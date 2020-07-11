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
package hu.bme.mit.gamma.plantuml.transformation

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.action.model.ExpressionStatement
import hu.bme.mit.gamma.action.model.Statement
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference
import hu.bme.mit.gamma.statechart.statechart.CompositeElement
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.ForkState
import hu.bme.mit.gamma.statechart.statechart.InitialState
import hu.bme.mit.gamma.statechart.statechart.JoinState
import hu.bme.mit.gamma.statechart.statechart.MergeState
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger
import hu.bme.mit.gamma.statechart.statechart.OpaqueTrigger
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.PseudoState
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.statechart.TimeoutAction
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer

class StatechartToPlantUMLTransformer {
	
	protected final StatechartDefinition statechart
	
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE

	new(StatechartDefinition statechart) {
		this.statechart = statechart
	}

	def execute() {
		return statechart.mainRegionSearch
	}
	
///////////////////// TRIGGER DISPATCH /////////////////////	

	// Handling the possible instances of triggers
	
	protected def dispatch String transformTrigger(EventTrigger eventTrigger) {
		return eventTrigger.eventReference.transformEventReference
	}

	protected def dispatch String transformTrigger(AnyTrigger anyTrigger) {
		return "any"
	}

	protected def dispatch String transformTrigger(OnCycleTrigger onCycleTrigger) {
		return "cycle"
	}

	protected def dispatch String transformTrigger(OpaqueTrigger opaqueTrigger) {
		return opaqueTrigger.trigger
	}

	protected def dispatch String transformTrigger(BinaryTrigger binaryTrigger) {
		if (binaryTrigger.type.value == 0) {
			return binaryTrigger.leftOperand.transformTrigger + " && " + binaryTrigger.rightOperand.transformTrigger
		} else if (binaryTrigger.type.value == 1) {
			return binaryTrigger.leftOperand.transformTrigger + " || " + binaryTrigger.rightOperand.transformTrigger
		} else if (binaryTrigger.type.value == 2) {
			return binaryTrigger.leftOperand.transformTrigger + " == " + binaryTrigger.rightOperand.transformTrigger
		} else if (binaryTrigger.type.value == 4) {
			return binaryTrigger.leftOperand.transformTrigger + " ^ " + binaryTrigger.rightOperand.transformTrigger
		} else if (binaryTrigger.type.value == 5) {
			return binaryTrigger.leftOperand.transformTrigger + " -> " + binaryTrigger.rightOperand.transformTrigger
		}
	}

	protected def dispatch String transformTrigger(UnaryTrigger unaryTrigger) {
		if (unaryTrigger.type.value == 0) {
			return " !" + unaryTrigger.operand.transformTrigger
		}
	}
	
///////////////////// EVENT REFERENCE DISPATCH /////////////////////	

	// Handling the different instances of event references

	protected def dispatch transformEventReference(PortEventReference portEventReference) {
		return (portEventReference.port.name + "." + portEventReference.event.name)
	}

	protected def dispatch transformEventReference(TimeoutEventReference timeoutEventReference) {
		return '''timeout «timeoutEventReference.timeout.name»'''
	}

	protected def dispatch transformEventReference(ClockTickReference clockTickReference) {
		return (clockTickReference.clock.name + " : " + clockTickReference.clock.timeSpecification.value + " " +
			clockTickReference.clock.timeSpecification.unit)
	}

	protected def dispatch transformEventReference(AnyPortEventReference anyPortEventReference) {
		return anyPortEventReference.port.name
	}
	
///////////////////// FORK,JOIN,CHOICE,MERGE DISPATCH /////////////////////

	// Handling the fork, join, choice and merge pseudostates
	// The initial and history states are not handled in this section, but instead in the stateSearch() method,
	// because it was more convenient that way.
	protected def dispatch transformPseudoState(ForkState forkState) {
		return "state " + forkState.name + " <<fork>>"
	}

	protected def dispatch transformPseudoState(JoinState joinState) {
		return "state " + joinState.name + " <<join>>"
	}

	protected def dispatch transformPseudoState(ChoiceState choiceState) {
		return "state " + choiceState.name + " <<choice>>"
	}

