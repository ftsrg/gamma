package hu.bme.mit.gamma.scenario.model.util

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment
import hu.bme.mit.gamma.scenario.model.CombinedFragment
import hu.bme.mit.gamma.scenario.model.Interaction
import hu.bme.mit.gamma.scenario.model.InteractionFragment
import hu.bme.mit.gamma.scenario.model.ModalInteraction
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioModelPackage
import java.util.AbstractMap.SimpleEntry
import java.util.List
import java.util.Map
import java.util.Set

import static extension hu.bme.mit.gamma.scenario.model.util.CombinationsUtil.pairwiseCombinations
import static extension hu.bme.mit.gamma.scenario.model.util.CombinationsUtil.pairwiseCombinationsWithIndices
import static extension hu.bme.mit.gamma.scenario.util.CollectionUtil.filterSameEntries
import static extension hu.bme.mit.gamma.scenario.util.CollectionUtil.myGetListInteraction
import static extension hu.bme.mit.gamma.scenario.util.StructuralValidator.equalsTo

class ScenarioExtraValidator {

	static def boolean isValid(ScenarioDeclaration scenarioDeclaration) {
		scenarioDeclaration.doesNotContainRedundantScenarios && scenarioDeclaration.combinedFragmentsDoNotContainRedundantFragments && scenarioDeclaration.everyPairwiseContinuationHaveTheSameModality
	}

	private static def boolean combinedFragmentsDoNotContainRedundantFragments(ScenarioDeclaration scenarioDeclaration) {
		scenarioDeclaration.eAllContents.filter(CombinedFragment).forall[doestNotContainRedundantFragments]
	}

	private static def boolean everyPairwiseContinuationHaveTheSameModality(ScenarioDeclaration scenarioDeclaration) {
		scenarioDeclaration.eAllContents.filter(AlternativeCombinedFragment).forall[everyPairwiseContinuationHaveTheSameModality]
	}

	private static def boolean doestNotContainRedundantFragments(CombinedFragment combinedFragment) {
		val fragments = combinedFragment.fragments
		val redundantFragments = fragments.pairwiseCombinations.filterSameEntries.map [
			val indexOfA = fragments.indexOf(it.key);
			val indexOfB = fragments.indexOf(it.value);
			new SimpleEntry(indexOfA, indexOfB)
		]
		redundantFragments.forEach [
			val firstIndex = it.key
			val secondIndex = it.value

			ValidationMarkerUtil::addWarningMarker('''Interaction fragment is the same as #�secondIndex + 1� element.''', combinedFragment, ScenarioModelPackage.Literals.COMBINED_FRAGMENT__FRAGMENTS, firstIndex)
			ValidationMarkerUtil::addWarningMarker('''Interaction fragment is the same as #�firstIndex + 1� element.''', combinedFragment, ScenarioModelPackage.Literals.COMBINED_FRAGMENT__FRAGMENTS, secondIndex)
		]
		redundantFragments.nullOrEmpty
	}

	private static def boolean doesNotContainRedundantScenarios(ScenarioDeclaration scenarioDeclaration) {
		val redundantScenarios = scenarioDeclaration.scenarios.pairwiseCombinations.filterSameEntries.map[new SimpleEntry(it.key.name, it.value.name)]
		redundantScenarios.forEach [ scenarioNames |
			val oneScenarioName = scenarioNames.key
			val otherScenarioName = scenarioNames.value

			val firstIndex = scenarioDeclaration.scenarios.indexOf(scenarioDeclaration.scenarios.findFirst[it.name == oneScenarioName])
			val secondIndex = scenarioDeclaration.scenarios.indexOf(scenarioDeclaration.scenarios.findFirst[it.name == otherScenarioName])
			ValidationMarkerUtil::addWarningMarker('''Scenario definition is the same as �otherScenarioName�.''', scenarioDeclaration, ScenarioModelPackage.Literals.SCENARIO_DECLARATION__SCENARIOS, firstIndex)
			ValidationMarkerUtil::addWarningMarker('''Scenario definition is the same as �oneScenarioName�.''', scenarioDeclaration, ScenarioModelPackage.Literals.SCENARIO_DECLARATION__SCENARIOS, secondIndex)
		]
		redundantScenarios.nullOrEmpty
	}

