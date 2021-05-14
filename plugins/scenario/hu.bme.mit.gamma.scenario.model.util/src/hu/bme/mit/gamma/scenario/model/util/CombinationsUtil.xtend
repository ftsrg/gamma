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