	protected def dispatch transformPseudoState(MergeState mergeState) {
		return "state " + mergeState.name + " <<choice>>"
	}

	protected def dispatch transformPseudoState(EntryState entryState) {
	}

///////////////////// ACTION DISPATCH /////////////////////

	// Handling the different instances of actions
	
	protected def dispatch transformActionReference(Action action) {
		throw new IllegalArgumentException("Not known action: " + action)
	}

	protected def dispatch transformActionReference(ExpressionStatement expressionStatement) {
		return expressionStatement.expression.serialize + ";"
	}
	
	protected def dispatch transformActionReference(AssignmentStatement assignmentStatement) {
		return assignmentStatement.lhs.serialize + " := " + assignmentStatement.rhs.serialize + ";"
	}
	
	protected def dispatch transformActionReference(RaiseEventAction raisedEventAction) {
		return "raise " + raisedEventAction.port.name + "." + raisedEventAction.event.name +
			'''(«FOR argument : raisedEventAction.arguments»«argument.serialize»«ENDFOR»);'''
	}

	protected def dispatch transformActionReference(TimeoutAction timeoutAction) {
		val setTimeout = timeoutAction as SetTimeoutAction
		val integer = setTimeout.time.value.serialize
		return "set " + timeoutAction.timeoutDeclaration.name + " := " + integer + " " +
			setTimeout.time.unit.serialize + ";"
	}
	
	protected def serialize(TimeUnit timeUnit) {
		switch (timeUnit) {
			case SECOND: "s"
			case MILLISECOND: "ms"
			default: throw new IllegalArgumentException("Not known time unit: " + timeUnit)
		}
	}
	
///////////////////// OTHER FUNCTIONS /////////////////////

	// Other methods that are required in the transformation
	/**
	 * regionSearch(StateNode, StatechartDefinition)
	 * 
	 * This method searches the inner states of composite states. The parameters are the following:
	 * The state whose regions we want to find, and the statechart, from which all transitions can be easily
	 * accessed.
	 * This method is necessary because of the syntax of PlantUml. Composite states are defined this way:
	 * 
	 * state State1{
	 * 	[*] --> State2
	 * }
	 * 
	 * Internal states have to be listed "inside" the composite state.
	 * The regions of composite states help us to achieve this.
	 * This method checks if the state received as parameter has regions, with the help of the
	 * regionDispatch() method.
	 * If it has, then it will search the pseudostates first (except initial and history states), then the 
	 * entry/exit actions of simple and composite states, and lastly, the transitions.
	 * This searching order is necessary because of how PlantUML works.
	 * If there are multiple regions in the state, it will separate them.
	 */
	protected def String regionSearch(StateNode state, StatechartDefinition statechart) {
		if (regionsDispatch(state) !== null) {
			val result = '''
				state «state.name» {
					«FOR region : regionsDispatch(state)»
						«FOR pseudo: region.stateNodes»
							«IF pseudo instanceof PseudoState»
								«pseudo.transformPseudoState»
							«ENDIF»
						«ENDFOR»
						«FOR inner: region.stateNodes»
							«regionSearch(inner, statechart)»
								«IF !(inner instanceof PseudoState)»
									«IF stateActionsSearch(inner) !== null»
										«stateActionsSearch(inner)»
									«ENDIF»
								«ENDIF»
						«ENDFOR»
						«FOR inner: region.stateNodes»
							«FOR itransition: statechart.transitions»
								«IF itransition.sourceState == inner»
									«stateSearch(itransition)»
								«ENDIF»
							«ENDFOR»
						«ENDFOR»
						«IF regionsDispatch(state).length > 1 && region !== regionsDispatch(state).last»
							--
						«ENDIF»
					«ENDFOR»
				}
				
			'''
			return result
		} else {
			val result = null
			return result
		}
	}

