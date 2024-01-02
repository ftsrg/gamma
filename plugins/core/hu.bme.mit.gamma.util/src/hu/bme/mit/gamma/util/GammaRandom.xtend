/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.util

import java.util.Map
import java.util.Random
import org.eclipse.emf.ecore.EObject

class GammaRandom {
	// Singleton
	public static final GammaRandom INSTANCE = new GammaRandom
	protected new() {}
	//
	protected final Random random = new Random()
	//
	
	def <T extends EObject> select(Map<T, Integer> frequency) {
		
	}
	
	def <T extends EObject> selectElement(Map<T, Double> probabilities) {
		val randomValue = Math.random
		var sumProbability = 0.0
		
		for (pair : probabilities.entrySet) {
			val element = pair.key
			val probability = pair.value
			
			if (sumProbability <= randomValue && randomValue < probability) {
				return element
			}
			else {
				sumProbability += probability
			}
		}
		throw new IllegalArgumentException("Could not select element randomly")
	}
	
}