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
import hu.bme.mit.gamma.xsts.model.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.model.XSTS
import hu.bme.mit.gamma.xsts.model.model.XSTSModelFactory
import java.io.File
import java.math.BigInteger
import java.util.List

import static extension hu.bme.mit.gamma.expression.model.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class GammaToXSTSTransformer {
	// Transformers
	GammaToLowlevelTransformer gammaToLowlevelTransformer = new GammaToLowlevelTransformer
	LowlevelToXSTSTransformer lowlevelToXSTSTransformer
	// Auxiliary objects
	protected final extension GammaEcoreUtil expressionUtil = new GammaEcoreUtil
	protected final extension FileUtil fileUtil = new FileUtil
	protected final extension ActionSerializer actionSerializer = new ActionSerializer
	protected final extension EnvironmentalActionFilter environmentalActionFilter = new EnvironmentalActionFilter
	protected final extension EventConnector eventConnector = new EventConnector
	protected final extension ActionOptimizer actionSimplifier = new ActionOptimizer
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
	
	def preprocessAndExecute(hu.bme.mit.gamma.statechart.model.Package _package, File containingFile) {
		val modelPreprocessor = new AnalysisModelPreprocessor
		val component = modelPreprocessor.preprocess(_package, containingFile)
		val newPackage = component.containingPackage
		return newPackage.executeAndSerialize
	}
	
	def void executeAndSerializeAndSave(hu.bme.mit.gamma.statechart.model.Package _package, File file) {
		val string = _package.execute.serializeXSTS.toString
		file.saveString(string)
	}
	
	def String executeAndSerialize(hu.bme.mit.gamma.statechart.model.Package _package) {
		return _package.execute.serializeXSTS.toString
	}
	
	def execute(hu.bme.mit.gamma.statechart.model.Package _package) {
		val gammaComponent = _package.components.head // Getting the first component
		gammaComponent.transformParameters(topComponentArguments) // Setting the parameter references
		val lowlevelPackage = gammaToLowlevelTransformer.transform(_package) // Not execute, as we want to distinguish between statecharts
		// Serializing the xSTS
		val xSts = gammaComponent.transform(lowlevelPackage) // Transforming the Gamma component
		// Removing duplicated types
		xSts.removeDuplicatedTypes
		// Optimizing
		xSts.variableInitializingAction = xSts.variableInitializingAction.optimize
		xSts.configurationInitializingAction = xSts.configurationInitializingAction.optimize
		xSts.entryEventAction = xSts.entryEventAction.optimize
		xSts.inEventAction = xSts.inEventAction.optimize
		xSts.outEventAction = xSts.outEventAction.optimize
		xSts.mergedTransition.action = xSts.mergedTransition.action.optimize
		return xSts
	}
	
	protected def void transformParameters(Component component, List<Expression> arguments) {
		val _package = component.containingPackage
		val parameterDeclarations = newArrayList
		parameterDeclarations += component.parameterDeclarations // So delete does not mess the list up
		for (parameter : parameterDeclarations) {
			val argumentConstant = createConstantDeclaration => [
				it.name = parameter.name + "Argument"
				it.type = parameter.type.clone(true, true)
				it.expression = arguments.get(parameter.index).clone(true, true)
			]
			_package.constantDeclarations += argumentConstant
			// Changing the references to the constant
			// Deleting because the parameter variables are not needed
			argumentConstant.changeAndDelete(parameter, component)
		}
	}
	
	protected def dispatch XSTS transform(Component component, Package lowlevelPackage) {
		throw new IllegalArgumentException("Not supported component type: " + component)
	}
	
	protected def dispatch XSTS transform(AbstractSynchronousCompositeComponent component, Package lowlevelPackage) {
		var XSTS xSts = null
		val scheduledInstances = component.scheduledInstances
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
				// Merged action
				val mergedAction = if (component instanceof CascadeCompositeComponent) createSequentialAction else createOrthogonalAction
				mergedAction.actions += xSts.mergedTransition.action
				mergedAction.actions += newXSts.mergedTransition.action
				xSts.mergedTransition.action = mergedAction
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
				// Environmental action
				val lastSchedulingIndex = scheduledInstances.lastIndexOf(subcomponent)
				val newInEventAction = newXSts.inEventAction as CompositeAction
				if (component instanceof CascadeCompositeComponent && i !== lastSchedulingIndex) {
					newInEventAction.resetNonPersistentParameters(type)
					// If this instance is scheduled multiple times, the inputs must be reset
					// Except after the last time:i !== lastSchedulingIndex
					mergedAction.actions += newInEventAction // Putting the reset in the merged action
					// When i == lastSchedulingIndex, the else branch will be executed and there will be only one in-event setting
				}
				else {
					val inEventAction = createSequentialAction
					inEventAction.actions += xSts.inEventAction
					inEventAction.actions += newInEventAction
					// Resetting events not led out to the system port (internal/channel events)
					inEventAction.resetInternalAssignments(component)
					xSts.inEventAction = inEventAction
				}
				// Out event
				val outEventAction = createSequentialAction
				outEventAction.actions += xSts.outEventAction
				outEventAction.actions += newXSts.outEventAction
					// Resetting events not led out to the system port (internal/channel events)
				outEventAction.resetInternalAssignments(component)
				xSts.outEventAction = outEventAction
			}
		}
		xSts.connectEventsThroughChannels(component) // Event (variable setting) connecting across channels
		xSts.name = component.name
		return xSts
	}
	
	protected def dispatch XSTS transform(StatechartDefinition statechart, Package lowlevelPackage) {
		// Note that the package is already transformed and traced because of the "val lowlevelPackage = gammaToLowlevelTransformer.transform(_package)" call
		val lowlevelStatechart = gammaToLowlevelTransformer.transform(statechart)
		lowlevelPackage.components += lowlevelStatechart
		lowlevelToXSTSTransformer = new LowlevelToXSTSTransformer(lowlevelPackage)
		val xStsEntry = lowlevelToXSTSTransformer.execute
		lowlevelPackage.components -= lowlevelStatechart // So that next time the matches do not return elements from this statechart
		val xSts = xStsEntry.key
		xSts.setClockVariables
		return xSts
	}
	
	protected def void setClockVariables(XSTS xSts) {
		if (schedulingConstraint === null) {
			return
		}
		val xStsEnvironmentalAction = createSequentialAction => [
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
			// Original action
			it.actions += xSts.inEventAction
		]
		xSts.inEventAction = xStsEnvironmentalAction
		xSts.clockVariables.clear // Clearing the clock variables, as they are handled like normal ones from now on
	}
	
	protected def void customizeDeclarationNames(XSTS xSts, ComponentInstance instance) {
		val type = instance.derivedType
		if (type instanceof StatechartDefinition) {
			for (variable : xSts.variableDeclarations) {
				variable.name = variable.customizeName(instance)
			}
			for (typeDeclaration : xSts.typeDeclarations) {
				typeDeclaration.name = typeDeclaration.customizeName(type)
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
	}
	
}