	private static def boolean everyPairwiseContinuationHaveTheSameModality(AlternativeCombinedFragment combinedFragment) {
		val indexedInteractionFragments = combinedFragment.fragments.indexed.toMap([it.key], [it.value])
		val longestCommonPrefixes = combinedFragment.fragments.findLongestCommonPrefixSeries
		return if(!longestCommonPrefixes.isEmpty) {
			val notCorrect = longestCommonPrefixes.entrySet.findFirst [
				val longestCommonPathLength = it.key.length
				val fragmentIndices = it.value

				val shortenedInteractionFragments = newHashMap
				fragmentIndices.forEach [
					val interactions = indexedInteractionFragments.get(it).interactions
					shortenedInteractionFragments.put(it, interactions.subList(longestCommonPathLength, interactions.size))
				]

				val firstModalInteractions = newHashSet
				fragmentIndices.collectFirstModalInteractionsInShortenedFragments(shortenedInteractionFragments, firstModalInteractions)
				!firstModalInteractions.forall[it.modality == firstModalInteractions.head.modality]
			]

			if(notCorrect !== null) {
				notCorrect.value.forEach [
					ValidationMarkerUtil::addWarningMarker('''For those interaction fragments which have a common prefix, the next interaction after the common prefix must have the same modality.''', combinedFragment, ScenarioModelPackage.Literals.COMBINED_FRAGMENT__FRAGMENTS, it)
				]
			}

			notCorrect === null
		} else {
			true
		}
	}

	static def findLongestCommonPrefixSeries(List<InteractionFragment> interactionFragments) {
		val pairwiseLongestCommonSeries = interactionFragments.pairwiseCombinationsWithIndices.fold(newHashMap, [ accumulator, actual |
			val fragmentOne = actual.key
			val fragmentTwo = actual.value

			val fragmentOneIter = fragmentOne.value.interactions.iterator
			val fragmentTwoIter = fragmentTwo.value.interactions.iterator

			var isTheSame = true
			var longestMatch = newArrayList

			while(fragmentOneIter.hasNext && fragmentTwoIter.hasNext && isTheSame) {
				val nextInteractionOne = fragmentOneIter.next
				val nextInteractionTwo = fragmentTwoIter.next
				if(nextInteractionOne.equalsTo(nextInteractionTwo)) {
					isTheSame = true
					longestMatch.add(nextInteractionOne)
				} else {
					isTheSame = false
				}
			}

			accumulator.put(new SimpleEntry(fragmentOne.key, fragmentTwo.key), longestMatch)
			accumulator
		])

		val hasCommonSeries = pairwiseLongestCommonSeries.filter[_key, longestMatch|longestMatch.size > 0]

		val grouppedByCommonPrefixes = hasCommonSeries.entrySet.fold(newHashMap, [ accumulator, actual |
			val commonPrefix = actual.value
			val indicesWithThisCommonPrefix = accumulator.myGetListInteraction(commonPrefix)
			if(indicesWithThisCommonPrefix !== null) {
				indicesWithThisCommonPrefix.add(actual.key.key)
				indicesWithThisCommonPrefix.add(actual.key.value)
			} else {
				val indices = newHashSet
				indices.add(actual.key.key)
				indices.add(actual.key.value)
				accumulator.put(commonPrefix, indices)
			}
			accumulator
		])

		grouppedByCommonPrefixes
	}

	static def void collectFirstModalInteractions(Interaction interaction, Set<ModalInteraction> modalInteractions) {
		switch (interaction) {
			ModalInteraction: modalInteractions.add(interaction)
			CombinedFragment: interaction.fragments.forEach[it.interactions.head.collectFirstModalInteractions(modalInteractions)]
			default: {
				// No operation
			}
		}
	}

	static def void collectFirstModalInteractionsInShortenedFragments(Set<Integer> fragmentIndices, Map<Integer, List<Interaction>> shortenedInteractionFragments, Set<ModalInteraction> firstModalInteractions) {
		fragmentIndices.forEach [
			val interactions = shortenedInteractionFragments.get(it)
			if(!interactions.isEmpty) {
				interactions.head.collectFirstModalInteractions(firstModalInteractions)
			}
		]
	}

}
