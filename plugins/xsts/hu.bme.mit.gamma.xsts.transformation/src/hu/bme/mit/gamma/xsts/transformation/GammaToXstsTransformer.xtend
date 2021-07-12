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
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.lowlevel.xsts.transformation.LowlevelToXstsTransformer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.ActionOptimizer
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ControlFunction
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.SchedulingConstraintAnnotation
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.transformation.util.preprocessor.AnalysisModelPreprocessor
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.InEventGroup
import hu.bme.mit.gamma.xsts.model.RegionGroup
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
import org.eclipse.emf.ecore.util.EcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class GammaToXstsTransformer {
	// This gammaToLowlevelTransformer must be the same during this transformation cycle due to tracing
	GammaToLowlevelTransformer gammaToLowlevelTransformer = new GammaToLowlevelTransformer
	// Auxiliary objects
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ActionSerializer actionSerializer = ActionSerializer.INSTANCE
	protected final extension OrthogonalActionTransformer orthogonalActionTransformer = OrthogonalActionTransformer.INSTANCE
	protected final extension EnvironmentalActionFilter environmentalActionFilter = EnvironmentalActionFilter.INSTANCE
	protected final extension EventConnector eventConnector = EventConnector.INSTANCE
	protected final extension SystemReducer systemReducer = SystemReducer.INSTANCE
	protected final extension ActionOptimizer actionSimplifier = ActionOptimizer.INSTANCE
	protected final extension AnalysisModelPreprocessor modelPreprocessor = AnalysisModelPreprocessor.INSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	// Transformation settings
	protected final Integer schedulingConstraint
	protected final boolean transformOrthogonalActions
	protected final boolean optimize
	protected final boolean useHavocActions
	// Logger
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new() {
		this(null, true, true, false)
	}
	
	new(Integer schedulingConstraint, boolean transformOrthogonalActions,
			boolean optimize, boolean useHavocActions) {
		this.schedulingConstraint = schedulingConstraint
		this.transformOrthogonalActions = transformOrthogonalActions
		this.optimize = optimize
		this.useHavocActions = useHavocActions
	}
	
	def preprocessAndExecuteAndSerialize(hu.bme.mit.gamma.statechart.interface_.Package _package,
			String targetFolderUri, String fileName) {
		return _package.preprocessAndExecute(#[], targetFolderUri, fileName).serializeXSTS
	}
	
	def preprocessAndExecuteAndSerialize(hu.bme.mit.gamma.statechart.interface_.Package _package,
			List<Expression> topComponentArguments, String targetFolderUri, String fileName) {
		return _package.preprocessAndExecute(topComponentArguments, targetFolderUri, fileName).serializeXSTS
	}

	def preprocessAndExecute(hu.bme.mit.gamma.statechart.interface_.Package _package,
			String targetFolderUri, String fileName) {
		val component = modelPreprocessor.preprocess(_package, #[], targetFolderUri, fileName, optimize)
		val newPackage = component.containingPackage
		return newPackage.execute
	}
	
	def preprocessAndExecute(hu.bme.mit.gamma.statechart.interface_.Package _package,
			List<Expression> topComponentArguments, String targetFolderUri, String fileName) {
		val component = modelPreprocessor.preprocess(_package, topComponentArguments,
			targetFolderUri, fileName, optimize)
		val newPackage = component.containingPackage
		return newPackage.execute
	}
	
	def execute(hu.bme.mit.gamma.statechart.interface_.Package _package) {
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
	
	protected def transformParameters(Component component, List<Expression> arguments) {
		val _package = component.containingPackage
		val parameterDeclarations = newArrayList
		parameterDeclarations += component.parameterDeclarations // So delete does not mess the list up
		// Theta back-annotation retrieves the argument values from the constant list
		for (parameter : parameterDeclarations) {
			val argumentConstant = createConstantDeclaration => [
				it.name = "__" + parameter.name + "Argument__"
				it.type = parameter.type.clone
				it.expression = arguments.get(parameter.index).clone
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
	
	protected def dispatch XSTS transform(AsynchronousAdapter component, Package lowlevelPackage) {
		// TODO maybe isTop boolean variables should be introduced as now in event actions are created discarded
		component.checkAdapter
		val wrappedInstance = component.wrappedComponent
		val wrappedType = wrappedInstance.type
		
		val messageQueue = component.messageQueues.head
		
		wrappedType.transformParameters(wrappedInstance.arguments) 
		val xSts = wrappedType.transform(lowlevelPackage)
		
		val inEventAction = xSts.inEventTransition
		// Deleting synchronous event assignments
		val xStsSynchronousInEventVariables = xSts.variableGroups
			.filter[it.annotation instanceof InEventGroup].map[it.variables]
			.flatten // There are more than one
		for (xStsAssignment : inEventAction.getAllContentsOfType(AbstractAssignmentAction)) {
			val xStsDeclaration = (xStsAssignment.lhs as DirectReferenceExpression).declaration
			if (xStsSynchronousInEventVariables.contains(xStsDeclaration)) {
				xStsAssignment.remove // Deleting in-event bool flags
			}
		}
		
		val extension eventRef = new EventReferenceToXstsVariableMapper(xSts)
		// Collecting the referenced event variables
		val xStsReferencedEventVariables = newHashSet
		for (eventReference : messageQueue.eventReference) {
			xStsReferencedEventVariables += eventReference.variables
		}
		
		val newInEventAction = createSequentialAction
		// Setting the referenced event variables to false
		for (xStsEventVariable : xStsReferencedEventVariables) {
			newInEventAction.actions += createAssignmentAction => [
				it.lhs = statechartUtil.createReferenceExpression(xStsEventVariable)
				it.rhs = createFalseExpression
			]
		}
		// Enabling the setting of the referenced event variables to true if no other is set
		for (xStsEventVariable : xStsReferencedEventVariables) {
			val negatedVariables = newArrayList
			negatedVariables += xStsReferencedEventVariables
			negatedVariables -= xStsEventVariable
			val branch = createIfActionBranch(
				xStsActionUtil.connectThroughNegations(negatedVariables),
				createAssignmentAction => [
					it.lhs = statechartUtil.createReferenceExpression(xStsEventVariable)
					it.rhs = createTrueExpression
				]
			)
			branch.extendChoiceWithBranch(createTrueExpression, createEmptyAction)
			newInEventAction.actions += branch
		}
		// Binding event variables that come from the same ports
		newInEventAction.actions += xSts.createEventAssignmentsBoundToTheSameSystemPort(wrappedType)
		 // Original parameter settings
		newInEventAction.actions += inEventAction.action
		// Binding parameter variables that come from the same ports
		newInEventAction.actions += xSts.createParameterAssignmentsBoundToTheSameSystemPort(wrappedType)
		xSts.inEventTransition = newInEventAction.wrap
		
		return xSts
	}
	
	protected def checkAdapter(AsynchronousAdapter component) {
		val messageQueues = component.messageQueues
		checkState(messageQueues.size == 1)
		// The capacity (and priority) do not matter, as they are from the environment
		checkState(component.clocks.empty)
		val controlSpecifications = component.controlSpecifications
		checkState(controlSpecifications.size == 1)
		val controlSpecification = controlSpecifications.head
		val trigger = controlSpecification.trigger
		checkState(trigger instanceof AnyTrigger)
		val controlFunction = controlSpecification.controlFunction
		checkState(controlFunction == ControlFunction.RUN_ONCE)
	}
	
	protected def dispatch XSTS transform(AbstractSynchronousCompositeComponent component, Package lowlevelPackage) {
		logger.log(Level.INFO, "Transforming abstract synchronous composite " + component.name)
		var XSTS xSts = null
		val scheduledInstances = component.scheduledInstances
		val mergedAction = if (component instanceof CascadeCompositeComponent) createSequentialAction else createOrthogonalAction
		val componentMergedActions = <Component, Action>newHashMap // To handle multiple schedulings in CascadeCompositeComponents
		for (var i = 0; i < scheduledInstances.size; i++) {
			val subcomponent = scheduledInstances.get(i)
			val type = subcomponent.type
			if (componentMergedActions.containsKey(type)) {
				// This type has already been transformed, this is just a new scheduling
				checkState(component instanceof CascadeCompositeComponent)
				mergedAction.actions += componentMergedActions.get(type).clone
			}
			else {
				// Normal transformation
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
					xSts.constraints += newXSts.constraints
					// Initializing action
					val variableInitAction = createSequentialAction
					variableInitAction.actions += xSts.variableInitializingTransition.action
					variableInitAction.actions += newXSts.variableInitializingTransition.action
					xSts.variableInitializingTransition = variableInitAction.wrap
					val configInitAction = createSequentialAction
					configInitAction.actions += xSts.configurationInitializingTransition.action
					configInitAction.actions += newXSts.configurationInitializingTransition.action
					xSts.configurationInitializingTransition = configInitAction.wrap
					val entryAction = createSequentialAction
					entryAction.actions += xSts.entryEventTransition.action
					entryAction.actions += newXSts.entryEventTransition.action
					xSts.entryEventTransition = entryAction.wrap
				}
				// Merged action
				val actualComponentMergedAction = createSequentialAction => [
					it.actions += newXSts.mergedAction
				]
				mergedAction.actions += actualComponentMergedAction
				// In and Out actions - using sequential actions to make sure they are composite actions
				// Methods reset... and delete... require this
				val newInEventAction = createSequentialAction => [ it.actions += newXSts.inEventTransition.action ]
				newXSts.inEventTransition = newInEventAction.wrap
				val newOutEventAction = createSequentialAction => [ it.actions += newXSts.outEventTransition.action ]
				newXSts.outEventTransition = newOutEventAction.wrap
				// Resetting channel events
				// 1) the Sync ort semantics: Resetting channel IN events AFTER schedule would result in a deadlock
				// 2) the Casc semantics: Resetting channel OUT events BEFORE schedule would delete in events of subsequent components
				// Note, System in and out events are reset in the env action
				if (component instanceof CascadeCompositeComponent) {
					// Resetting IN events AFTER schedule
					val clonedNewInEventAction = newInEventAction.clone
						.resetEverythingExceptPersistentParameters(type) // Clone is important
					actualComponentMergedAction.actions += clonedNewInEventAction // Putting the new action AFTER
				}
				else {
					// Resetting OUT events BEFORE schedule
					val clonedNewOutEventAction = newOutEventAction.clone // Clone is important
						.resetEverythingExceptPersistentParameters(type)
					actualComponentMergedAction.actions.add(0, clonedNewOutEventAction) // Putting the new action BEFORE
				}
				// In event
				newInEventAction.deleteEverythingExceptSystemEventsAndParameters(component)
				if (xSts !== newXSts) { // Only if this is not the first component
					val inEventAction = createSequentialAction
					inEventAction.actions += xSts.inEventTransition.action
					inEventAction.actions += newInEventAction
					xSts.inEventTransition = inEventAction.wrap
				}
				// Out event
				newOutEventAction.deleteEverythingExceptSystemEventsAndParameters(component)
				if (xSts !== newXSts) { // Only if this is not the first component
					val outEventAction = createSequentialAction
					outEventAction.actions += xSts.outEventTransition.action
					outEventAction.actions += newOutEventAction
					xSts.outEventTransition = outEventAction.wrap
				}
				// Tracing merged action
				componentMergedActions.put(type, actualComponentMergedAction.clone)
			}
		}
		xSts.name = component.name
		xSts.changeTransitions(mergedAction.wrap)
		logger.log(Level.INFO, "Deleting unused instance ports in " + component.name)
		xSts.deleteUnusedPorts(component) // Deleting variable assignments for unused ports
		// Connect only after xSts.mergedTransition.action = mergedAction
		logger.log(Level.INFO, "Connecting events through channels in " + component.name)
		xSts.connectEventsThroughChannels(component) // Event (variable setting) connecting across channels
		logger.log(Level.INFO, "Binding event to system port events in " + component.name)
		val oldInEventAction = xSts.inEventTransition
		val bindingAssignments = xSts.createEventAndParameterAssignmentsBoundToTheSameSystemPort(component)
		// Optimization: removing old NonDeterministicActions 
		bindingAssignments.removeNonDeterministicActionsReferencingAssignedVariables(oldInEventAction.action)
		val newInEventAction = createSequentialAction => [
			it.actions += oldInEventAction.action
			// Bind together ports connected to the same system port
			it.actions += bindingAssignments
		]
		xSts.inEventTransition = newInEventAction.wrap
		return xSts
	}
	
	protected def dispatch XSTS transform(StatechartDefinition statechart, Package lowlevelPackage) {
		logger.log(Level.INFO, "Transforming statechart " + statechart.name)
		// Note that the package is already transformed and traced because of the "val lowlevelPackage = gammaToLowlevelTransformer.transform(_package)" call
		val lowlevelStatechart = gammaToLowlevelTransformer.transform(statechart)
		lowlevelPackage.components += lowlevelStatechart
		val lowlevelToXSTSTransformer = new LowlevelToXstsTransformer(lowlevelPackage, optimize, useHavocActions)
		val xStsEntry = lowlevelToXSTSTransformer.execute
		lowlevelPackage.components -= lowlevelStatechart // So that next time the matches do not return elements from this statechart
		val xSts = xStsEntry.key
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
				val maxValue = xStsClockVariable.greatestComparison
				val incrementExpression = createAddExpression => [
					it.operands += statechartUtil.createReferenceExpression(xStsClockVariable)
					it.operands += statechartUtil.toIntegerLiteral(schedulingConstraint)
				]
				val rhs = (maxValue === null) ? incrementExpression :
					createIfThenElseExpression => [
						it.condition = createLessExpression => [
							it.leftOperand = statechartUtil.createReferenceExpression(xStsClockVariable)
							it.rightOperand = statechartUtil.toIntegerLiteral(maxValue)
						]
						it.then = incrementExpression
						it.^else = statechartUtil.createReferenceExpression(xStsClockVariable)
					]
				it.actions += createAssignmentAction => [
					it.lhs = statechartUtil.createReferenceExpression(xStsClockVariable)
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
	
	protected def void setSchedulingAnnotation(
			hu.bme.mit.gamma.statechart.interface_.Package _package, Integer schedulingConstraint) {
		if (schedulingConstraint !== null) {
			if (!_package.annotations.exists[it instanceof SchedulingConstraintAnnotation]) {
				_package.annotations += createSchedulingConstraintAnnotation => [
					it.schedulingConstraint = statechartUtil.toIntegerLiteral(schedulingConstraint)
				]
				_package.save
			}
		}
	}
	
	protected def void customizeDeclarationNames(XSTS xSts, ComponentInstance instance) {
		val type = instance.derivedType
		if (type instanceof StatechartDefinition) {
			// Customizing every variable name
			for (variable : xSts.variableDeclarations) {
				variable.name = variable.getCustomizedName(instance)
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
		
		for (port : component.allConnectedSimplePorts) {
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