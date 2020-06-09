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
package hu.bme.mit.gamma.uppaal.transformation

import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.uppaal.transformation.queries.ConstantDeclarations
import hu.bme.mit.gamma.uppaal.transformation.queries.ConstantDeclarationsWithoutInit
import hu.bme.mit.gamma.uppaal.transformation.queries.EntryStatesWithIncorrectIncomingTransition
import hu.bme.mit.gamma.uppaal.transformation.queries.FromChoiceToHigherTransition
import hu.bme.mit.gamma.uppaal.transformation.queries.InOutEvents
import hu.bme.mit.gamma.uppaal.transformation.queries.InOutTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.MultipleEntryStatesWithoutIncomingTransition
import hu.bme.mit.gamma.uppaal.transformation.queries.NamedElements
import hu.bme.mit.gamma.uppaal.transformation.queries.States
import hu.bme.mit.gamma.uppaal.transformation.queries.VariableDeclarations
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

class ModelValidator {
	
	protected Component topComponent
	protected ResourceSet resourceSet 
	protected ViatraQueryEngine engine
	
	boolean checkTopComponentParameters
	
	new(Component topComponent, boolean checkTopComponentParameters) {
        this.resourceSet = topComponent.eResource.resourceSet
        this.topComponent = topComponent
        this.checkTopComponentParameters = checkTopComponentParameters
        // Create EMF scope and EMF IncQuery engine based on the TTMC resource
        val scope = new EMFScope(resourceSet)
        engine = ViatraQueryEngine.on(scope)
    }
    
    new(Component topComponent) {
        this(topComponent, true)
    }
    
    def checkModel() {
    	if (checkTopComponentParameters) {
    		checkTopComponentParameters()
    	}
    	checkConstants
    	checkInOutEvents
    	checkInOutTransitions
    	checkChoiceTransitions
    	checkEntryStatesWithIncorrectIncomingTransition
    	checkMultipleEntryStatesWithoutIncomingTransition
    	checkFloatVariables
    	checkNames
//    	checkUppaalKeywords
    }
    
	/**
	 * This method checks whether the top components has parameters. If so, it throws an exception.
	 */
	def checkTopComponentParameters() {
		if (!topComponent.parameterDeclarations.empty) {
			throw new IllegalArgumentException("The top component must not have parameters. " + topComponent.parameterDeclarations)
		}
	}
	
    /**
	 * This method checks whether there are constants without initialization. If so, it throws an exception.
	 */
    private def checkConstants() {
    	val constanstsMatcher = engine.getMatcher(ConstantDeclarationsWithoutInit.instance)
		val constanstsMatches = constanstsMatcher.allMatches
		if (constanstsMatches.size != 0) {
			val constansts = new StringBuilder()
			for (constanstsMatch : constanstsMatches) {
				constansts.append(" " + constanstsMatch.name)
			}
			throw new IllegalArgumentException("The constant must have an initial value: " + constansts.toString())
		}
    }
    
    /**
	 * This method checks whether there are in-out events. If so, it throws an exception.
	 */
    private def checkInOutEvents() {
    	val inOutEventsMatcher = engine.getMatcher(InOutEvents.instance)
		val inOutEventsMatches = inOutEventsMatcher.allMatches
		if (inOutEventsMatches.size != 0) {
			val events = new StringBuilder()
			for (inOutEventsMatch : inOutEventsMatches) {
				events.append(" " + inOutEventsMatch.port.name + "->" + inOutEventsMatch.event.name)
			}
			throw new IllegalArgumentException("In-out events are not supported in the UPPAAL mapping:" + events.toString())
		}
    }
    
    /**
	 * This method checks whether there are transitions that connect nodes extraordinarily. If so, it throws an exception.
	 */
    private def checkInOutTransitions() {
    	val extraordinaryTransitionsMatcher = engine.getMatcher(InOutTransitions.instance)
		val extraordinaryTransitionsMatches = extraordinaryTransitionsMatcher.allMatches
		if (extraordinaryTransitionsMatches.size != 0) {
			val transitions = new StringBuilder()
			for (entryOrExitWithGuardMatch : extraordinaryTransitionsMatches) {
				transitions.append(" " + entryOrExitWithGuardMatch.source.name + "->" + entryOrExitWithGuardMatch.target.name)
			}
			throw new IllegalArgumentException("The source/target of a transition must be an ancestor/descendant of the target/source:" + transitions.toString())
		}
    }
    
