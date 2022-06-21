/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.phase.History
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.SchedulingOrder
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.Collection

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.ComponentDeactivator.Namings.*

class ComponentDeactivator {
	
	static Interface activityInterface // Singleton
	static Event activityEvent // Singleton
	static ParameterDeclaration isActiveParameter // Singleton
	
	//
	
	final Component component
//	final boolean hasHistory
//	final boolean needNegatedActivityTriggers
//	final boolean needLoopTransitionForInitialStates

	final History history
	final Collection<VariableDeclaration> unresettableDeclarations = newHashSet
	
	//
	
	Port activityPort
	
	//
	
	protected static final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	
	protected static final InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE
	protected static final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected static final extension StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE
	
	//
	
//	new(Component component) {
//		this(component, false)
//	}
//	
//	new(Component component, boolean hasHistory) {
//		this(component, hasHistory, false, false)
//	}
//	
//	new(Component component, boolean hasHistory,
//			boolean needNegatedActivityTriggers, boolean needLoopTransitionForInitialStates) {
//		this(component, hasHistory,
//			needNegatedActivityTriggers, needLoopTransitionForInitialStates, #[])
//	}
//	
//	new(Component component,
//			boolean hasHistory, boolean needNegatedActivityTriggers, boolean needLoopTransitionForInitialStates,
//			Collection<? extends VariableDeclaration> unresettableDeclarations) {
//		this.component = component // Statechart or composite component
//		this.hasHistory = hasHistory // Loop or initial state targeting deactivating transitions
//		this.needNegatedActivityTriggers = needNegatedActivityTriggers // To handle that deactivating transitions are only introduced to the top region
//		this.needLoopTransitionForInitialStates = needLoopTransitionForInitialStates // To handle initial blocks
//		this.unresettableDeclarations += unresettableDeclarations // To handle tied variables
//	}

