/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.ElementSerializer
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.Cycle
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkArgument
import static com.google.common.base.Preconditions.checkNotNull

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class UnfoldedExecutionTraceBackAnnotator {
	
	protected final ExecutionTrace trace
	protected final Component originalTopComponent
	protected final boolean sortTrace
	
	//
	
	protected final Collection<Expression> dummyAsserts = newArrayList
	protected final Collection<OpaqueExpression> metadata = newArrayList
	
	protected final InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final CompositeModelFactory compositeModelFactory = CompositeModelFactory.eINSTANCE
	protected final ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension TraceModelFactory traceModelFactory = TraceModelFactory.eINSTANCE
	protected final extension ElementSerializer elementSerializer = ElementSerializer.INSTANCE
	protected final extension UnfoldingTraceability traceability = UnfoldingTraceability.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	public static final String TRAP_STATE_ID = "_TrapState_"
	public static final String TRAP_STATE_MESSAGE_BEGINNING = "Trap state entered in"
	
	public static final String EXECUTED_TRANSITION_VARIABLE_BEGINNING = "__id_"
	public static final String EXECUTED_TRANSITION_VARIABLE_END = "_"
	public static final String EXECUTED_TRANSITION_MESSAGE_BEGINNING = TraceModelDerivedFeatures.TRANSITION_EXEC_PREFIX
	
	public static final String SENT_INTERACTION_VARIABLE_BEGINNING = EXECUTED_TRANSITION_VARIABLE_BEGINNING + "first_"
	public static final String RECEIVED_INTERACTION_VARIABLE_BEGINNING = EXECUTED_TRANSITION_VARIABLE_BEGINNING + "second_"
	public static final String INTERACTION_SENDING_BEGINNING = "Interaction sent by: "
	public static final String INTERACTION_RECEIVING_BEGINNING = "Interaction received by: "
	//
	
	new(ExecutionTrace trace, Component originalTopComponent) {
		this(trace, originalTopComponent, true)
	}
	
	new(ExecutionTrace trace, Component originalTopComponent, boolean sortTrace) {
		checkNotNull(originalTopComponent)
		checkArgument(!originalTopComponent.statechart,
				"The original component cannot be a statechart")
		this.trace = trace
		this.originalTopComponent = originalTopComponent
		this.sortTrace = sortTrace
	}
	
	def execute() {
		val originalExecutionTrace = createExecutionTrace => [
			it.import = originalTopComponent.containingPackage
			it.annotations += trace.annotations.map[it.clone] // References not expected
			it.name = trace.name
			it.component = originalTopComponent
			it.arguments += trace.arguments.map[it.transformExpression]
		]
		
		val steps = trace.steps
		for (step : steps) {
			originalExecutionTrace.steps += step.transformStep
		}
		
		// Potential cycle at the end
		val cycle = trace.cycle
		if (cycle !== null) {
			originalExecutionTrace.cycle = cycle.transformCycle		
		}
		
		// There are injected variables that cannot be back-annotated
		removeDummyAsserts
		handleMetadata
		// After removing dummy asserts (nulls)
		if (sortTrace) {
			originalExecutionTrace.sortInstanceStates
		}
		
		return originalExecutionTrace
	}
	
	
	// Step
	
	protected def transformStep(Step step) {
		val newStep = createStep
		
		for (act : step.actions) {
			newStep.actions += act.transformAct
		}
		
		for (assert : step.asserts) {
			newStep.asserts += assert.transformAssert
		}
		// Handling removed (reduced) variables (if any)
		newStep.handleRemovedStatesAndVariables
		
		return newStep
	}
	
	protected def transformCycle(Cycle cycle) {
		val newCycle = createCycle
		
		for (step : cycle.steps) {
			newCycle.steps += step.transformStep
		}
		
		return newCycle
	}
	
	// Acts
	
	protected def dispatch transformAct(RaiseEventAct act) {
		return createRaiseEventAct => [
			it.port = originalTopComponent.getOriginalPort(act.port)
			// Works if the interfaces/types are loaded into different resources
			// even when resource set and URI type (absolute/platform) must match
			it.event = originalTopComponent.getOriginalEvent(act.event)
			it.arguments += act.arguments
					.map[it.transformAssert]
		]
	}
	
	protected def dispatch transformAct(Reset act) {
		return createReset
	}
	
	protected def dispatch transformAct(ComponentSchedule act) {
		return createComponentSchedule
	}
	
	protected def dispatch transformAct(InstanceSchedule act) {
		val instanceReference = act.instanceReference
		val instance = instanceReference.componentInstance
		
		val oldInstanceReference = instance.getOriginalScheduledInstanceReference(originalTopComponent)
		
		return createInstanceSchedule => [
			it.instanceReference = oldInstanceReference
		]
	}
	
	protected def dispatch transformAct(TimeElapse act) {
		return createTimeElapse => [
			it.elapsedTime = act.elapsedTime.clone
		]
	}
	
	// Asserts
	
	protected def dispatch Expression transformAssert(ComponentInstanceStateReferenceExpression assert) {
		val newState = assert.state
		val instance = assert.instance.lastInstance as SynchronousComponentInstance
		val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
		try {
			val originalState = originalInstance.getOriginalState(newState)
			val originalReference = originalInstance.createStateReference(originalState)
			return originalReference
		} catch (IllegalArgumentException e) {
			val message = e.message.trim
			if (message.startsWith("Not found state")) {
				val metadataMessage = assert.backAnnotate
				if (metadataMessage !== null) {
					return metadataMessage
				}
				
				logger.warning(message)
				val trueExpression = expressionModelFactory.createTrueExpression
				dummyAsserts += trueExpression
				return trueExpression
			}
			throw e
		}
	}
	
	protected def dispatch Expression transformAssert(ComponentInstanceVariableReferenceExpression assert) {
		val instance = assert.instance.lastInstance as SynchronousComponentInstance
		val variable = assert.variableDeclaration
		val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
		val originalVariable = try {
			originalInstance.getOriginalVariable(variable)
		} catch (IllegalArgumentException e) {
			val message = e.message.trim
			if (message.startsWith("Not found variable")) {
				val metadataMessage = assert.backAnnotate
				if (metadataMessage !== null) {
					return metadataMessage
				}
			}
			
			logger.info("Not found original variable for " + variable)
			null
		}
		
		val variableState = statechartUtil.createVariableReference(
				originalInstance, originalVariable)
		if (originalVariable === null) {
			dummyAsserts += variableState
		}
		
		return variableState
	}
	
	protected def dispatch Expression transformAssert(RaiseEventAct assert) {
		return assert.transformAct as RaiseEventAct // Same as act
	}
	
	protected def dispatch Expression transformAssert(EventParameterReferenceExpression assert) {
		return interfaceModelFactory.createEventParameterReferenceExpression => [
			it.port = originalTopComponent.getOriginalPort(assert.port)
			// Works if the interfaces/types are loaded into different resources
			// even when resource set and URI type (absolute/platform) must match
			it.event = originalTopComponent.getOriginalEvent(assert.event)
			it.parameterDeclaration = it.event.parameterDeclarations.get(assert.parameterDeclaration.index)
		]
	}
	
	protected def dispatch Expression transformAssert(MultiaryExpression assert) {
		val multiaryAssert = expressionModelFactory.create(assert.eClass) as MultiaryExpression
		
		for (operand : assert.operands) {
			multiaryAssert.operands += operand.transformAssert
		}
		
		return multiaryAssert
	}
	
	protected def dispatch Expression transformAssert(BinaryExpression assert) {
		val binaryAssert = expressionModelFactory.create(assert.eClass) as BinaryExpression
		
		binaryAssert.leftOperand = assert.leftOperand.transformAssert
		binaryAssert.rightOperand = assert.rightOperand.transformAssert
		
		return binaryAssert
	}
	
	protected def dispatch Expression transformAssert(UnaryExpression assert) {
		val unaryAssert = expressionModelFactory.create(assert.eClass) as UnaryExpression
		
		unaryAssert.operand = assert.operand.transformAssert
		
		return unaryAssert
	}
	
	protected def dispatch Expression transformAssert(Expression assert) {
		return assert.transformExpression
	}
	
	//
	
	protected def Expression transformExpression(Expression value) {
		val clonedValue = value.clone
		
		// Type declarations
		val typeDeclarations = newLinkedHashSet
		
		val typeReferences = clonedValue.getSelfAndAllContentsOfType(TypeReference)
		typeDeclarations += typeReferences.map[it.reference]
		val recordLiterals = clonedValue.getSelfAndAllContentsOfType(RecordLiteralExpression)
		typeDeclarations += recordLiterals.map[it.typeDeclaration]
		
		for (typeDeclaration : typeDeclarations) {
			val originalTypeDeclaration = originalTopComponent
					.getOriginalTypeDeclaration(typeDeclaration)
			
			typeReferences.filter[it.reference === typeDeclaration]
					.forEach[it.reference = originalTypeDeclaration]
			recordLiterals.filter[it.typeDeclaration === typeDeclaration]
					.forEach[it.typeDeclaration = originalTypeDeclaration]
		}
		
		// Record fields
		for (recordLiteral : recordLiterals) {
			val recordType = recordLiteral.typeDeclaration.typeDefinition as RecordTypeDefinition
			for (fieldAssignment : recordLiteral.fieldAssignments) {
				val field = fieldAssignment.reference.fieldDeclaration
				val originalField = recordType.fieldDeclarations.findFirst[it.name == field.name] // TODO getOriginalFieldDeclaration
				fieldAssignment.reference = originalField.createReferenceExpression
				fieldAssignment.value = fieldAssignment.value.transformExpression
			}
		}
		
		// Enum literal setting in addition to the type reference setting
		if (clonedValue instanceof EnumerationLiteralExpression) {
			val enumLiteral = clonedValue.reference
			val originalEnumLiteral = originalTopComponent
					.getOriginalEnumLiteral(enumLiteral)
			clonedValue.reference = originalEnumLiteral
		}
		
		return clonedValue
	}
	
	//
	
	protected def void handleRemovedStatesAndVariables(Step step) {
		val variableInstances = step.asserts
				.map[it.getSelfAndAllContentsOfType(ComponentInstanceVariableReferenceExpression)]
				.flatten
		val stateInstances = step.asserts
				.map[it.getSelfAndAllContentsOfType(ComponentInstanceStateReferenceExpression)]
				.flatten
		
		val instances = originalTopComponent.allSimpleInstanceReferences
		for (instance : instances) {
			val statechart = instance.lastInstance.derivedType
			if (statechart instanceof StatechartDefinition) {
				val statechartVariables = statechart.variableDeclarations
				val presentInstanceVariables = variableInstances.filter[it.instance.name == instance.name]
				val presentVariables = presentInstanceVariables.map[it.variableDeclaration]
				
				val absentVariables = statechartVariables.filter[!presentVariables.contains(it)]
				for (absentVariable : absentVariables) {
					// We know what to do only if the variable is unwritten
					if (absentVariable.unwritten) {
						val unwrittenVariable = instance.clone
								.createVariableReference(absentVariable)
						val value = absentVariable.initialValue
						
						val assertion = unwrittenVariable.createEqualityExpression(value)
						step.asserts += assertion
					}
				}
				
				val statechartRegions = statechart.allRegions
				val presentRegions = stateInstances.filter[it.instance.name == instance.name].map[it.region]
				
				val absentRegions = statechartRegions.filter[!presentRegions.contains(it)]
				for (absentRegion : absentRegions) {
					val states = absentRegion.states
					// We know what to do only if there is one state in the region
					if (states.size == 1 &&
							(absentRegion.topRegion || presentRegions.contains(absentRegion.parentState))) { // Could be more sophisticated
						val initialStateAssertion = instance.clone
								.createStateReference(states.head)
								
						step.asserts += initialStateAssertion
					}
				}
			}
		}
	}
	
	//
	
	protected def backAnnotate(ComponentInstanceStateReferenceExpression assert) {
		val instance = assert.instance.lastInstance as SynchronousComponentInstance
		val state = assert.state
		val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
		val name = state.name
		
		// Injected state for checking nondeterministic behavior
		if (name == TRAP_STATE_ID) {
			val regionName = state.parentRegion.name
			val instanceName = originalInstance.name
			
			val metadataMessage = '''«TRAP_STATE_MESSAGE_BEGINNING» region «regionName» of «instanceName»'''
					.createOpaqueExpression
			
			return metadataMessage
		}
		
		return null
	}
	
	protected def backAnnotate(ComponentInstanceVariableReferenceExpression assert) {
		val instance = assert.instance.lastInstance as SynchronousComponentInstance
		val variable = assert.variableDeclaration
		val name = variable.name
		
		// All for 'transition', 'transition-pair' and 'interaction' coverage
		if (name.startsWith(EXECUTED_TRANSITION_VARIABLE_BEGINNING) &&
				name.endsWith(EXECUTED_TRANSITION_VARIABLE_END)) {
			val container = assert.eContainer
			if (container instanceof Step || container instanceof EqualityExpression) {
				val rhs = (container instanceof EqualityExpression) ? container.rightOperand : 
						expressionModelFactory.createTrueExpression
				// There should be one 'true' or 'integer literal' assignment to this variable
				val statechart = instance.derivedType
				if (statechart instanceof StatechartDefinition) {
					val transitions = statechart.transitions
					val executedTransitions = transitions.filter[
							it.effects.filter(AssignmentStatement)
								.exists[it.lhs.declaration == variable && it.rhs.helperEquals(rhs)]]
					if (!executedTransitions.empty) {
						// 'Transition' (and/or '-pair') or 'interaction reception'
						val executedTransition = executedTransitions.head
						val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
						
						val prefix = name.startsWith(RECEIVED_INTERACTION_VARIABLE_BEGINNING) ?
								INTERACTION_RECEIVING_BEGINNING : EXECUTED_TRANSITION_MESSAGE_BEGINNING
						val metadataMessage = executedTransition.getMetadata(originalInstance, prefix)
						
						return metadataMessage
					}
					else {
						// Sender of 'interaction' coverage
						val newComponent = trace.component
						for (senderInstance : newComponent.allSynchronousSimpleInstances) {
							val senderStatechart = senderInstance.getStatechart
							
							val allStates = senderStatechart.allStates
							val allTransitions = senderStatechart.transitions
							val actions = allStates.map[it.entryActions + it.exitActions].flatten +
									allTransitions.map[it.effects].flatten
							val raiseEventActions = actions.map[it.getSelfAndAllContentsOfType(RaiseEventAction)].flatten.toSet
							val executedActions = raiseEventActions
									.filter[!it.arguments.empty && it.arguments.lastOrNull.helperEquals(rhs)]
							if (!executedActions.empty) {
								val originalSenderInstance = senderInstance.getOriginalSimpleInstanceReference(originalTopComponent)
								val action = executedActions.head
								val transitionOrState = action.containingTransitionOrState
								if (transitionOrState instanceof Transition) {
									val metadataMessage = transitionOrState.getMetadata(originalSenderInstance, INTERACTION_SENDING_BEGINNING)
									
									return metadataMessage
								}
								else if (transitionOrState instanceof State) {
									val stateName = transitionOrState.name
									val regionName = transitionOrState.parentRegion.name
									val instanceName = originalSenderInstance.name
									
									val metadataMessage = '''«INTERACTION_SENDING_BEGINNING»state «stateName» region «regionName» of «instanceName»'''
											.createOpaqueExpression
									
									return metadataMessage
								}
							}
						}
					}
				}
			}
		}
		
		return null
	}
	
	protected def getMetadata(Transition newTransition,
			ComponentInstanceReferenceExpression originalInstance, String prefix) {
		val transition = try {
			originalInstance.getOriginalTransition(newTransition)
		} catch (IllegalArgumentException e2) {
			// Did not find the original transition
			newTransition
		}
		val instanceName = originalInstance.name
		
		val metadataMessage = prefix.getTransitionMessage(transition, instanceName)
					.createOpaqueExpression
		metadata += metadataMessage
		
		return metadataMessage
	}
	
	protected def getTransitionMessage(String prefix, Transition transition, String instanceName)
		'''«prefix»«transition.serialize» of «instanceName»'''
	
	//
	
	protected def removeDummyAsserts() {
		dummyAsserts.removeContainmentChains(Expression)
		dummyAsserts.clear
	}
	
	protected def handleMetadata() {
		for (data : metadata) {
			val container = data.eContainer
			if (!(container instanceof Step)) {
				val topmostExpression = data.getChildOfContainerOfType(Step)
				data.replace(topmostExpression)
			}
		}
		
		metadata.clear
	}
	
}