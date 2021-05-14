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

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment
import hu.bme.mit.gamma.scenario.model.Chart
import hu.bme.mit.gamma.scenario.model.CombinedFragment
import hu.bme.mit.gamma.scenario.model.InteractionFragment
import hu.bme.mit.gamma.scenario.model.ModalInteraction
import hu.bme.mit.gamma.scenario.model.ParallelCombinedFragment
import hu.bme.mit.gamma.scenario.model.Reset
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition
import hu.bme.mit.gamma.scenario.model.Signal
import hu.bme.mit.gamma.scenario.model.UnorderedCombinedFragment
import java.util.Collection
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper
import hu.bme.mit.gamma.scenario.model.Delay

class StructuralValidator {

	static val EqualityHelper helper = new EqualityHelper

	static def boolean equalsTo(EObject objA, EObject objB) {
		if(objA instanceof ScenarioDeclaration && objB instanceof ScenarioDeclaration) {
			val scenariosA = (objA as ScenarioDeclaration).scenarios
			val scenariosB = (objB as ScenarioDeclaration).scenarios
			return scenariosA.equalsTo(scenariosB)
		} else if(objA instanceof ScenarioDefinition && objB instanceof ScenarioDefinition) {
			val scenarioA = objA as ScenarioDefinition
			val scenarioB = objB as ScenarioDefinition
			return scenarioA.chart.equalsTo(scenarioB.chart)
		} else if(objA instanceof Chart && objB instanceof Chart) {
			val chartA = objA as Chart
			val chartB = objB as Chart
			return chartA.fragment.equalsTo(chartB.fragment)
		} else if(objA instanceof UnorderedCombinedFragment && objB instanceof UnorderedCombinedFragment) {
			val cfA = (objA as CombinedFragment)
			val cfB = (objB as CombinedFragment)
			return cfA.equalsTo(cfB)
		} else if(objA instanceof ParallelCombinedFragment && objB instanceof ParallelCombinedFragment) {
			val cfA = (objA as CombinedFragment)
			val cfB = (objB as CombinedFragment)
			return cfA.equalsTo(cfB)
		} else if(objA instanceof AlternativeCombinedFragment && objB instanceof AlternativeCombinedFragment) {
			val cfA = (objA as CombinedFragment)
			val cfB = (objB as CombinedFragment)
			return cfA.equalsTo(cfB)
		} else if(objA instanceof Reset && objB instanceof Reset) {
			return true
		} else if(objA instanceof ModalInteraction && objB instanceof ModalInteraction) {
			val modalInteractionA = objA as ModalInteraction
			val modalInteractionB = objB as ModalInteraction
			val modalityIsTheSame = modalInteractionA.modality == modalInteractionB.modality
			return modalityIsTheSame && modalInteractionA.equalsTo(modalInteractionB)
		} else if(objA instanceof Signal && objB instanceof Signal) {
			val signalA = objA as Signal
			val signalB = objB as Signal
			val directionEquals = signalA.direction == signalB.direction
			val portIsTheSame = signalA.port.name == signalB.port.name
			val eventIsTheSame = signalA.event.name == signalB.event.name
			// Not checking arguments!
			return directionEquals && portIsTheSame && eventIsTheSame
		} else if(objA instanceof Delay && objB instanceof Delay) {
			val delayA = objA as Delay
			val delayB = objB as Delay
			return helper.equals(delayA.minimum, delayB.minimum) && helper.equals(delayA.maximum, delayB.maximum)
		} else if(objA instanceof InteractionFragment && objB instanceof InteractionFragment) {
			val interactionsA = (objA as InteractionFragment).interactions
			val interactionsB = (objB as InteractionFragment).interactions

			val objAeContainerCls = if(objA.eContainer === null) null else objA.eContainer.class
			val objBeContainerCls = if(objB.eContainer === null) null else objB.eContainer.class

			return interactionsA.equalsTo(interactionsB) && (objAeContainerCls == objBeContainerCls)
		} else if(objA !== null && objB !== null && objA.class == objB.class) {
			return helper.equals(objA, objB)
		} else {
			return false
		}
	}

	private static def equalsTo(CombinedFragment cfA, CombinedFragment cfB) {
		val fragmentsA = (cfA as CombinedFragment).fragments
		val fragmentsB = (cfB as CombinedFragment).fragments
		return fragmentsA.equalsTo(fragmentsB)
	}

	private static def <T extends EObject> boolean equalsTo(Collection<T> collA, Collection<T> collB) {
		if(collA.size == collB.size) {
			val collIteratorA = collA.iterator
			val collIteratorB = collB.iterator
			while(collIteratorA.hasNext) {
				val same = collIteratorA.next.equalsTo(collIteratorB.next)
				if(!same) {
					return false
				}
			}
			return true
		} else {
			return false
		}
	}
}
