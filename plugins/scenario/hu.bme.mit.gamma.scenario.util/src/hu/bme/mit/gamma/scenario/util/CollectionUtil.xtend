/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.util

import hu.bme.mit.gamma.scenario.model.Interaction
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Set
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.scenario.util.StructuralValidator.equalsTo

class CollectionUtil {

	static def <K extends EObject, V extends EObject> filterSameEntries(Set<Entry<K, V>> toBeFiltered) {
		toBeFiltered.filter[key.equalsTo(value)]
	}

//	static def myFilter(List<Transition> transitions, Transition transition) {
//		transitions.filter[it.trigger.equalsTo(transition.trigger)]
//	}
//
//	static def myFilterByTrigger(List<Transition> transitions, InteractionDefinition trigger) {
//		transitions.filter[it.trigger.equalsTo(trigger)]
//	}
//
//	static def Map<InteractionDefinition, Set<Set<State>>> groupByKey2(Set<? extends Entry<InteractionDefinition, Set<State>>> toBeGrouppedBy) {
//		return toBeGrouppedBy.fold(newHashMap, [ accumulator, entry |
//			val interaction = entry.key
//			if(!accumulator.contains(interaction)) {
//				val states = toBeGrouppedBy.filter[it.key.equalsTo(interaction)].map[it.value].toSet
//				accumulator.put(interaction, states)
//			}
//			accumulator
//		])
//	}
//
//	static def Map<InteractionDefinition, Set<? extends State>> groupByKey(Set<? extends Entry<InteractionDefinition, Set<? extends State>>> toBeGrouppedBy) {
//		return toBeGrouppedBy.fold(newHashMap, [ accumulator, entry |
//			val interaction = entry.key
//			if(!accumulator.contains(interaction)) {
//				val states = toBeGrouppedBy.filter[it.key.equalsTo(interaction)].map[it.value].flatten.toSet
//				accumulator.put(interaction, states)
//			}
//			accumulator
//		])
//	}

	static def <K extends EObject, V extends Collection<?>> myRemove(Map<K, V> map, K key) {
		val toBeRemoved = map.findEntry(key)?.key
		if(toBeRemoved !== null) {
			map.remove(toBeRemoved)
		}
	}

	static def <K extends EObject, V extends Collection<?>> myGet(Map<K, V> map, K key) {
		map.findEntry(key)?.value
	}

//	static def <K extends Entry<InteractionDefinition, Set<? extends State>>, V extends Set<State>> myGet2(Map<K, V> map, K key) {
//		map.entrySet.findFirst[it.key.key.equalsTo(key.key) && it.key.value.equals(key.value)]?.value
//	}

	static def <K extends List<Interaction>, V extends Set<Integer>> myGetListInteraction(Map<K, V> map, K key) {
		map.entrySet.findFirst [
			val entryKeyIterator = it.key.iterator
			val keyIterator = key.iterator

			var equalsTo = true
			while(entryKeyIterator.hasNext && keyIterator.hasNext && equalsTo) {
				equalsTo = entryKeyIterator.next.equalsTo(keyIterator.next)
			}

			equalsTo
		]?.value
	}

//	static def <K extends List<Interaction>, V extends List<State>> myGetListInteraction2(Map<K, V> map, K key) {
//		map.entrySet.findFirst [
//			val entryKeyIterator = it.key.iterator
//			val keyIterator = key.iterator
//
//			var equalsTo = true
//			while(entryKeyIterator.hasNext && keyIterator.hasNext && equalsTo) {
//				equalsTo = entryKeyIterator.next.equalsTo(keyIterator.next)
//			}
//
//			equalsTo
//		]?.value
//	}

	private static def <K extends EObject, V extends Collection<?>> boolean contains(Map<K, V> map, K key) {
		map.findEntry(key) !== null
	}

	private static def <K extends EObject, V extends Collection<?>> findEntry(Map<K, V> map, K key) {
		/**
		 * WARNING: As for the time being, it is a workaround of a problem, not being able to compare 
		 * two ScenarioDeclarations which would be the same by 
		 * hu.bme.mit.gamma.scenario.util.StructuralValidator.equalsTo.
		 * 
		 * This special use case is used by hu.bme.mit.gamma.scenario.validation.ScenarioLanguageValidator
		 * to show warning markers for every ScenarioDefinition in
		 * ScenarioLanguageValidator.checkCustomMarkers method.
		 */
		if(key instanceof ScenarioDeclaration && map.keySet.filter(ScenarioDeclaration).size === 1) {
			return map.entrySet.findFirst[it.key instanceof ScenarioDeclaration]
		}

		map.entrySet.findFirst[it.key.equalsTo(key)]
	}
}
