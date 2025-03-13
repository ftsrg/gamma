/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.util.TypeSerializer
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference
import hu.bme.mit.gamma.statechart.statechart.CompositeElement
import hu.bme.mit.gamma.statechart.statechart.DeepHistoryState
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.ForkState
import hu.bme.mit.gamma.statechart.statechart.InitialState
import hu.bme.mit.gamma.statechart.statechart.JoinState
import hu.bme.mit.gamma.statechart.statechart.MergeState
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger
import hu.bme.mit.gamma.statechart.statechart.OpaqueTrigger
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.PseudoState
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.ShallowHistoryState
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.statechart.util.ActionSerializer
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import org.eclipse.emf.common.util.EList

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartToPlantUmlTransformer {

	protected final StatechartDefinition statechart

	protected extension ActionSerializer actionSerializer = ActionSerializer.INSTANCE
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE

	new(StatechartDefinition statechart) {
		this.statechart = statechart
	}

	def String execute() '''
		@startuml
		
		skin rose ««« !theme plain

		skinparam backgroundcolor transparent
		skinparam legend {
			BackgroundColor lightgrey
		}

		skinparam nodesep 30
		skinparam ranksep 30
		skinparam padding 5
			«statechart.listVariablesInNote»
			«statechart.mainRegionSearch»
		@enduml
	'''

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
		val leftOperand = binaryTrigger.leftOperand
		val rightOperand = binaryTrigger.rightOperand
		val type = binaryTrigger.type
		return '''(«leftOperand.transformTrigger» «type.transformOperator»\n«rightOperand.transformTrigger»)'''
	}

	protected def transformOperator(BinaryType type) {
		switch (type) {
			case AND: {
				return "&&"
			}
			case OR: {
				return "||"
			}
			case XOR: {
				return "^"
			}
			case IMPLY: {
				return "->"
			}
			case EQUAL: {
				return "=="
			}
			default: {
				throw new IllegalArgumentException("Not supported binary type: " + type)
			}
		}
	}

	protected def dispatch String transformTrigger(UnaryTrigger unaryTrigger) {
		val type = unaryTrigger.type
		val operand = unaryTrigger.operand
		return '''«type.transformOperator»(«operand.transformTrigger»)'''
	}

	protected def transformOperator(UnaryType type) {
		switch (type) {
			case NOT: {
				return "!"
			}
			default: {
				throw new IllegalArgumentException("Not supported unary type: " + type)
			}
		}
	}

