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

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.util.Triple
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.regex.Pattern
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class DataflowCheckPostprocessor extends VerificationPostprocessor {
	//
	public static final String metadataBeginning = "Variable "
	public static final String metadataUsedBy = "used by"
	public static final String metadataDefBy = "as last defined by"
	public static final String OF = "of"
	//
	protected final List<Collection<? extends
			Entry<ComponentInstanceReferenceExpression, Triple<Declaration, EObject, EObject>>>> defUses = newArrayList
	//
	
	override execute(ExecutionTrace trace) {
		trace.saveTrace
		
		val defUses = <Entry<ComponentInstanceReferenceExpression, Triple<Declaration, EObject, EObject>>>newArrayList
		
		val steps = trace.allSteps
		for (step : steps) {
			val asserts = step.asserts
			for (assertion : asserts.filter(OpaqueExpression)
						.filter[it.expression.startsWith(metadataBeginning)]) {
				val instanceTransition = trace.parseDefUse(assertion)
				val instance = instanceTransition.key
				val transition = instanceTransition.value
				
			}
		}
		
		return defUses
	}
	
	def parseDefUse(ExecutionTrace trace, OpaqueExpression expression) {
		val string = expression.expression
		val pattern = Pattern.compile('''«metadataBeginning»(.*) «metadataUsedBy» (.*) «OF» (.*) «
					metadataDefBy» (.*) «OF» (.*)''')
		val matcher = pattern.matcher(string)
		if (!matcher.find) {
			throw new IllegalArgumentException("Not found pattern: " + string)
		}
		
		val instances = trace.steps.map[it.asserts].flatten
				.filter(ComponentInstanceElementReferenceExpression)
				.map[it.instance]
		
		val variableName = matcher.group(1).trim
		val useStateOrTransitionName = matcher.group(2).trim
		val instanceName = matcher.group(3).trim
		val defStateOrTransitionName = matcher.group(4).trim
		
		val instance = instances.findFirst[it.name == instanceName].clone
		val statechart = instance.lastInstance.getStatechart
		val variable = statechart.variableDeclarations.findFirst[it.name == variableName]
		val useStateOrTransition = useStateOrTransitionName.getStateOrTransition(instance)
		val defStateOrTransition = defStateOrTransitionName.getStateOrTransition(instance)
		
		return Map.entry(instance,
			new Triple(variable, useStateOrTransition, defStateOrTransition))
	}
	
	//
	
	def getId(Entry<ComponentInstanceReferenceExpression, Triple<Declaration, EObject, EObject>> transitionInstance) {
		val instance = transitionInstance.key
		val value = transitionInstance.value
		return instance.name + "." + value.toString
	}
	
	//
	
	def getCoveredDefUses() {
		return defUses
	}
	
	def getAllCoveredDefUses() {
		return defUses.flatten
	}
	
	def getUncoveredDefUses() {
		val uncoveredDefUses = newLinkedHashSet
		
		val coveredDefUseIds = allCoveredDefUses.map[it.id].toSet
		
		val instances = super.statechartInstanceReferences
		for (instance : instances) {
			val statechartInstance = instance.lastInstance
			val statechart = statechartInstance.getStatechart
			val transitions = statechart.transitions
			for (transition : transitions) {
				val transitionReference = instance.clone
						.createTransitionReference(transition)
				if (!coveredDefUseIds.contains(null /* TODO */)) {
					uncoveredDefUses += transitionReference
				}
			}
		}
		
		return uncoveredDefUses
	}
	
}