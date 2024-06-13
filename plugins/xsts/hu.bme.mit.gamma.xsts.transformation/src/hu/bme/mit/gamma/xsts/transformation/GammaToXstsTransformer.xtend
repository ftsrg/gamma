/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.PredicateExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.ArrayOptimizer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.RemovableVariableRemover
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.ResettableVariableResetter
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.XstsOptimizer
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.SchedulingConstraintAnnotation
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer
import hu.bme.mit.gamma.transformation.util.preprocessor.AnalysisModelPreprocessor
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.SystemInEventGroup
import hu.bme.mit.gamma.xsts.model.SystemInEventParameterGroup
import hu.bme.mit.gamma.xsts.model.SystemOutEventGroup
import hu.bme.mit.gamma.xsts.model.SystemOutEventParameterGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer
import hu.bme.mit.gamma.xsts.transformation.util.LoopActionUnroller
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueOptimizer
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collections
import java.util.List
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.xsts.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class GammaToXstsTransformer {
	// This gammaToLowlevelTransformer must be the same during this transformation cycle due to tracing
	protected final GammaToLowlevelTransformer gammaToLowlevelTransformer
	// Transformation utility
	protected final extension ComponentTransformer componentTransformer
	// Transformation settings
	protected final Integer minSchedulingConstraint
	protected final Integer maxSchedulingConstraint
	
	protected final PropertyPackage initialState
	protected final InitialStateSetting initialStateSetting
	protected final boolean optimize
	protected final boolean optimizeOneCapacityArrays
	protected final boolean unfoldMessageQueues
	protected final boolean unrollLoopActions = true
	// Auxiliary objects
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ActionSerializer actionSerializer = ActionSerializer.INSTANCE
	protected final extension EnvironmentalActionFilter environmentalActionFilter =
			EnvironmentalActionFilter.INSTANCE
	protected final extension AnalysisModelPreprocessor modelPreprocessor = AnalysisModelPreprocessor.INSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	// Logger
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new() {
		this(null, true, true, false, false, true, TransitionMerging.HIERARCHICAL)
	}
	
	new(Integer schedulingConstraint, boolean transformOrthogonalActions,
			boolean optimize, boolean optimizeOneCapacityArrays,
			boolean unfoldMessageQueues, boolean optimizeEnvironmentalMessageQueues,
			TransitionMerging transitionMerging) {
		this(schedulingConstraint, transformOrthogonalActions, optimize,
				optimizeOneCapacityArrays, unfoldMessageQueues, optimizeEnvironmentalMessageQueues,
				transitionMerging, null, null)
	}
	
	new(Integer schedulingConstraint, boolean transformOrthogonalActions,
			boolean optimize, boolean optimizeOneCapacityArrays,
			boolean unfoldMessageQueues, boolean optimizeEnvironmentalMessageQueues,
			TransitionMerging transitionMerging,
			PropertyPackage initialState, InitialStateSetting initialStateSetting) {
		this(schedulingConstraint, schedulingConstraint,
			transformOrthogonalActions, optimize, optimizeOneCapacityArrays, unfoldMessageQueues,
			optimizeEnvironmentalMessageQueues, transitionMerging, initialState, initialStateSetting)
	}
	
	new(Integer minSchedulingConstraint, Integer maxSchedulingConstraint,
			boolean transformOrthogonalActions,	boolean optimize, boolean optimizeOneCapacityArrays,
			boolean unfoldMessageQueues, boolean optimizeEnvironmentalMessageQueues,
			TransitionMerging transitionMerging,
			PropertyPackage initialState, InitialStateSetting initialStateSetting) {
		this.gammaToLowlevelTransformer = new GammaToLowlevelTransformer
		this.componentTransformer = new ComponentTransformer(this.gammaToLowlevelTransformer,
			transformOrthogonalActions, optimize, optimizeEnvironmentalMessageQueues, transitionMerging)
		this.minSchedulingConstraint = minSchedulingConstraint
		this.maxSchedulingConstraint = maxSchedulingConstraint
		this.initialState = initialState
		this.initialStateSetting = initialStateSetting
		this.optimize = optimize
		this.optimizeOneCapacityArrays = optimizeOneCapacityArrays
		this.unfoldMessageQueues = unfoldMessageQueues
	}
	
	def preprocessAndExecuteAndSerialize(Package _package,
			String targetFolderUri, String fileName) {
		return _package.preprocessAndExecute(#[], targetFolderUri, fileName).serializeXsts
	}
	
	def preprocessAndExecuteAndSerialize(Package _package,
			List<Expression> topComponentArguments, String targetFolderUri, String fileName) {
		return _package.preprocessAndExecute(
				topComponentArguments, targetFolderUri, fileName).serializeXsts
	}

	def preprocessAndExecute(Package _package,
			String targetFolderUri, String fileName) {
		val component = modelPreprocessor.preprocess(
				_package, #[], targetFolderUri, fileName, optimize)
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
		logger.info("Starting main execution of Gamma-XSTS transformation")
		val gammaComponent = _package.firstComponent // Getting the first component
		// "transform", not "execute", as we want to distinguish between statecharts
		val lowlevelPackage = gammaToLowlevelTransformer.transform(_package)
		// Serializing the xSTS
		val xSts = gammaComponent.transform(lowlevelPackage) // Transforming the Gamma component
		
		// Adding metadata
		if (gammaComponent.synchronous) {
			xSts.addSynchronousAnnotation
		}
		else {
			checkState(gammaComponent.asynchronous)
			xSts.addAsynchronousAnnotation
		}
		
		// Creating system event groups for traceability purposes
		logger.info("Creating system event groups for " + gammaComponent.name)
		xSts.createSystemEventGroups(gammaComponent) // Now synchronous event variables are put in there
		// Removing duplicated types
		xSts.removeDuplicatedTypes
		// Setting clock variable increase
		xSts.setClockVariables
		_package.setSchedulingAnnotation // Needed for back-annotation
		// Remove internal parameter assignments from environment
		xSts.removeInternalParameterAssignment(gammaComponent)
		// Optimizing
		xSts.optimize
		
		if (initialState !== null) {
			logger.info("Setting initial state " + gammaComponent.name)
			val initialStateHandler = new InitialStateHandler(xSts, gammaComponent,
				initialState, initialStateSetting)
			initialStateHandler.execute
		}
		
		return xSts
	}
	
	protected def void setClockVariables(XSTS xSts) {
		if (minSchedulingConstraint === null) {
			// We are expected to execute this branch if we aim at generating Timed XSTS models (TXSTS)
			return
		}
		//
		// Note that we get here if some kind of scheduling constraint is specified
		//
		val xStsClockSettingAction = createSequentialAction
		// Increasing the clock variables
		var VariableDeclaration xStsDelayVariable = null
		if (minSchedulingConstraint != maxSchedulingConstraint) {
			xStsDelayVariable = createIntegerTypeDefinition
					.createVariableDeclaration(delayVariableName)
			// Needed for back-annotation
			xStsDelayVariable.addResettableAnnotation // So it is reset at the beginning
			xSts.variableDeclarations += xStsDelayVariable
			
			val xStsDelayHavocAction = xStsDelayVariable.createHavocAction
			xStsClockSettingAction.actions += xStsDelayHavocAction
			
			val xStsDelayAssume = minSchedulingConstraint.toIntegerLiteral
					.createLessEqualExpression(xStsDelayVariable.createReferenceExpression)
					.wrapIntoAndExpression(
						xStsDelayVariable.createReferenceExpression
							.createLessEqualExpression(maxSchedulingConstraint.toIntegerLiteral))
					.createAssumeAction
			xStsClockSettingAction.actions += xStsDelayAssume
		}
		
		for (xStsClockVariable : xSts.clockVariables) {
			val maxValue = xStsClockVariable.greatestComparison
			val incrementExpression = xStsClockVariable.createReferenceExpression
				.wrapIntoAddExpression(
					(xStsDelayVariable === null) ?
					toIntegerLiteral(minSchedulingConstraint) : xStsDelayVariable.createReferenceExpression)
			val rhs = (maxValue === null) ? incrementExpression :
				createIfThenElseExpression => [
					it.condition = createLessExpression => [
						it.leftOperand = createReferenceExpression(xStsClockVariable)
						it.rightOperand = toIntegerLiteral(maxValue)
					]
					it.then = incrementExpression
					it.^else = createReferenceExpression(xStsClockVariable)
				]
			xStsClockSettingAction.actions += xStsClockVariable.createAssignmentAction(rhs)
			// Denoting variable as scheduled clock variable
			xStsClockVariable.addScheduledClockAnnotation
		}
		// Putting it in merged transition as it does not work in environment action
		xStsClockSettingAction.actions += xSts.mergedAction
		
		xSts.changeTransitions(xStsClockSettingAction.wrap)
		// Clearing the clock variables - they are handled like normal ones from now on
		// This way the UPPAAL transformer will not use clock types as variable values 
		xSts.removeVariableDeclarationAnnotations(ClockVariableDeclarationAnnotation)
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
	
	protected def void setSchedulingAnnotation(Package _package) {
		if (minSchedulingConstraint !== null && minSchedulingConstraint == maxSchedulingConstraint) {
			if (!_package.annotations.exists[it instanceof SchedulingConstraintAnnotation]) {
				_package.annotations += createSchedulingConstraintAnnotation => [
					it.schedulingConstraint = toIntegerLiteral(minSchedulingConstraint)
				]
				_package.save
			}
		}
	}
	
	protected def removeDuplicatedTypes(XSTS xSts) {
		logger.info("Checking if the XSTS contains multiple type declarations with the same name")
		val types = xSts.typeDeclarations
		for (var i = 0; i < types.size - 1; i++) {
			val lhs = types.get(i)
			for (var j = i + 1; j < types.size; j++) {
				val rhs = types.get(j)
				if (lhs.name == rhs.name && lhs.helperEquals(rhs)) {
					lhs.changeAllAndRemove(rhs, xSts) // Remove instead of delete to speed up
					j--
				}
			}
		}
		// Type declaration names are not customized as multiple types can refer to the same type
		// These types would be different in XSTS, when they are the same in Gamma
		// Note: for this reason, every type declaration must have a different name
		val typeDeclarationNames = types.map[it.name]
		val duplications = typeDeclarationNames
				.filter[Collections.frequency(typeDeclarationNames, it) > 1].toList
		if (!duplications.empty) {
			logger.info("The XSTS contains multiple type declarations with the same name: " + duplications)
		}
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
		xSts.variableGroups.filter[it.annotation instanceof SystemInEventParameterGroup].forEach[it.remove]
		xSts.variableGroups.filter[it.annotation instanceof SystemOutEventGroup].forEach[it.remove]
		xSts.variableGroups.filter[it.annotation instanceof SystemOutEventParameterGroup].forEach[it.remove]
		
		val systemInEventGroup = createVariableGroup => [
			it.annotation = createSystemInEventGroup
		]
		val systemInEventParameterGroup = createVariableGroup => [
			it.annotation = createSystemInEventParameterGroup
		]
		val systemOutEventGroup = createVariableGroup => [
			it.annotation = createSystemOutEventGroup
		]
		val systemOutEventParameterGroup = createVariableGroup => [
			it.annotation = createSystemOutEventParameterGroup
		]
		xSts.variableGroups += systemInEventGroup
		xSts.variableGroups += systemInEventParameterGroup
		xSts.variableGroups += systemOutEventGroup
		xSts.variableGroups += systemOutEventParameterGroup
		
		for (port : component.allBoundSimplePorts) {
			val instance = port.containingComponentInstance
			for (inEvent : port.inputEvents) {
				val inEventVariableName = customizeInputName(inEvent, port, instance)
				val inEventVariable = xSts.getVariable(inEventVariableName)
				if (inEventVariable !== null) {
					systemInEventGroup.variables += inEventVariable
					// Parameters
					for (inParameter : inEvent.parameterDeclarations) {
						val inEventParameterVariableNames = customizeInNames(inParameter, port, instance)
						for (inEventParameterVariableName : inEventParameterVariableNames) {
							val inEventParameterVariable = xSts.getVariable(inEventParameterVariableName)
							if (inEventParameterVariable !== null) {
								systemInEventParameterGroup.variables += inEventParameterVariable
							}
						}
					}
				}
			}
			for (outEvent : port.outputEvents) {
				val outEventVariableName = customizeOutputName(outEvent, port, instance)
				val outEventVariable = xSts.getVariable(outEventVariableName)
				if (outEventVariable !== null) {
					systemOutEventGroup.variables += outEventVariable
					// Parameters
					for (outParameter : outEvent.parameterDeclarations) {
						val outEventParameterVariableNames = customizeOutNames(outParameter, port, instance)
						for (outEventParameterVariableName : outEventParameterVariableNames) {
							val outEventParameterVariable = xSts.getVariable(outEventParameterVariableName)
							if (outEventParameterVariable !== null) {
								systemOutEventParameterGroup.variables += outEventParameterVariable
							}
						}
					}
				}
			}
		}
	}
	
	protected def removeInternalParameterAssignment(XSTS xSts, Component component) {
		val systemInEventParameters = xSts.systemInEventParameterVariableGroup.variables
		val systemInEventInternalParameters = systemInEventParameters
				.filter[it.internal].toList
				
				
		// In the asynchronous case, the underlying transformation works
		if (component.synchronous) {
			val inEventTransition = xSts.inEventTransition
			systemInEventInternalParameters.changeAssignmentsToEmptyActions(inEventTransition)
		}
		
		systemInEventParameters -= systemInEventInternalParameters
	}
		
	
	protected def optimize(XSTS xSts) {
		logger.info("Optimizing reset, environment and merged actions in " + xSts.name)
		val XstsOptimizer xStsOptimizer = XstsOptimizer.INSTANCE
		xStsOptimizer.optimizeXSts(xSts) // Affects all actions
		
		if (optimize) {
			logger.info("Optimizing read-only variables in " + xSts.name)
			val variableRemover = RemovableVariableRemover.INSTANCE
			variableRemover.removeReadOnlyVariables(xSts) // Affects parameter and input variables, too
			
			logger.info("Resetting resettable variables in the environment in " + xSts.name)
			val resetter = ResettableVariableResetter.INSTANCE
			resetter.resetResettableVariables(xSts)
			
			xStsOptimizer.optimizeXSts(xSts) // Once again after the potential variable removals above
			// Due to, e.g., read-only -> optimize (inline) chain that results in unused local variables
		}
		
		if (unfoldMessageQueues) {
			logger.info("Unfolding message queues in " + xSts.name)
			val messageQueueOptimizer = MessageQueueOptimizer.INSTANCE
			messageQueueOptimizer.unfoldMessageQueues(xSts)
		}
		// Unfold before one-capacity array to ensure "sound" queue unfolding (one-capacity arrays can be non-queues)
		if (optimizeOneCapacityArrays) {
			logger.info("Optimizing one capacity arrays in " + xSts.name)
			val arrayOptimizer = ArrayOptimizer.INSTANCE
			arrayOptimizer.optimizeOneCapacityArrays(xSts)
		}
		if (unrollLoopActions) {
			logger.info("Unrolling loop actions in " + xSts.name)
			val loopActionUnroller = LoopActionUnroller.INSTANCE
			loopActionUnroller.unrollLoopActions(xSts)
		}
		
		if (unfoldMessageQueues || optimizeOneCapacityArrays || unrollLoopActions) {
			logger.info("Optimizing XSTS another time: " + xSts.name)
			xStsOptimizer.optimizeXSts(xSts) // Maybe unfoldings/unrollings can be exploited
		}
		
		logger.info("Optimization has finished for " + xSts.name)
	}
	
}