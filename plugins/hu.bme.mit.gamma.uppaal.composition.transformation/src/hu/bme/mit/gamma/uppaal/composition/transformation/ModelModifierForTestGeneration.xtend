/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.EntryState
import hu.bme.mit.gamma.statechart.model.RaiseEventAction
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseInstanceEvents
import hu.bme.mit.gamma.uppaal.transformation.queries.Transitions
import java.util.Collection
import java.util.Map
import java.util.Set
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import uppaal.NTA
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.expressions.AssignmentExpression
import uppaal.templates.Edge
import uppaal.templates.TemplatesPackage

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class ModelModifierForTestGeneration {
	// Has to be set externally
	extension NtaBuilder ntaBuilder
	extension AssignmentExpressionCreator assignmentExpressionCreator
	NTA nta
	ViatraQueryEngine engine
	extension Trace trace
	// Packages
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	// Transition coverage
	protected boolean TRANSITION_COVERAGE
	protected final Set<SynchronousComponentInstance> transitionCoverableComponents = newHashSet
	protected final Set<Transition> coverableTransitions = newHashSet
	protected final Map<Transition, Integer> transitionAnnotations = newHashMap
	protected DataVariableDeclaration transitionIdVariable
	protected final int INITIAL_TRANSITION_ID = 1
	protected int transitionId = INITIAL_TRANSITION_ID
	// Interaction coverage
	protected boolean INTERACTION_COVERAGE
	protected final Set<SynchronousComponentInstance> interactionCoverableComponents = newHashSet
	protected final Map<SynchronousComponentInstance, DataVariableDeclaration> sendingVariables = newHashMap
	protected final Map<SynchronousComponentInstance, DataVariableDeclaration> receivingVariables = newHashMap
	// Map<outInstance, Map<RaiseEventAction, Pair<outEdgeId, Set<Pair<inEdgeId, ReceivingTransition>>>>>
	protected final Map<SynchronousComponentInstance, Map<RaiseEventAction, Pair<Integer, Set<Pair<Integer, Transition>>>>> interactionIds = newHashMap
	
	
	new(NtaBuilder ntaBuilder, AssignmentExpressionCreator assignmentExpressionCreator,
			ViatraQueryEngine engine, Trace trace) {
		this.ntaBuilder = ntaBuilder
		this.assignmentExpressionCreator = assignmentExpressionCreator
		this.nta = ntaBuilder.nta
		this.engine = engine
		this.trace = trace
	}
	
	/**
	 * Has to be called explicitly.
	 */
	def setComponentInstances(Collection<SynchronousComponentInstance> transitionCoverableComponents,
			Collection<SynchronousComponentInstance> interactionCoverableComponents) {
		if (!transitionCoverableComponents.empty) {
			this.TRANSITION_COVERAGE = true
			this.transitionCoverableComponents += transitionCoverableComponents
			this.coverableTransitions += transitionCoverableComponents
				.map[it.type].filter(StatechartDefinition)
				.map[it.transitions].flatten
		}
		if (!interactionCoverableComponents.empty) {
			this.INTERACTION_COVERAGE = true
			this.interactionCoverableComponents += interactionCoverableComponents
		}
	}
	
	def getEngine() {
		return this.engine
	}
	
	def getNta() {
		return this.nta
	}
	
	def getTransitionIdVariable() {
		this.transitionIdVariable
	}
	
	// Transition coverage
	
	private def needsAnnotation(Transition transition) {
		return !(transition.sourceState instanceof EntryState) &&
			(transition.targetState instanceof State) &&
			coverableTransitions.contains(transition)
	}
	
	private def getNextAnnotationValue(Transition transition) {
		checkState(!transitionAnnotations.containsKey(transition))
		transitionAnnotations.put(transition, transitionId)
		return transitionId++
	}
	
	private def modifyModelForTransitionCoverage() {
		if (!TRANSITION_COVERAGE) {
			return
		}
		// Creating a global variable in UPPAAL for transition ids
		this.transitionIdVariable = this.nta.globalDeclarations.createVariable(DataVariablePrefix.NONE,
			nta.int, transitionIdVariableName)
		// Annotating the transitions
		for (transition : Transitions.Matcher.on(engine).allValuesOftransition
				.filter[it.needsAnnotation]) {
			val edges = transition.allValuesOfTo.filter(Edge)
			checkState(edges.size == 1)
			val edge = edges.head
			edge.createAssignmentExpression(edge_Update, transitionIdVariable,
				transition.getNextAnnotationValue.toString)
		}
	}
	
	def getTransitionAnnotations() {
		return this.transitionAnnotations
	}
	
	// Interaction coverage
	
	private def getSendingId(SynchronousComponentInstance outInstance, RaiseEventAction action) {
		val actionMap = interactionIds.get(outInstance) // This initialization is expected
		if (actionMap.empty) {
			val initialValue = 0
			actionMap.put(action, new Pair<Integer, Set<Pair<Integer, Transition>>>(initialValue, newHashSet))
			return initialValue
		}
		else if (actionMap.containsKey(action)) {
			return actionMap.get(action).key
		}
		else {
			// It has to be inserted, but the map is not empty (nextValue can be computed)
			val nextValue = actionMap.values.map[it.key].max + 1
			actionMap.put(action, new Pair<Integer, Set<Pair<Integer, Transition>>>(nextValue, newHashSet))
			return nextValue
		}
	}
	
	private def setSendingId(SynchronousComponentInstance outInstance, RaiseEventAction action, int value) {
		val actionMap = interactionIds.get(outInstance) // This initialization is expected
		if (actionMap.containsKey(action)) {
			checkState(actionMap.get(action).key == value)
			return 
		}
		actionMap.put(action, new Pair<Integer, Set<Pair<Integer, Transition>>>(value, newHashSet))
	}
	
	private def getReceivingId(SynchronousComponentInstance outInstance, RaiseEventAction action, 
			Transition receivingTransition) {
		val actionMap = interactionIds.get(outInstance) //
		val idPair = actionMap.get(action)
		val receivingIds = idPair.value
		var int nextValue
		val previousValues = actionMap.values.map[it.value].flatten.map[it.key]
		if (previousValues.empty) {
			nextValue = 0
		}
		else {
			nextValue = previousValues.max + 1
		}
		receivingIds += new Pair(nextValue, receivingTransition);
		return nextValue
	}
	
	private def modifyModelForInteractionCoverage() {
		if (!INTERACTION_COVERAGE) {
			return
		}
		val sendingComponents = newHashSet
		val receivingComponents = newHashSet
		sendingComponents += interactionCoverableComponents
		receivingComponents += interactionCoverableComponents
		val interactionMatcher = RaiseInstanceEvents.Matcher.on(engine)
		sendingComponents.retainAll(interactionMatcher.allValuesOfoutInstance)
		receivingComponents.retainAll(interactionMatcher.allValuesOfinInstance)
		// Creating variables
		for (sendingComponent : sendingComponents) {
			sendingVariables.put(sendingComponent,
				this.nta.globalDeclarations.createVariable(DataVariablePrefix.NONE,
					nta.int, sendingComponent.sendingInteractionIdVariableName))
		}
		for (receivingComponent : receivingComponents) {
			receivingVariables.put(receivingComponent,
				this.nta.globalDeclarations.createVariable(DataVariablePrefix.NONE,
					nta.int, receivingComponent.receivingInteractionIdVariableName))
		}
		// Creating maps
		for (sendingComponent : sendingComponents) {
			interactionIds.put(sendingComponent, newHashMap)
		}
		// Annotating transitions
		val edgeAnnotations = newHashMap // One edge can handle at most one assignment to the same variable
		for (match : interactionMatcher.allMatches) {
			// Sending
			val raiseEventAction = match.raiseEventAction
			val outInstance = match.outInstance
			val sendingVariable = sendingVariables.get(outInstance)
			val uppaalAssignments = raiseEventAction.allExpressionValuesOfTo.filter(AssignmentExpression)
			checkState(!uppaalAssignments.empty)
			// There can be more than one resulting assignment, each edge has to be assigned once
			for (edge : uppaalAssignments.map[it.eContainer].filter(Edge).toSet) {
				// One edge can handle at most one assignment to the same variable (multiple raise event actions)!
				var int sendingId
				if (edgeAnnotations.containsKey(edge)) {
					sendingId = edgeAnnotations.get(edge)
					outInstance.setSendingId(raiseEventAction, sendingId)
				}
				else {
					sendingId = outInstance.getSendingId(raiseEventAction)
					edgeAnnotations.put(edge, sendingId)
					edge.createAssignmentExpression(edge_Update, sendingVariable, sendingId.toString)
				}
			}
			// Receiving
			val receivingTransition = match.receivingTransition
			val inInstance = match.inInstance
			val receivingVariable = receivingVariables.get(inInstance)
			val receivingEdges = receivingTransition.allValuesOfTo.filter(Edge)
			checkState(receivingEdges.size == 1)
			val receivingEdge = receivingEdges.head
			// There is only one receivingEdge in theory
			val receivingId = /*must be outInstance*/outInstance.getReceivingId(raiseEventAction, receivingTransition)
			receivingEdge.createAssignmentExpression(edge_Update, receivingVariable, receivingId.toString)
		}
	}
	
	def getInteractionIds() {
		return this.interactionIds
	}
	
	def modifyModelForTestGeneration() {
		modifyModelForTransitionCoverage
		modifyModelForInteractionCoverage
	}
	
}