	/**
	 * stateActionsSearch(StateNode)
	 * 
	 * This method searches for the actions of non-pseudostates.
	 * If the state received as parameter has entry or exit actions, it gathers and
	 * returns them in the "result" variable.
	 * 
	 */
	protected def stateActionsSearch(StateNode statenode) {
		val state = statenode as State
		if (!(state.getEntryActions().empty) || !(state.getExitActions().empty)) {
			val result = '''
				«IF !(state.getEntryActions().empty)»
					«FOR entry: state.getEntryActions()»
						«val entryraise = entry as Statement»
						«statenode.name» : entry / «entryraise.transformActionReference»
					«ENDFOR»
				«ENDIF»
				«IF !(state.getExitActions().empty)»
					«FOR exit: state.getExitActions()»
						«val exitraise = exit as Statement»
						«statenode.name» : exit / «exitraise.transformActionReference»
					«ENDFOR»
				«ENDIF»
			'''
			return result
		} else {
			val result = null
			return result
		}
	}
	
	/**
	 * regionsDispatch(StateNode)
	 * 
	 * Contrary to the name, this is not a real dispatch method.
	 * It returns the regions of non-pseudostates, or null.
	 * 
	 */	
	protected def regionsDispatch(StateNode state) {
		if (!(state instanceof PseudoState)) {
			val statecomp = state as CompositeElement
			if (!(statecomp.getRegions().isEmpty())) {
				val region = statecomp.getRegions()
				return region
			} else {
				return null
			}
		}
	}
	
	/**
	 * mainRegionSearch(StatechartDefitnition)
	 * 
	 * This method has a similar functionality to the regionSearch() method, but this is for the uppermost,
	 * main region. The result of this method is the mainString variable, which contains the whole visualization.
	 * 
	 */
	protected def mainRegionSearch(StatechartDefinition statechart){
		val mainString = '''
			«FOR main : statechart.regions»
				«FOR pseudo: main.stateNodes»
					«IF pseudo instanceof PseudoState»
						«pseudo.transformPseudoState»
					«ENDIF»
				«ENDFOR»
			«ENDFOR»
			«FOR main : statechart.regions»
				«FOR mainstate: main.stateNodes.filter(State)»
					«regionSearch(mainstate, statechart)»
					«IF !(mainstate instanceof PseudoState)»
						«IF stateActionsSearch(mainstate) !== null»
							«stateActionsSearch(mainstate)»
						«ENDIF»
					«ENDIF»
				«ENDFOR»
			«ENDFOR»
			«FOR transition : statechart.transitions»
				«FOR main: statechart.regions»
					«FOR mainstate: main.stateNodes»
						«IF transition.sourceState == mainstate»
							«stateSearch(transition)»
						«ENDIF»
					«ENDFOR»
				«ENDFOR»
			«ENDFOR»
		'''
		return mainString
	}
	
	/**
	 * stateSearch(Transition)
	 * 
	 * This method searches the source and target state of the transition received as parameter.
	 * This is where the visualization of the initial and history states is handled, as well as
	 * the obtaining of the guards and triggers of transitions.
	 * The end result will look like this:
	 * 
	 * State1 -> State2 : trigger [guard] / action
	 * 
	 */
	protected def stateSearch(Transition transition) {
		val guard = transition.guard
		val transitions = '''
			«IF transition.sourceState instanceof PseudoState»
				«IF transition.sourceState instanceof EntryState»
					«IF transition.sourceState instanceof InitialState»
						[*] --> «transition.targetState.name»
					«ELSE»
						[H] --> «transition.targetState.name»
					«ENDIF»
				«ELSE»
					«transition.sourceState.name» --> «transition.targetState.name» : «IF transition.guard !== null»[«guard.serialize»]«ENDIF»«FOR effect : transition.effects BEFORE ' /\\n' SEPARATOR '\\n'»«effect.transformActionReference»«ENDFOR»
				«ENDIF»
			«ELSE»	
				«transition.sourceState.name» --> «transition.targetState.name» : «IF transition.trigger !== null»«transition.trigger.transformTrigger»«ENDIF» «IF transition.guard !== null»[«guard.serialize»]«ENDIF»«FOR effect : transition.effects BEFORE ' /\\n' SEPARATOR '\\n'»«effect.transformActionReference»«ENDFOR»
			«ENDIF»
		'''
		return transitions
	}
	
}
