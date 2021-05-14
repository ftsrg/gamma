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
import hu.bme.mit.gamma.scenario.model.CombinedFragment
import hu.bme.mit.gamma.scenario.model.InteractionDefinition
import hu.bme.mit.gamma.scenario.model.InteractionFragment
import hu.bme.mit.gamma.scenario.model.ModalInteraction
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition
import hu.bme.mit.gamma.scenario.model.UnorderedCombinedFragment
import java.util.Iterator
import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.EcoreUtil2

import static extension hu.bme.mit.gamma.scenario.model.util.ConversionUtil.convertToAlternativeCombinedFragment
import static extension hu.bme.mit.gamma.scenario.util.StructuralValidator.equalsTo
import hu.bme.mit.gamma.scenario.model.Chart

class ScenarioBackannotationUtil {

	static val DEFAULT_LATEST_TRACE_INDEX = -1

	@Data
	static class ErroneousInteractionContext {
		val InteractionFragment container
		val int index
		val List<InteractionDefinition> remainingTrace
	}

	static def ErroneousInteractionContext findErroneousInteractionIndex(ScenarioDefinition scenario, List<InteractionDefinition> trace) {
		val fragments = newArrayList
		fragments.addAll(scenario.chart.fragment)
//		fragments.addAll(scenario.mainchart.fragment)

		var latestTrace = trace

		for (fragment : fragments) {
			val result = findErroneousInteractionIndex(fragment, latestTrace, fragment)
			if(result !== null && result.container !== null) {
				return result
			} else {
				latestTrace = result.remainingTrace
			}
		}
	}

	static def ErroneousInteractionContext findErroneousInteractionIndex(InteractionFragment fragment, List<InteractionDefinition> trace, InteractionFragment alternativeFragment) {
		val interactions = fragment.interactions
		val interactionsIter = interactions.iterator.indexed
		val traceIter = trace.iterator.indexed

		var latestTraceIndex = DEFAULT_LATEST_TRACE_INDEX

		while(interactionsIter.hasNext && traceIter.hasNext) {
			val interactionsIterCtx = interactionsIter.next
			val traceIterCtx = traceIter.next

			val latestInteraction = interactionsIterCtx.value
			val latestInteractionIndex = interactionsIterCtx.key
			val latestTraceElement = traceIterCtx.value
			latestTraceIndex = traceIterCtx.key

			switch (latestInteraction) {
				ModalInteraction: {
					val interaction = latestInteraction
					if(!interaction.equalsTo(latestTraceElement)) {
						val container = if(fragment.eResource === null) alternativeFragment else fragment
						return new ErroneousInteractionContext(container, latestInteractionIndex, trace.subList(latestTraceIndex, trace.size))
					} 
				}
				UnorderedCombinedFragment: {
					val alternativeFragments = latestInteraction.convertToAlternativeCombinedFragment
					val result = traverseAlternativeCombinedFragment(alternativeFragments, latestTraceIndex, traceIter, trace, latestInteraction)
					if(result !== null) {
						return result
					}
				}
				AlternativeCombinedFragment: {
					val result = traverseAlternativeCombinedFragment(latestInteraction, latestTraceIndex, traceIter, trace, latestInteraction)
					if(result !== null) {
						return result
					}
				}
				default:
					throw new IllegalArgumentException("Not known interaction type: " + latestInteraction)
			}
		}

		return new ErroneousInteractionContext(null, DEFAULT_LATEST_TRACE_INDEX, trace.subList(latestTraceIndex, trace.size))
	}

	private static def traverseAlternativeCombinedFragment(AlternativeCombinedFragment combined, int latestTraceIndex, Iterator<Pair<Integer, InteractionDefinition>> traceIter, List<InteractionDefinition> trace, CombinedFragment alternativeContainer) {
		// last argument is used only for traceability purposes (to track the error trace back into the editor correctly) to get who was the latest container
		// in case of a generated fragment, it has to be substituted by a 'valid' element that is contained in a resource
		var ErroneousInteractionContext tempResult = null
		for (latestFragment : combined.fragments) {
			val isNotPrechart = EcoreUtil2::getAllContainers(alternativeContainer).filter(Chart).nullOrEmpty
			val alternativeFragment = if(latestFragment.eResource === null) alternativeContainer.fragments.getMatchingFragment(latestFragment) else latestFragment
			val result = findErroneousInteractionIndex(latestFragment, trace.subList(latestTraceIndex, trace.size), alternativeFragment)
			if(result.container !== null) {
				tempResult = result
			} else if(result.index != DEFAULT_LATEST_TRACE_INDEX && isNotPrechart) {
				// workaround if the container is null, but the error trace index is not null, then substitute the parent with the last fragment, and set the index to 0
				tempResult = new ErroneousInteractionContext(alternativeContainer.fragments.last, 0, result.remainingTrace)
			} else {
				// if we found a fragment which accepts the trace part, then go on with it and return null (which means we did not find any conflict)
				return null
			}
		}
		return tempResult
	}
	
	private static def getMatchingFragment(List<InteractionFragment> here, InteractionFragment lookingFor) {
		here.findFirst[equalsTo(lookingFor)]
	}
}
