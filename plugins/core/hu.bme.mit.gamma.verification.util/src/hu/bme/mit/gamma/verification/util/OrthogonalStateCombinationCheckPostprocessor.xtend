/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.Collection
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class OrthogonalStateCombinationCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final Component originalTopComponent
	//
	protected final List<Collection<? extends ComponentInstanceStateReferenceExpression>> stateCombinations = newArrayList
	//
	
	new(Component originalTopComponent) {
		this.originalTopComponent = originalTopComponent
	}
	
	override execute(Result result) {
		val res = result.result
		
		if (res == ThreeStateBoolean.TRUE) {
			// Knowing the structure of the property
			val property = result.property
			val states = property.selectStates
			
			val originalStates = states.map[it.getOriginal(originalTopComponent)]
			
			stateCombinations += originalStates
		}
		
		return stateCombinations
	}
	
	override execute(ExecutionTrace trace) {
		return null // Nothing to process at this point
	}
	
	//
	
	def getCoveredOrthogonalStateCombinations() {
		return stateCombinations
	}
	
	protected def calculateAllOrthogonalStateCombinations(StatechartDefinition statechart) {
		return statechart.allOrthogonalStateCombinations
	}
	
	def getUncoveredOrthogonalStateCombinations() {
		val uncoveredOrthogonalStateCombinations = <List<? extends ComponentInstanceStateReferenceExpression>>newArrayList
		val coveredOrthogonalStateCombinations = this.coveredOrthogonalStateCombinations
		
		val instances = originalTopComponent.allSimpleInstanceReferences
		for (instance : instances) {
			val lastInstance = instance.lastInstance
			val statechart = lastInstance.derivedType as StatechartDefinition
			val orthogonalStateCombinations = statechart.calculateAllOrthogonalStateCombinations
			for (orthogonalStateCombination : orthogonalStateCombinations) {
				val newInstances = orthogonalStateCombination.map[instance.clone.createStateReference(it)].toList
				val ids = newInstances.map[it.id]
				
				if (!coveredOrthogonalStateCombinations.exists[
						it.forall[ids.contains(it.id)]]) {
					uncoveredOrthogonalStateCombinations += newInstances
				}
			}
		}
		
		return uncoveredOrthogonalStateCombinations
	}
	
}