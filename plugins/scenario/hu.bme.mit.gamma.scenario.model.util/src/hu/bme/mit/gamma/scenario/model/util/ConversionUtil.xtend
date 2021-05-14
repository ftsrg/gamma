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
package hu.bme.mit.gamma.scenario.model.util

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment
import hu.bme.mit.gamma.scenario.model.Delay
import hu.bme.mit.gamma.scenario.model.Interaction
import hu.bme.mit.gamma.scenario.model.InteractionDefinition
import hu.bme.mit.gamma.scenario.model.InteractionFragment
import hu.bme.mit.gamma.scenario.model.ModalInteraction
import hu.bme.mit.gamma.scenario.model.ParallelCombinedFragment
import hu.bme.mit.gamma.scenario.model.Reset
import hu.bme.mit.gamma.scenario.model.ScenarioModelFactory
import hu.bme.mit.gamma.scenario.model.Signal
import hu.bme.mit.gamma.scenario.model.UnorderedCombinedFragment
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.AbstractMap.SimpleEntry
import java.util.HashMap
import java.util.List
import java.util.Set

import static extension hu.bme.mit.gamma.scenario.model.util.CombinationsUtil.permutations
import static extension hu.bme.mit.gamma.scenario.model.util.CombinationsUtil.permutationsListInteractions

class ConversionUtil {
	
	protected final static extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE

	static def AlternativeCombinedFragment convertToAlternativeCombinedFragment(UnorderedCombinedFragment combined) {
		val interactions = combined.fragments.map[interactions].toList
		val permutations = interactions.permutationsListInteractions
		permutations.map[flatten.toList].toSet.createAlternativeCombinedFragment
	}

	static def AlternativeCombinedFragment convertToAlternativeCombinedFragment(ParallelCombinedFragment combined) {
		val fragments = combined.fragments

		val permutations = fragments.map[interactions].flatten.toList.permutations
		val originalSequenceWithIndices = fragments.map[interactions].indexed.toList

		val permutationsWithIndices = permutations.fold(
			newHashSet,
			[ accumulator, permutation |
				val permutationWithIndices = permutation.fold(newArrayList, [ acc, interaction |
					val fragmentIndex = originalSequenceWithIndices.findFirst[it.value.contains(interaction)].key
					acc.add(new SimpleEntry(fragmentIndex, interaction))
					acc
				])
				accumulator.add(permutationWithIndices)
				accumulator
			]
		)

		val interactionsAreInCorrectOrderInFragments = permutationsWithIndices.filter [ permutationWithIndices |
			val permutationsGrouppedByFragmentIndex = permutationWithIndices.fold(new HashMap<Integer, List<Interaction>>, [ accumulator, actual |
				val interaction = actual.value
				val fragmentIndex = actual.key

				val fragment = accumulator.get(fragmentIndex)
				if(fragment !== null) {
					fragment.add(interaction)
				} else {
					val interactions = newArrayList
					interactions.add(interaction)
					accumulator.put(fragmentIndex, interactions)
				}

				accumulator
			])

			// validate that for every fragment the contained interactions are in the same order as in the original fragment
			permutationsGrouppedByFragmentIndex.entrySet.forall [
				val fragmentIndex = it.key
				val originalSequenceIter = originalSequenceWithIndices.findFirst[it.key == fragmentIndex].value.iterator
				val interactionsIter = it.value.iterator

				var orderIsTheSame = true
				while(interactionsIter.hasNext && orderIsTheSame) {
					// the triple equation marks are on purpose, because we want to compare by reference and not by equals!
					if(interactionsIter.next !== originalSequenceIter.next) {
						orderIsTheSame = false
					}
				}
				orderIsTheSame
			]
		].map[map[value].toList].toSet

		interactionsAreInCorrectOrderInFragments.createAlternativeCombinedFragment
	}

	private static def AlternativeCombinedFragment createAlternativeCombinedFragment(Set<List<Interaction>> permutations) {
		val combinedFragment = ScenarioModelFactory.eINSTANCE.createAlternativeCombinedFragment
		permutations.forEach [
			val interactionFragment = ScenarioModelFactory.eINSTANCE.createInteractionFragment
			interactionFragment.interactions.addAll(copy)
			combinedFragment.fragments.add(interactionFragment)
		]
		combinedFragment
	}

	private static def List<Interaction> copy(List<Interaction> interactions) {
		interactions.fold(newArrayList, [ accumulator, actual |
			accumulator.add(actual.copy)
			accumulator
		]).toList
	}

	private static def Interaction copy(Interaction interaction) {
		switch (interaction) {
			Reset: {
				ScenarioModelFactory.eINSTANCE.createReset
			}
			Delay: {
				ScenarioModelFactory.eINSTANCE.createDelay => [
					it.minimum = interaction.minimum.clone(true, true)
					it.maximum = interaction.maximum.clone(true, true)
				]
			}
			Signal: {
				val copied = ScenarioModelFactory.eINSTANCE.createSignal
				copied.direction = interaction.direction
				copied.event = interaction.event
				copied.port = interaction.port
				copied.arguments += interaction.arguments.map[it.clone(true, true)]
				copied
			}
//			ModalInteraction: {
//				val copied = ScenarioModelFactory.eINSTANCE.createModalInteraction
//				copied.modality = interaction.modality
//				copied.interaction = interaction.interaction.copy as InteractionDefinition
//				copied
//			}
			AlternativeCombinedFragment: {
				val copied = ScenarioModelFactory.eINSTANCE.createAlternativeCombinedFragment
				interaction.fragments.forEach[copied.fragments.add(copyFragment)]
				copied
			}
			UnorderedCombinedFragment: {
				val copied = ScenarioModelFactory.eINSTANCE.createUnorderedCombinedFragment
				interaction.fragments.forEach[copied.fragments.add(copyFragment)]
				copied
			}
		}
	}

	private static def InteractionFragment copyFragment(InteractionFragment fragment) {
		val copied = ScenarioModelFactory.eINSTANCE.createInteractionFragment
		fragment.interactions.forEach[copied.interactions.add(copy)]
		copied
	}

}
