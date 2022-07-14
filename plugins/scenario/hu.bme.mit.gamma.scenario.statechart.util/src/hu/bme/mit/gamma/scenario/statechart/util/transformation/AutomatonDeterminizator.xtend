/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.statechart.util.transformation

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.statechart.contract.ContractModelFactory
import hu.bme.mit.gamma.statechart.contract.SpecialStateKind
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.Set

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class AutomatonDeterminizator {

	protected val extension StatechartModelFactory statechartfactory = StatechartModelFactory.eINSTANCE
	protected val extension ExpressionModelFactory expressionfactory = ExpressionModelFactory.eINSTANCE
	protected val extension InterfaceModelFactory interfacefactory = InterfaceModelFactory.eINSTANCE
	protected val extension ActionModelFactory actionfactory = ActionModelFactory.eINSTANCE
	protected val extension ContractModelFactory contractfactory = ContractModelFactory.eINSTANCE
	protected val extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected val extension ExpressionEvaluator exprEval = ExpressionEvaluator.INSTANCE
	protected val extension ExpressionUtil exprUtil = ExpressionUtil.INSTANCE
	protected val extension ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE
	protected val extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE

	var StatechartDefinition oldStatechart = null
	val newStateOldStates = <StateNode, Collection<StateNode>>newLinkedHashMap
	val statesCollectiveState = <Collection<StateNode>, StateNode>newLinkedHashMap
	val oldStateNewStates = <StateNode, Collection<StateNode>>newLinkedHashMap
	val oldNewStateMap = <StateNode, StateNode>newLinkedHashMap
	var Region firstRegion = null
	var Region oldFirstRegion = null
	var StatechartDefinition newStatechart = null
	var int stateCount = 0

	new(StatechartDefinition oldStatechart) {
		this.oldStatechart = oldStatechart
		this.oldFirstRegion = oldStatechart.regions.head
		this.newStatechart = oldStatechart.clone
		this.firstRegion = newStatechart.regions.head
		newStatechart.variableDeclarations.clear
		newStatechart.variableDeclarations += oldStatechart.variableDeclarations
	}

	def StatechartDefinition execute() {
		firstRegion.stateNodes.clear
		newStatechart.transitions.clear
		for (state : oldStatechart.regions.head.stateNodes) {
			val stateClone = state.clone
			oldStateNewStates += {
				state -> newLinkedList
			}
			newStateOldStates += {
				stateClone -> #[state]
			}
			oldNewStateMap += {
				state -> stateClone
			}
			firstRegion.stateNodes += stateClone
		}

		val oldFirstState = oldFirstRegion.stateNodes.head
		val oldSecondState = oldFirstRegion.stateNodes.get(1)
		val newFirstState = oldNewStateMap.get(oldFirstState)
		val newSecondState = oldNewStateMap.get(oldSecondState)
		val initialTransition = oldStatechart.transitions.findFirst [
			it.sourceState == oldFirstState && it.targetState == oldSecondState
		]
		firstRegion.stateNodes += newFirstState
		firstRegion.stateNodes += newSecondState
		newStatechart.transitions += initialTransition
		initialTransition.sourceState = newFirstState
		initialTransition.targetState = newSecondState
		oldStateNewStates.get(oldFirstState) += #[newFirstState]
		newStateOldStates += #{newFirstState -> #[oldFirstState]}
		oldStateNewStates.get(oldSecondState) += #[newSecondState]
		newStateOldStates += #{newSecondState -> #[oldSecondState]}
		for (var i = 1; i < firstRegion.stateNodes.size; i++) {
			val state = firstRegion.stateNodes.get(i)
			handleState(state)
		}

		// Reset references inside triggers
		for (port : newStatechart.ports) {
			val oldPort = oldStatechart.ports.findFirst[it.name == port.name]
			ecoreUtil.change(port, oldPort, newStatechart)
		}
		
		for (timeout : oldStatechart.timeoutDeclarations){
			val newTimeout = newStatechart.timeoutDeclarations.findFirst[it.name == timeout.name]
			ecoreUtil.change(newTimeout, timeout, newStatechart)
		}

		// remove unreachable nodes
		removeUnreachableNodes()

		// add annotations
		addAnnotationForAcceptingStates()

		return newStatechart
	}

	def addAnnotationForAcceptingStates() {
		val acceptingStates = firstRegion.states.filter[it.name.contains(accepting)]
		for (acceptingState : acceptingStates) {
			val annotation = createSpecialStateAnnotation
			annotation.kind = SpecialStateKind.ACCEPTING
			acceptingState.annotations += annotation
		}
	}

	def void removeUnreachableNodes() {
		val remove = <StateNode>newArrayList
		for (stateNode : firstRegion.stateNodes) {
			if (stateNode.incomingTransitions.isEmpty && stateNode.name != scenarioStatechartUtil.initial)
				remove += stateNode
		}
		newStatechart.transitions.removeAll(remove.flatMap[it.outgoingTransitions])
		firstRegion.stateNodes -= remove
		if (firstRegion.stateNodes
				.exists[it.incomingTransitions.isEmpty && it.name != scenarioStatechartUtil.initial]) {
			removeUnreachableNodes()
		}
	}

	def handleState(StateNode node) {
		val representedOldStates = newStateOldStates.get(node).toSet
		val outgoingTransitions = representedOldStates.flatMap[it.outgoingTransitions].toList
		val sets = findNonDeterministicSets(outgoingTransitions)
		for (set : sets) {
			val targetStates = set.map[it.targetState].toSet
			var StateNode state = null
			if (targetStates.size == 1) {
				state = oldNewStateMap.get(targetStates.head)
			} else {
				state = findCollectiveState(targetStates)
			}
			if (state === null) {
				state = creatCollectiveState(targetStates)
			}
			val newTransition = set.head.clone
			newTransition.sourceState = node
			newTransition.targetState = state
			newStatechart.transitions += newTransition
		}
		val allNondeterministicTransition = sets.flatten
		val deterministicTransitions = outgoingTransitions.filter[!allNondeterministicTransition.contains(it)]
		for (transition : deterministicTransitions) {
			val newTransition = transition.clone
			newTransition.sourceState = node
			newTransition.targetState = oldNewStateMap.get(transition.targetState)
			newStatechart.transitions += newTransition
		}
	}

	def StateNode creatCollectiveState(Collection<StateNode> nodes) {
		val newState = createState
		newState.name = nodes.map[it.name].join('__')
		firstRegion.stateNodes += newState
		statesCollectiveState.put(nodes, newState)
		newStateOldStates.put(newState, nodes)
		return newState
	}

	def StateNode findCollectiveState(Collection<StateNode> nodes) {
		for (key : statesCollectiveState.keySet) {
			if (areListsEqual(key, nodes)) {
				return statesCollectiveState.get(key)
			}
		}
		return null
	}

	def boolean areListsEqual(Collection<StateNode> list1, Collection<StateNode> list2) {
		if (list1.size != list2.size) {
			return false
		}
		for (element : list1) {
			if (!list2.contains(element)) {
				return false
			}
		}
		return true
	}

	def Set<Set<Transition>> findNonDeterministicSets(Collection<Transition> transitions) {
		val output = <Set<Transition>>newHashSet
		for (transitionI : transitions) {
			for (transitionJ : transitions) {
				if (transitionI != transitionJ && areTransitionsNonDeterministic(transitionI, transitionJ)) {
					var containingSet = findContainingSetForEither(output, transitionI, transitionJ)
					if (containingSet === null) {
						containingSet = newHashSet
						output += containingSet
					}
					containingSet += transitionI
					containingSet += transitionJ
				}
			}
		}
		return output
	}

	def Set<Transition> findContainingSetForEither(Set<Set<Transition>> sets, Transition a, Transition b) {
		for (set : sets) {
			if (set.contains(a) || set.contains(b)) {
				return set
			}
		}
		return null
	}

	def boolean areTransitionsNonDeterministic(Transition a, Transition b) {
		return ecoreUtil.helperEquals(a.trigger, b.trigger) && ecoreUtil.helperEquals(a.guard, b.guard)
	}

	def protected createNewState(String name) {
		var state = createState
		state.name = name
		return state
	}

	def protected createNewState() {
		return createNewState(scenarioStatechartUtil.stateName + String.valueOf(stateCount++))
	}
}