	new(Component component, History history) {
		this(component, history, #[]);
	}
	
	new(Component component, History history,
			Collection<? extends VariableDeclaration> unresettableDeclarations) {
		this.component = component // Statechart or composite component
		this.history = history // Initial state, shallow or deep history
		this.unresettableDeclarations += unresettableDeclarations // To handle tied variables
	}
	
	def static getActivityInterface() {
		if (activityInterface === null) {
			val activityInterface = interfaceFactory.createInterface
			activityInterface.name = activityInterfaceName
			val eventDeclaration = interfaceFactory.createEventDeclaration
			activityInterface.events += eventDeclaration
			eventDeclaration.direction = EventDirection.OUT
			val event = interfaceFactory.createEvent
			eventDeclaration.event = event
//			event.persistency = Persistency.PERSISTENT
			event.name = activityEventName
			ComponentDeactivator.activityEvent = event
			
			ComponentDeactivator.isActiveParameter = event.extendEventWithParameter(
					expressionFactory.createBooleanTypeDefinition, activityParameterName)
			
			ComponentDeactivator.activityInterface = activityInterface
		}
		return activityInterface
	}
	
	def static getActivityEvent() {
		if (activityInterface === null) {
			getActivityInterface
		}
		return activityEvent
	}
	
	def addActivityPort() {
		if (activityPort !== null) {
			throw new IllegalArgumentException("Activity port us already created: " + activityPort.name)
		}
		this.activityPort = activityInterface.createPort(
				RealizationMode.REQUIRED, component.activityPortName)
		component.ports += activityPort
		
		return activityPort
	}
	
//	def addDeactivatingTransitions() {
//		getActivityInterface // To make sure all the events are created
//		
//		val transitions = component.getAllContentsOfType(Transition)
//				.filter[it.leavingState]
//		// Extending all transitions with a guard that handles activity
//		for (transition : transitions) {
//			if (needNegatedActivityTriggers) {
//				val notTrigger = activityPort.createEventTrigger(activityEvent)
//						.createUnaryTrigger(UnaryType.NOT)
//				// To counter top-down or bottom-up scheduling in synchronous statecharts
//				transition.extendTrigger(notTrigger, BinaryType.AND)
//			}
//			
//			val guard = transition.guard
//			val isActiveExpression = activityPort.createEventParameterReference(isActiveParameter)
//			val extendedGuard = guard.wrapIntoAndExpression(isActiveExpression)
//			transition.guard = extendedGuard
//		}
//		
//		// Handling deactivations by introducing new transitions to the top regions
//		val statecharts = component.getSelfAndAllContentsOfType(StatechartDefinition)
//		val topRegions = statecharts.map[it.regions].flatten
//		for (region : topRegions) {
//			// It is enough to introduce these deactivating transitions to the top region
//			// as all other transitions are deactivated by the not trigger and isActiveParameter guard
//			val initialState = region.initialState
//			val states = region.states
//			
//			if (!needLoopTransitionForInitialStates) {
//				states -= initialState // If it handles an initial block, timing cannot be put here anyway
//			}
//			
//			for (State state : states) {
//				val targetState = (hasHistory) ? state : initialState
//				val deactivatingTransition = state.createTransition(targetState)
//				val deactivatingTrigger = activityPort.createEventTrigger(activityEvent)
//				deactivatingTransition.trigger = deactivatingTrigger
//				// We do not add an event parameter reference to support loop edges in adaptive states
//				// that deactivate and activate the contract in a 'single cycle'
//				// This works as all activity events denote deactivation inside the contact
////				EventParameterReferenceExpression isActiveExpression =
////						statechartUtil.createEventParameterReference(activityPort, isActiveParameter);
////				NotExpression isNotActiveExpression =
////						statechartUtil.createNotExpression(isActiveExpression);
////				deactivatingTransition.setGuard(isNotActiveExpression);
//				// Note that this way, deactivation has priority over anything
//				val highestPriority = state.highestPriority
//				deactivatingTransition.priority = highestPriority.add(BigInteger.ONE)
//				// Resetting variables if necessary
//				if (!hasHistory) {
//					val statechart = region.containingStatechart
//					val variables = newLinkedHashSet
//					variables += statechart.variableDeclarations
//					variables -= unresettableDeclarations
//					for (variable : variables) {
//						val variableInitializationAction = variable.createAssignment(
//								variable.initialValue)
//						deactivatingTransition.effects += variableInitializationAction
//					}
//				}
//			}
//		}
//	}
	
	def makeContractDeactivatable() {
		checkState(component.statechart)
		
		makeComponentDeactivatable
		// Handle initial/entry output blocks: these blocks are executed on activation in the case of history, too
		val statechart = component as StatechartDefinition
		if (statechart.hasInitialOutputsBlock) {
			val topRegion = statechart.regions
					.onlyElement
			val activityState = topRegion.states
					.findFirst[it.name == activeStateName]
			val originalRegion = activityState.regions
					.onlyElement
			val initialBlockState = originalRegion.initialState
			val incomingTransitionOfInitialBlockState = initialBlockState
					.incomingTransitions
					.reject[it.loop] // Cold violation loop edges
					.onlyElement
					
			topRegion.stateNodes += initialBlockState
			val isActiveTransition = activityState.incomingTransition
			isActiveTransition.targetState = initialBlockState
			
			val nonTrappingOutgoingTransitions = initialBlockState
					.nonTrappingOutgoingTransitions
			// Entering the violation (and accept) state(s)
			val firstValidState = nonTrappingOutgoingTransitions
					.reject[it.loop] // Cold violation loop edges
					.map[it.targetState]
					.toSet // Can be multiple "parallel" transitions to the same state
					.onlyElement // state0
			incomingTransitionOfInitialBlockState.targetState = firstValidState
			for (nonTrappingOutgoingTransition : nonTrappingOutgoingTransitions) {
				nonTrappingOutgoingTransition.targetState = activityState
			}
			
			if (statechart.synchronous) {
				val choiceState = createChoiceState
				choiceState.name = initialBlockState.name
				choiceState.changeAndReplace(initialBlockState, statechart)
			}
		}
		
		// TODO handle accept and violation states in the case of history 
	}
	
	
	def makeBehaviorDeactivatable() {
		makeComponentDeactivatable
		
		val statecharts = component.getSelfAndAllContentsOfType(StatechartDefinition)
		for (statechart : statecharts) {
			val schedulingOrder = statechart.schedulingOrder
			if (schedulingOrder != SchedulingOrder.TOP_DOWN) {
				val transitions = component.getAllContentsOfType(Transition)
						.filter[it.leavingState]
				for (transition : transitions) {
					val notTrigger = activityPort.createEventTrigger(activityEvent)
							.createUnaryTrigger(UnaryType.NOT)
					// To counter top-down or bottom-up scheduling in synchronous statecharts
					transition.extendTrigger(notTrigger, BinaryType.AND)
				}
			}
		}
	}
	
	protected def makeComponentDeactivatable() {
		val statecharts = component.getSelfAndAllContentsOfType(StatechartDefinition)
		for (statechart : statecharts) {
			val originalRegions = newArrayList
			originalRegions += statechart.regions
			for (originalRegion : originalRegions) {
				val originalEntry = originalRegion.entryState
				val newEntry = history.createEntryState
				newEntry.name = newEntry.getEntryStateName(originalRegion)
				newEntry.changeAndReplace(originalEntry, statechart)
			}
			
			val initialState = createInitialState /* No matter */
			initialState.name = entryStateName
			val inactivityState = statechart.createRegionWithState(
					initialState, topActivityRegionName, inactiveStateName)
			
			val activityRegion = inactivityState.parentRegion
			val activityState = createState
			activityState.name = activeStateName
			activityRegion.stateNodes += activityState
			
			activityState.regions += originalRegions
			
			val mergeState = createMergeState
			mergeState.name = mergeStateName
			activityRegion.stateNodes += mergeState
			
			val choiceState = createChoiceState
			choiceState.name = choiceStateName
			activityRegion.stateNodes += choiceState
			
			val activityTransition = activityState.createMaximumPriorityTransition(mergeState)
			activityTransition.trigger = activityPort.createEventTrigger(activityEvent)
			
			val inactivityTransition = inactivityState.createMaximumPriorityTransition(mergeState)
			inactivityTransition.trigger = activityPort.createEventTrigger(activityEvent)
			
			val mergeChoiceTransition = mergeState.createMaximumPriorityTransition(choiceState)
			// Resetting variables if necessary
			if (!activityRegion.hasHistory) {
				val variables = newLinkedHashSet
				variables += statechart.variableDeclarations
				variables -= unresettableDeclarations
				for (variable : variables) {
					val variableInitializationAction = variable.createAssignment(
							variable.initialValue)
					mergeChoiceTransition.effects += variableInitializationAction
				}
			}
			
			val isActiveTransition = choiceState.createMaximumPriorityTransition(activityState)
			isActiveTransition.guard = activityPort.createEventParameterReference(isActiveParameter)
			
			val isInactiveTransition = choiceState.createMaximumPriorityTransition(inactivityState)
			isInactiveTransition.guard = activityPort.createEventParameterReference(isActiveParameter)
					.createNotExpression
		}
	}
	
	def getComponent() {
		return component
	}
	
	///
	
	static class Namings {
	
		//
	
		def static String getActivityPortName(Component component) {
			return component.name + "_Activity"
		}
		
		def static String getActivityInterfaceName() {
			return "Activity"
		}
		
		def static String getActivityEventName() {
			return "activity"
		}
		
		def static String getActivityParameterName() {
			return "isActive"
		}
		
		//
		
		def static String getEntryStateName() {
			return "__Initial__"
		}
		
		def static String getEntryStateName(EntryState entry, Region region) {
			return "__" + entry.eClass.name + "Of" + region.name + "__"
		}
		
		def static String getTopActivityRegionName() {
			return "__activity__"
		}
		
		def static String getActiveStateName() {
			return "__Activated__"
		}
		
		def static String getInactiveStateName() {
			return "__Deactivated__" // Cannot be "__Inactive__"
		}
		
		def static String getMergeStateName() {
			return "__Merge__"
		}
		
		def static String getChoiceStateName() {
			return "__Choice__"
		}
		
	}
	
}