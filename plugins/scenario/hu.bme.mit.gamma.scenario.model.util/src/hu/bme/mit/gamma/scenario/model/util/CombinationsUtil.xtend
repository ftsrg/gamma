package hu.bme.mit.gamma.scenario.model.util

import com.google.common.collect.Collections2
import hu.bme.mit.gamma.scenario.model.Interaction
import java.util.AbstractMap.SimpleEntry
import java.util.ArrayList
import java.util.Collection
import java.util.HashSet
import java.util.List
import java.util.Map.Entry
import java.util.Set

class CombinationsUtil {

	static def <T> Set<Entry<T, T>> pairwiseCombinations(Collection<T> elements) {
		return elements.fold(new HashSet<Entry<T, T>>, [ accumulator, actual |
			elements.tail.forEach [ other |
				val isNotPresentYet = accumulator.findFirst[it.key == other && it.value == actual] === null
				if(actual != other && isNotPresentYet) {
					accumulator.add(new SimpleEntry(actual, other))
				}
			]
			accumulator
		])
	}

	static def <T> List<Entry<Pair<Integer, T>, Pair<Integer, T>>> pairwiseCombinationsWithIndices(List<T> elements) {
		val elementsWithIndices = elements.indexed.toList
		return elementsWithIndices.fold(new ArrayList<Entry<Pair<Integer, T>, Pair<Integer, T>>>, [ accumulator, actual |
			elementsWithIndices.tail.forEach [ other |
				val isNotPresentYet = accumulator.findFirst[it.key.value == other && it.value.value == actual] === null
				if(actual != other && isNotPresentYet) {
					accumulator.add(new SimpleEntry(actual, other))
				}
			]
			accumulator
		])
	}

	static def <T extends List<Interaction>> Set<List<T>> permutationsListInteractions(List<T> elements) {
		elements.permutations
	}

	static def <T> permutations(List<T> elements) {
		Collections2::permutations(elements).toSet
	}

}