    /**
	 * This method checks whether there are transitions coming from a choice and going to a node that is on a hierarchy level. If so, it throws an exception.
	 */
	private def checkChoiceTransitions() {
		val choiceTransitionsMatcher = engine.getMatcher(FromChoiceToHigherTransition.instance)
		val choiceTransitionsMatches = choiceTransitionsMatcher.allMatches
		if (choiceTransitionsMatches.size != 0) {
			val transitions = new StringBuilder()
			for (choiceTransitionsMatch : choiceTransitionsMatches) {
				transitions.append(" " + choiceTransitionsMatch.transition)
			}
			throw new IllegalArgumentException("A transition must not go to a higher level hierarchy node if its source is a choice and the region has history:" + transitions.toString())
		}
	}
	
	private def checkEntryStatesWithIncorrectIncomingTransition() {
		val matcher = engine.getMatcher(EntryStatesWithIncorrectIncomingTransition.instance)
		val matches = matcher.allMatches
		if (matches.size != 0) {
			val entry = new StringBuilder()
			for (match : matches) {
				entry.append(" " + match.entry.name)
			}
			throw new IllegalArgumentException("An entry node must not have incoming transitions from non-entry nodes in the same region:" + entry.toString())
		}
	}
	
	private def checkMultipleEntryStatesWithoutIncomingTransition() {
		val matcher = engine.getMatcher(MultipleEntryStatesWithoutIncomingTransition.instance)
		val matches = matcher.allMatches
		if (matches.size != 0) {
			val regions = new StringBuilder()
			for (match : matches) {
				regions.append(" " + match.region.name)
			}
			throw new IllegalArgumentException("A region cannot have multiple entry nodes without an incoming transition:" + regions.toString())
		}
	}
	
	/**
	 * This method checks whether there are float variables and constants in the model. If so, it throws an exception.
	 */
	private def checkFloatVariables() {
		val variablesMatcher = engine.getMatcher(VariableDeclarations.instance)
		val costantsMatcher = engine.getMatcher(ConstantDeclarations.instance)
		val variables = variablesMatcher.allMatches.filter[it.type instanceof DecimalTypeDefinition].map[it.variable]
		val constants = costantsMatcher.allMatches.filter[it.type instanceof DecimalTypeDefinition].map[it.constant]
		if (variables.size != 0) {
			throw new IllegalArgumentException("Float variables cannot be transformed:" + variables.toString())
		}
		if (constants.size != 0) {
			throw new IllegalArgumentException("Float constants cannot be transformed:" + constants.toString())
		}
	}
	
	/**
	 * This method checks whether there are declaration names that are equal to state names. If so, it throws an exception.
	 */
	private def checkNames() {
		val variablesMatcher = engine.getMatcher(VariableDeclarations.instance)
		val costantsMatcher = engine.getMatcher(ConstantDeclarations.instance)
//		val signalsMatcher = engine.getMatcher(Events.instance)
		val statesMatcher = engine.getMatcher(States.instance)
		val variables = variablesMatcher.allMatches.map[it.variable.name]
		val constants = costantsMatcher.allMatches.map[it.name]
//		val signals = signalsMatcher.allMatches.map[it.event.name]
		val states = statesMatcher.allMatches.map[it.state.name].toSet
		for (varName : variables + constants/* + signals*/) {
			if (states.contains(varName)) {
				throw new IllegalArgumentException("This variable is used as a declaration name and a state name as well: " + varName)
			}
		}
	}
	
	/**
	 * This method checks whether there are UPPAAL keywords used in the names of model elements. If so, it throws an exception.
	 */
	def checkUppaalKeywords() {
		val names = engine.getMatcher(NamedElements.instance).allValuesOfname
		val uppaalKeywords = #{"init",  "system", "process", "urgent" , "broadcast" , "chan" , "int",
			"bool" , "void" , "true", "false", "clock", "const", "return"}
		for (name : names) {
			if (uppaalKeywords.contains(name)) {
				throw new IllegalArgumentException(name + " is an UPPAAL keyword, therefore it cannot be used in the model.")
			}
		}
	}
	
}