///////////////////// EVENT REFERENCE DISPATCH /////////////////////	
	// Handling the different instances of event references
	protected def dispatch transformEventReference(PortEventReference portEventReference) {
		return portEventReference.port.name + "." + portEventReference.event.name
	}

	protected def dispatch transformEventReference(TimeoutEventReference timeoutEventReference) {
		return '''timeout «timeoutEventReference.timeout.name»'''
	}

	protected def dispatch transformEventReference(ClockTickReference clockTickReference) {
		val clock = clockTickReference.clock
		return clock.name + " : " + clock.timeSpecification.value + " " + clock.timeSpecification.unit
	}

	protected def dispatch transformEventReference(AnyPortEventReference anyPortEventReference) {
		return '''«anyPortEventReference.port.name».any'''
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
	protected def transformAction(Action action) {
		return action.serialize.replaceAll(System.lineSeparator, "\\\\n") // PlantUML needs \\n
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
								«FOR itransition: statechart.transitions»
									«IF itransition.sourceState == inner»
										«stateSearch(itransition)»
									«ENDIF»
								«ENDFOR»
						«ENDFOR»
						«FOR inner: region.stateNodes»
						«ENDFOR»
						«IF regionsDispatch(state).length > 1 && region !== regionsDispatch(state).lastOrNull»
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
		if (!(state.entryActions.empty) || !(state.exitActions.empty) || !(state.invariants.empty)) {
			val result = '''
				«IF !(state.invariants.empty)»
					«FOR invariant: state.invariants»
						«statenode.name» : invariant «invariant.serialize»
					«ENDFOR»
				«ENDIF»
				«IF !(state.entryActions.empty)»
					«FOR entry: state.entryActions»
						«statenode.name» : entry / «entry.transformAction»
					«ENDFOR»
				«ENDIF»
				«IF !(state.exitActions.empty)»
					«FOR exit: state.exitActions»
						«statenode.name» : exit / «exit.transformAction»
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
	protected def mainRegionSearch(StatechartDefinition statechart) {
		val mainString = '''
			«IF statechart.regions.size > 1»state «statechart.name» {«ENDIF»
				«FOR main : statechart.regions»
					«FOR pseudo: main.stateNodes»
						«IF pseudo instanceof PseudoState»
							«pseudo.transformPseudoState»
						«ENDIF»
					«ENDFOR»
					«FOR mainstate: main.stateNodes.filter(State)»
						«regionSearch(mainstate, statechart)»
						«IF !(mainstate instanceof PseudoState)»
							«IF stateActionsSearch(mainstate) !== null»
								«stateActionsSearch(mainstate)»
							«ENDIF»
						«ENDIF»
					«ENDFOR»
					«FOR transition : statechart.transitions»
						«FOR mainstate: main.stateNodes»
							«IF transition.sourceState == mainstate»
								«stateSearch(transition)»
							«ENDIF»
						«ENDFOR»
					«ENDFOR»
					
					«IF !(isLastRegion(statechart.regions, main))»
						--
					«ENDIF»
					
				«ENDFOR»
			«IF statechart.regions.size > 1»
				}
				[*] -> «statechart.name»
			«ENDIF»
		'''
		return mainString
	}

	protected def isLastRegion(EList<Region> regions, Region region) {
		val size = regions.size
		if (regions.contains(region)) {
			if (regions.indexOf(region) == size - 1) {
				return true
			} else {
				return false
			}
		} else {
			return false
		}
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
		val source = transition.sourceState
		val trigger = transition.trigger
		val guard = transition.guard
		val effects = transition.effects
		val target = transition.targetState
		var arrow = ""
		if (source instanceof EntryState || (source.parentRegion.orthogonal && target.state)) {
			arrow = "->"
		} else {
			arrow = "-->"
		}
		return '''
			«transition.sourceText» «arrow» «target.name»«IF !transition.empty» : «ENDIF»«IF trigger !== null»«trigger.transformTrigger»«ENDIF» «IF guard !== null»\n[«guard.serialize
				.replaceAll("\\|\\|", "||\\\\n").replaceAll("\\&\\&", "&&\\\\n")»]«ENDIF»«FOR effect : effects BEFORE ' /\\n' SEPARATOR '\\n'»«effect.transformAction»«ENDFOR»
		'''
	}

	protected def getSourceText(Transition transition) {
		val source = transition.sourceState
		switch (source) {
			InitialState: {
				return '''[*]'''
			}
			ShallowHistoryState: {
				return '''[H]'''
			}
			DeepHistoryState: {
				return '''[H]''' // PlantUML does not distinguish between the two history states
			}
			default: {
				return source.name
			}
		}
	}

	protected def listVariablesInNote(StatechartDefinition statechart) {
		val parameterDeclarations = statechart.parameterDeclarations
		val variableDeclarations = statechart.variableDeclarations
		val timeoutDeclarations = statechart.timeoutDeclarations
		val invariants = statechart.invariants
		
		if (variableDeclarations.empty && timeoutDeclarations.empty && parameterDeclarations.empty && invariants.empty) {
			return ''''''
		}
		return '''
			legend top
			 	«FOR parameter : parameterDeclarations»
			 		param «parameter.name»: «parameter.type.serialize»
				«ENDFOR»
				«FOR variable : variableDeclarations»
					var «variable.name»: «variable.type.serialize»«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»
				«ENDFOR»
				«FOR timeout : timeoutDeclarations»
					timeout «timeout.name»
				«ENDFOR»
				«FOR invariant : invariants»
				    invariant «invariant.serialize»
				«ENDFOR»
			endlegend
		'''
	}

}
