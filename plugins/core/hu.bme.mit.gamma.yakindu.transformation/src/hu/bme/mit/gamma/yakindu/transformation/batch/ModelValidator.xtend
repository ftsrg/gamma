/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.yakindu.transformation.batch

import hu.bme.mit.gamma.yakindu.transformation.queries.EmptyChoiceTransitions
import hu.bme.mit.gamma.yakindu.transformation.queries.EntryOrExitReactionWithGuards
import hu.bme.mit.gamma.yakindu.transformation.queries.NamesWithIncorrectCharacters
import hu.bme.mit.gamma.yakindu.transformation.queries.RaisedInEvents
import hu.bme.mit.gamma.yakindu.transformation.queries.RaisedOutEvents
import hu.bme.mit.gamma.yakindu.transformation.queries.StatesWithSameName
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.api.impl.RunOnceQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.yakindu.sct.model.sgraph.Statechart

class ModelValidator {

	protected Statechart resource
	protected ViatraQueryEngine engine
	protected RunOnceQueryEngine runOnceEngine
	
	new(Statechart resource) {
        this.resource = resource
        // Create EMF scope and EMF IncQuery engine based on the TTMC resource
        val scope = new EMFScope(resource)
        engine = ViatraQueryEngine.on(scope)
        runOnceEngine = new RunOnceQueryEngine(resource)
    }
    
    def checkModel() {
    	checkEntryAndExitLocalReactions
    	checkIds
    	checkUniqueNames
    	checkInEventRaisings
    	checkOutEventRaisings
    	checkEmptyChoiceTransitions
    }

	/**
	 * This method checks whether there are guards in entry or exit local reactions. If so, it throws an exception.
	 */
	private def checkEntryAndExitLocalReactions() throws Exception {
		val entryOrExitWithGuardMatches = runOnceEngine.getAllMatches(EntryOrExitReactionWithGuards.instance)
		if (entryOrExitWithGuardMatches.size != 0) {
			val states = new StringBuilder()
			for (entryOrExitWithGuardMatch : entryOrExitWithGuardMatches) {
				states.append(" " + entryOrExitWithGuardMatch.state.name)
			}
			throw new IllegalArgumentException("Entry or exit local reactions of states must not contain guards:" + states.toString())
		}
	}
	
	/**
	 * This method checks whether there are incorrect names.
	 */
	private def checkIds() throws Exception {
		val idMatcher = engine.getMatcher(NamesWithIncorrectCharacters.instance)
		for (idMatch : idMatcher.allMatches.filter[!it.namedElement.name.nullOrEmpty]) {
			throw new IllegalArgumentException("The following named element has an incorrect name: " +
				idMatch.namedElement.name + ". Only letters, underscore and digits are permitted.")
		}
	}
	
	/**
	 * This method checks whether there are multiple states with the same name.
	 */
	private def checkUniqueNames() throws Exception {
		val uniqueNamesMatcher = engine.getMatcher(StatesWithSameName.instance)
		for (uniqueNamesMatch : uniqueNamesMatcher.allMatches) {
			throw new IllegalArgumentException("The following states have the same name: " + uniqueNamesMatch.lhs + " and " + uniqueNamesMatch.rhs + ".")
		}
	}
	
	/**
	 * This method checks whether there are raised in-events.
	 */
	private def checkInEventRaisings() throws Exception {
		val raisedInEventsMatcher = engine.getMatcher(RaisedInEvents.instance)
		for (raisedInEventMatch : raisedInEventsMatcher.allMatches) {
			throw new IllegalArgumentException("The following IN event is raised by the statechart: " + raisedInEventMatch.event + ".")	
		}
	}

	/**
	 * This method checks whether any out-events are used as triggers.
	 */
	private def checkOutEventRaisings() throws Exception {
		val raisedOutEventsMatcher = engine.getMatcher(RaisedOutEvents.instance)
		for (raisedOutEventMatch : raisedOutEventsMatcher.allMatches) {
			throw new IllegalArgumentException("The following OUT event is used by the statechart: " + raisedOutEventMatch.event + ".")	
		}
	}
	
	
		/**
	 * This method checks whether any out-events are used as triggers.
	 */
	private def checkEmptyChoiceTransitions() throws Exception {
		val emptyTransitionsMatcher = engine.getMatcher(EmptyChoiceTransitions.instance)
		for (emptyTransitionsMatch : emptyTransitionsMatcher.allMatches) {
			val transition = emptyTransitionsMatch.transition
			throw new IllegalArgumentException("The following transition contains neither a trigger nor a guard: " +
				transition.source.name + " -> " + transition.target.name + ". Use a default trigger or a guard!")	
		}
	}
}