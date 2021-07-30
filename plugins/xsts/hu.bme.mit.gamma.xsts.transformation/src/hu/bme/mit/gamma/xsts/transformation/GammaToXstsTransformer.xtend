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

import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.PredicateExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.ActionOptimizer
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.SchedulingConstraintAnnotation
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer
import hu.bme.mit.gamma.transformation.util.preprocessor.AnalysisModelPreprocessor
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.SystemInEventGroup
import hu.bme.mit.gamma.xsts.model.SystemOutEventGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer
import hu.bme.mit.gamma.xsts.transformation.util.OrthogonalActionTransformer
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collections
import java.util.List
import java.util.logging.Level
import java.util.logging.Logger

import static hu.bme.mit.gamma.xsts.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class GammaToXstsTransformer {
	// This gammaToLowlevelTransformer must be the same during this transformation cycle due to tracing
	protected final GammaToLowlevelTransformer gammaToLowlevelTransformer
	// Transformation utility
	protected final extension ComponentTransformer componentTransformer
	// Transformation settings
	protected final Integer schedulingConstraint
	protected final boolean transformOrthogonalActions
	// Auxiliary objects
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ActionSerializer actionSerializer = ActionSerializer.INSTANCE
	protected final extension OrthogonalActionTransformer orthogonalActionTransformer = OrthogonalActionTransformer.INSTANCE
	protected final extension EnvironmentalActionFilter environmentalActionFilter = EnvironmentalActionFilter.INSTANCE
	protected final extension ActionOptimizer actionSimplifier = ActionOptimizer.INSTANCE
	protected final extension AnalysisModelPreprocessor modelPreprocessor = AnalysisModelPreprocessor.INSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	// Logger
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new() {
		this(null, true, true, false, false, TransitionMerging.HIERARCHICAL)
	}
	
	new(Integer schedulingConstraint, boolean transformOrthogonalActions,
			boolean optimize, boolean useHavocActions, boolean extractGuards,
			TransitionMerging transitionMerging) {
		this.gammaToLowlevelTransformer = new GammaToLowlevelTransformer
		this.componentTransformer = new ComponentTransformer(this.gammaToLowlevelTransformer,
			optimize, useHavocActions, extractGuards, transitionMerging)
		this.schedulingConstraint = schedulingConstraint
		this.transformOrthogonalActions = transformOrthogonalActions
	}
	
	def preprocessAndExecuteAndSerialize(Package _package,
			String targetFolderUri, String fileName) {
		return _package.preprocessAndExecute(#[], targetFolderUri, fileName).serializeXSTS
	}
	
	def preprocessAndExecuteAndSerialize(Package _package,
			List<Expression> topComponentArguments, String targetFolderUri, String fileName) {
		return _package.preprocessAndExecute(topComponentArguments, targetFolderUri, fileName).serializeXSTS
	}

	def preprocessAndExecute(Package _package,
			String targetFolderUri, String fileName) {
		val component = modelPreprocessor.preprocess(_package, #[], targetFolderUri, fileName, optimize)
		val newPackage = component.containingPackage
		return newPackage.execute
	}
	
	def preprocessAndExecute(Package _package,
			List<Expression> topComponentArguments, String targetFolderUri, String fileName) {
		val component = modelPreprocessor.preprocess(_package, topComponentArguments,
			targetFolderUri, fileName, optimize)
		val newPackage = component.containingPackage
		return newPackage.execute
	}
	
	def execute(Package _package) {
		logger.log(Level.INFO, "Starting main execution of Gamma-XSTS transformation")
		val gammaComponent = _package.components.head // Getting the first component
		val lowlevelPackage = gammaToLowlevelTransformer.transform(_package) // Not execute, as we want to distinguish between statecharts
		// Serializing the xSTS
		val xSts = gammaComponent.transform(lowlevelPackage) // Transforming the Gamma component
		// Creating system event groups for traceability purposes
		logger.log(Level.INFO, "Creating system event groups for " + gammaComponent.name)
		xSts.createSystemEventGroups(gammaComponent)
		// Removing duplicated types
		xSts.removeDuplicatedTypes
		// Setting clock variable increase
		xSts.setClockVariables
		_package.setSchedulingAnnotation(schedulingConstraint) // Needed for back-annotation
		if (transformOrthogonalActions) {
			logger.log(Level.INFO, "Optimizing orthogonal actions in " + xSts.name)
			xSts.transform
			// Before optimize actions
		}
		if (optimize) {
			// Optimizing: system in events (but not PERSISTENT parameters) can be reset after the merged transition
			xSts.resetInEventsAfterMergedAction(gammaComponent)
		}
		// Optimizing
		xSts.optimize
		return xSts
	}
	
	protected def void setClockVariables(XSTS xSts) {
		if (schedulingConstraint === null) {
			return
		}
		val xStsClockSettingAction = createSequentialAction => [
			// Increasing the clock variables
			for (xStsClockVariable : xSts.clockVariables) {
				val maxValue = xStsClockVariable.greatestComparison
				val incrementExpression = createAddExpression => [
					it.operands += createReferenceExpression(xStsClockVariable)
					it.operands += toIntegerLiteral(schedulingConstraint)
				]
				val rhs = (maxValue === null) ? incrementExpression :
					createIfThenElseExpression => [
						it.condition = createLessExpression => [
							it.leftOperand = createReferenceExpression(xStsClockVariable)
							it.rightOperand = toIntegerLiteral(maxValue)
						]
						it.then = incrementExpression
						it.^else = createReferenceExpression(xStsClockVariable)
					]
				it.actions += createAssignmentAction => [
					it.lhs = createReferenceExpression(xStsClockVariable)
					it.rhs = rhs
				]
			}
			// Putting it in merged transition as it does not work in environment action
			it.actions += xSts.mergedAction
		]
		xSts.changeTransitions(xStsClockSettingAction.wrap)
		xSts.clockVariables.clear // Clearing the clock variables, as they are handled like normal ones from now on
	}
	
	protected def Integer getGreatestComparison(VariableDeclaration variable) {
		val root = variable.root
		val values = newHashSet
		val comparisons = root.getAllContentsOfType(PredicateExpression).filter(BinaryExpression)
		try {
			for (comparison : comparisons) {
				val left = comparison.leftOperand
				val right = comparison.rightOperand
				if (left instanceof DirectReferenceExpression) {
					if (left.declaration === variable) {
						values += right.evaluateInteger
					}
				}
				else if (right instanceof DirectReferenceExpression) {
					if (right.declaration === variable) {
						values += left.evaluateInteger
					}
				}
			}
			return (values.empty) ? null : values.max
		} catch (IllegalArgumentException e) {
			// A variable is referenced
			return null
		}
	}
	
	protected def void setSchedulingAnnotation(Package _package, Integer schedulingConstraint) {
		if (schedulingConstraint !== null) {
			if (!_package.annotations.exists[it instanceof SchedulingConstraintAnnotation]) {
				_package.annotations += createSchedulingConstraintAnnotation => [
					it.schedulingConstraint = toIntegerLiteral(schedulingConstraint)
				]
				_package.save
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
		val typeDeclarationNames = types.map[it.name]
		val duplications = typeDeclarationNames.filter[Collections.frequency(typeDeclarationNames, it) > 1].toList
		logger.log(Level.INFO, "The XSTS contains multiple type declarations with the same name:" + duplications)
		// It is possible that in some instances of the same region, some states are removed due to optimization
		var id = 0
		for (type : types) {
			// It does not mess up traceability, the variable type names are not important
			val typeName = type.name
			if (duplications.contains(typeName)) {
				type.name = typeName + id++
			}
		}
	}
	
	protected def void createSystemEventGroups(XSTS xSts, Component component) {
		xSts.variableGroups.filter[it.annotation instanceof SystemInEventGroup].forEach[it.remove]
		xSts.variableGroups.filter[it.annotation instanceof SystemOutEventGroup].forEach[it.remove]
		
		val systemInEventGroup = createVariableGroup => [
			it.annotation = createSystemInEventGroup
		]
		val systemOutEventGroup = createVariableGroup => [
			it.annotation = createSystemOutEventGroup
		]
		xSts.variableGroups += systemInEventGroup
		xSts.variableGroups += systemOutEventGroup
		
		for (port : component.allBoundSimplePorts) {
			val instance = port.containingComponentInstance
			for (inEvent : port.inputEvents) {
				val inEventVariableName = customizeInputName(inEvent, port, instance)
				val inEventVariable = xSts.getVariable(inEventVariableName)
				if (inEventVariable !== null) {
					systemInEventGroup.variables += inEventVariable
				}
			}
			for (outEvent : port.outputEvents) {
				val outEventVariableName = customizeOutputName(outEvent, port, instance)
				val outEventVariable = xSts.getVariable(outEventVariableName)
				if (outEventVariable !== null) {
					systemOutEventGroup.variables += outEventVariable
				}
			}
		}
	}
	
	protected def void resetInEventsAfterMergedAction(XSTS xSts, Component type) {
		val inEventAction = xSts.inEventTransition.action
		// Maybe still not perfect?
		if (inEventAction instanceof CompositeAction) {
			val clonedInEventAction = inEventAction.clone
			// Not PERSISTENT parameters
			val resetAction = clonedInEventAction.resetEverythingExceptPersistentParameters(type)
			val newMergedAction = createSequentialAction => [
				it.actions += xSts.mergedAction
				it.actions += resetAction
			]
			xSts.changeTransitions(newMergedAction.wrap)
		}
	}
	
	protected def optimize(XSTS xSts) {
		logger.log(Level.INFO, "Optimizing reset, environment and merged actions in " + xSts.name)
		xSts.variableInitializingTransition = xSts.variableInitializingTransition.optimize
		xSts.configurationInitializingTransition = xSts.configurationInitializingTransition.optimize
		xSts.entryEventTransition = xSts.entryEventTransition.optimize
		xSts.inEventTransition = xSts.inEventTransition.optimize
		xSts.outEventTransition = xSts.outEventTransition.optimize
		xSts.changeTransitions(xSts.transitions.optimize)
	}
	
}