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
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	//
	
	def <T extends EObject> selectBasedOnInvertedFrequency(Map<T, Integer> frequencies) {
		val probabilities = newHashMap
		
		val EPSILON = 0.0001 // To counter 0 values
		for (element : frequencies.keySet) {
			val frequency = frequencies.get(element)
			val invertedFrequency = 1 / (frequency + EPSILON)
			
			probabilities += element -> invertedFrequency
		}
		
		return probabilities.selectBasedOnDoubleFrequency
	}
	
	def <T extends EObject> selectBasedOnFrequency(Map<T, Integer> frequencies) {
		val doubleFrequencies = frequencies.castValues(Double)
		return doubleFrequencies.selectBasedOnDoubleFrequency
	}
	
	def <T extends EObject> selectBasedOnDoubleFrequency(Map<T, Double> frequencies) {
		val probabilities = newHashMap
		val sum = frequencies.values.reduce[a, b | a + b]
		
		for (element : frequencies.keySet) {
			val frequency = frequencies.get(element) 
			val probability = frequency / sum
			
			probabilities += element -> probability
		}
		
		return probabilities.selectBasedOnProbability
	}
	
	def <T extends EObject> selectBasedOnProbability(Map<T, Double> probabilities) {
		val randomValue = Math.random
		var sumProbability = 0.0 // Must sum up to 1.0
		
		for (pair : probabilities.entrySet) {
			val element = pair.key
			val probability = pair.value
			val adjustedProbability = sumProbability + probability
			
			if (sumProbability <= randomValue && randomValue < adjustedProbability) {
				return element
			}
			else {
				sumProbability += probability
			}
		}
		throw new IllegalArgumentException("Could not select element randomly")
	}
	
}