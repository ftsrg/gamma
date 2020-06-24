/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.lowlevel.xsts.transformation.ActionOptimizer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.LowlevelToXSTSTransformer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.serializer.ActionSerializer
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.transformation.util.AnalysisModelPreprocessor
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.model.RegionGroup
import hu.bme.mit.gamma.xsts.model.model.XSTS
import hu.bme.mit.gamma.xsts.model.model.XSTSModelFactory
import java.io.File
import java.math.BigInteger
import java.util.Collections
import java.util.List
import org.eclipse.emf.ecore.util.EcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.model.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class GammaToXSTSTransformer {
	// Transformers
	GammaToLowlevelTransformer gammaToLowlevelTransformer = new GammaToLowlevelTransformer
	LowlevelToXSTSTransformer lowlevelToXSTSTransformer
	// Auxiliary objects
	protected final extension GammaEcoreUtil expressionUtil = GammaEcoreUtil.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension ActionSerializer actionSerializer = new ActionSerializer
	protected final extension EnvironmentalActionFilter environmentalActionFilter = new EnvironmentalActionFilter
	protected final extension EventConnector eventConnector = new EventConnector
	protected final extension ActionOptimizer actionSimplifier = new ActionOptimizer
	protected final extension AnalysisModelPreprocessor modelPreprocessor = new AnalysisModelPreprocessor
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xstsModelFactory = XSTSModelFactory.eINSTANCE
	// Top component arguments
	protected final List<Expression> topComponentArguments
	// Scheduling constraint
	protected final Integer schedulingConstraint
	
	new() {
		this(#[], null)
	}
	
	new(List<Expression> topComponentArguments, Integer schedulingConstraint) {
		this.topComponentArguments = topComponentArguments
		this.schedulingConstraint = schedulingConstraint
	}
	
	def preprocessAndExecuteAndSerializeAndSave(hu.bme.mit.gamma.statechart.model.Package _package, File containingFile) {
		val component = modelPreprocessor.preprocess(_package, topComponentArguments, containingFile)
		val newPackage = component.containingPackage
		newPackage.executeAndSerializeAndSave(containingFile)
	}
	
	/**
	 * Note that there is no preprocess and argument process in this method.
	 */
	def void executeAndSerializeAndSave(hu.bme.mit.gamma.statechart.model.Package _package, File file) {
		val string = _package.executeAndSerialize
		file.saveString(string)
	}
	
	private def String executeAndSerialize(hu.bme.mit.gamma.statechart.model.Package _package) {
		return _package.execute.serializeXSTS.toString
	}
	
	private def execute(hu.bme.mit.gamma.statechart.model.Package _package) {
		val gammaComponent = _package.components.head // Getting the first component
		val lowlevelPackage = gammaToLowlevelTransformer.transform(_package) // Not execute, as we want to distinguish between statecharts
		// Serializing the xSTS
		val xSts = gammaComponent.transform(lowlevelPackage) // Transforming the Gamma component
		// Removing duplicated types
		xSts.removeDuplicatedTypes
		// Optimizing
		xSts.optimize
		return xSts
	}
	
	protected def transformParameters(Component component, List<Expression> arguments) {
		val _package = component.containingPackage
		val parameterDeclarations = newArrayList
		parameterDeclarations += component.parameterDeclarations // So delete does not mess the list up
		// Theta back-annotation retrieves the argument values from the constant list
		for (parameter : parameterDeclarations) {
			val argumentConstant = createConstantDeclaration => [
				it.name = "__" + parameter.name + "Argument__"
				it.type = parameter.type.clone(true, true)
				it.expression = arguments.get(parameter.index).clone(true, true)
			]
			_package.constantDeclarations += argumentConstant
			// Changing the references to the constant
			argumentConstant.change(parameter, component)
		}
		// Deleting after the index settings have been completed (otherwise the index always returns 0)
		EcoreUtil.deleteAll(parameterDeclarations, true)
	}
	
	protected def dispatch XSTS transform(Component component, Package lowlevelPackage) {
		throw new IllegalArgumentException("Not supported component type: " + component)
	}
	
	protected def dispatch XSTS transform(AbstractSynchronousCompositeComponent component, Package lowlevelPackage) {
		var XSTS xSts = null
		val scheduledInstances = component.scheduledInstances
		val mergedAction = if (component instanceof CascadeCompositeComponent) createSequentialAction else createOrthogonalAction
		for (var i = 0; i < scheduledInstances.size; i++) {
			val subcomponent = scheduledInstances.get(i)
			val type = subcomponent.type
			type.transformParameters(subcomponent.arguments) // Change the reference from parameters to constants
			val newXSts = type.transform(lowlevelPackage)
			newXSts.customizeDeclarationNames(subcomponent)
			if (xSts === null) {
				xSts = newXSts
			}
			else {
				// Adding new elements
				xSts.typeDeclarations += newXSts.typeDeclarations
				xSts.publicTypeDeclarations += newXSts.publicTypeDeclarations
				xSts.variableGroups += newXSts.variableGroups
				xSts.variableDeclarations += newXSts.variableDeclarations
				xSts.transientVariables += newXSts.transientVariables
				xSts.controlVariables += newXSts.controlVariables
				xSts.clockVariables += newXSts.clockVariables
				xSts.transitions += newXSts.transitions
				xSts.constraints += newXSts.constraints
				// Initializing action
				val variableInitAction = createSequentialAction
				variableInitAction.actions += xSts.variableInitializingAction
				variableInitAction.actions += newXSts.variableInitializingAction
				xSts.variableInitializingAction = variableInitAction
				val configInitAction = createSequentialAction
				configInitAction.actions += xSts.configurationInitializingAction
				configInitAction.actions += newXSts.configurationInitializingAction
				xSts.configurationInitializingAction = configInitAction
				val entryAction = createSequentialAction
				entryAction.actions += xSts.entryEventAction
				entryAction.actions += newXSts.entryEventAction
				xSts.entryEventAction = entryAction
			}
			// Merged action
			val actualComponentMergedAction = createSequentialAction => [
				it.actions += newXSts.mergedAction
			]
			mergedAction.actions += actualComponentMergedAction
			// In and Out actions - using sequential actions to make sure they are composite actions
			// Methods reset... and delete... require this
			val newInEventAction = createSequentialAction => [ it.actions += newXSts.inEventAction ]
			newXSts.inEventAction = newInEventAction
			val newOutEventAction = createSequentialAction => [ it.actions += newXSts.outEventAction ]
			newXSts.outEventAction = newOutEventAction
			// Resetting channel events
			// 1) the Sync ort semantics: Resetting channel IN events AFTER schedule would result in a deadlock
			// 2) the Casc semantics: Resetting channel OUT events BEFORE schedule would delete in events of subsequent components
			// Note, System in and out events are reset in the env action
			if (component instanceof CascadeCompositeComponent) {
				// Resetting IN events AFTER schedule
				val clonedNewInEventAction = newInEventAction.clone(true, true)
					.resetEverythingExceptPersistentParameters(type) // Clone is important
				actualComponentMergedAction.actions += clonedNewInEventAction // Putting the new action AFTER
			}
			else {
				// Resetting OUT events BEFORE schedule
				val clonedNewOutEventAction = newOutEventAction.clone(true, true) // Clone is important
					.resetEverythingExceptPersistentParameters(type)
				actualComponentMergedAction.actions.add(0, clonedNewOutEventAction) // Putting the new action BEFORE
			}
			// In event
			newInEventAction.deleteEverythingExceptSystemEventsAndParameters(component)
			if (xSts !== newXSts) { // Only if this is not the first component
				val inEventAction = createSequentialAction
				inEventAction.actions += xSts.inEventAction
				inEventAction.actions += newInEventAction
				xSts.inEventAction = inEventAction
			}
			// Out event
			newOutEventAction.deleteEverythingExceptSystemEventsAndParameters(component)
			if (xSts !== newXSts) { // Only if this is not the first component
				val outEventAction = createSequentialAction
				outEventAction.actions += xSts.outEventAction
				outEventAction.actions += newOutEventAction
				xSts.outEventAction = outEventAction
			}
		}
		xSts.mergedAction = mergedAction
		// Connect only after xSts.mergedTransition.action = mergedAction
		xSts.connectEventsThroughChannels(component) // Event (variable setting) connecting across channels
		xSts.inEventAction.bindEventsBoundToTheSameSystemPort(component) // Bind together ports connected to the same system port
		xSts.name = component.name
		return xSts
	}
	
	protected def dispatch XSTS transform(StatechartDefinition statechart, Package lowlevelPackage) {
		// Note that the package is already transformed and traced because of the "val lowlevelPackage = gammaToLowlevelTransformer.transform(_package)" call
		val lowlevelStatechart = gammaToLowlevelTransformer.transform(statechart)
		lowlevelPackage.components += lowlevelStatechart
		lowlevelToXSTSTransformer = new LowlevelToXSTSTransformer(lowlevelPackage, true)
		val xStsEntry = lowlevelToXSTSTransformer.execute
		lowlevelPackage.components -= lowlevelStatechart // So that next time the matches do not return elements from this statechart
		val xSts = xStsEntry.key
		xSts.setClockVariables
		// 0-ing all variable declaration initial expression, the normal ones are in the init action
		for (variable : xSts.variableDeclarations) {
			val type = variable.type
			variable.expression = type.defaultExpression
		}
		return xSts
	}
	
	protected def void setClockVariables(XSTS xSts) {
		if (schedulingConstraint === null) {
			return
		}
		val xStsClockSettingAction = createSequentialAction => [
			// Increasing the clock variables
			for (xStsClockVariable : xSts.clockVariables) {
				it.actions += createAssignmentAction => [
					it.lhs = createReferenceExpression => [
						it.declaration = xStsClockVariable
					]
					it.rhs = createAddExpression => [
						it.operands += createReferenceExpression => [
							it.declaration = xStsClockVariable
						]
						it.operands += createIntegerLiteralExpression => [
							it.value = BigInteger.valueOf(schedulingConstraint)
						]
					]
				]
			}
			// Putting it in merged transition as it does not work in environment action
			it.actions += xSts.mergedAction
		]
		xSts.mergedAction = xStsClockSettingAction
		xSts.clockVariables.clear // Clearing the clock variables, as they are handled like normal ones from now on
	}
	
	protected def void customizeDeclarationNames(XSTS xSts, ComponentInstance instance) {
		val type = instance.derivedType
		if (type instanceof StatechartDefinition) {
			// Customizing every variable name
			for (variable : xSts.variableDeclarations) {
				variable.name = variable.customizeName(instance)
			}
			// Customizing region type declaration name
			for (regionType : xSts.variableGroups.filter[it.annotation instanceof RegionGroup]
					.map[it.variables].flatten.map[it.type].filter(TypeReference).map[it.reference]) {
				regionType.name = regionType.customizeRegionTypeName(type)
			}
		}
	}
	
	protected def removeDuplicatedTypes(XSTS xSts) {
		val types = xSts.typeDeclarations
		for (var i = 0; i < types.size - 1; i++) {
			val lhs = types.get(i)
			for (var j = i + 1; j < types.size; j++) {
				val rhs = types.get(j)
				if (lhs.helperEquals(rhs)) {
					lhs.changeAllAndDelete(rhs, xSts)
					j--
				}
			}
		}
		// Type declaration names are not customized as multiple types can refer to the same type
		// These types would be different in XSTS, when they are the same in Gamma
		// Note: for this reason, every type declaration must have a different name
		val typeDeclarationNames = xSts.typeDeclarations.map[it.name]
		val duplications = typeDeclarationNames.filter[Collections.frequency(typeDeclarationNames, it) > 1].toList
		checkState(duplications.empty, "The XSTS contains multiple type declarations with the same name:" + duplications)
	}
	
	protected def optimize(XSTS xSts) {
		xSts.variableInitializingAction = xSts.variableInitializingAction.optimize
		xSts.configurationInitializingAction = xSts.configurationInitializingAction.optimize
		xSts.entryEventAction = xSts.entryEventAction.optimize
		xSts.inEventAction = xSts.inEventAction.optimize
		xSts.outEventAction = xSts.outEventAction.optimize
		xSts.mergedAction = xSts.mergedAction.optimize
	}
	
}