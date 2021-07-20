/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.annotations

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.property.model.ComponentInstancePortReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceTransitionReference
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.lib.annotations.Data

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class AnnotationStructures { }
	
///
// Auxiliary classes for transitions, interactions and dataflow during annotation
///

class TransitionAnnotations {
	
	final Map<Transition, VariableDeclaration> transitionPairVariables
	
	new(Map<Transition, VariableDeclaration> transitionPairVariables) {
		this.transitionPairVariables = transitionPairVariables
	}
	
	def getTransitions() {
		return transitionPairVariables.keySet
	}
	
	def isAnnotated(Transition transition) {
		return transitionPairVariables.containsKey(transition)
	}
	
	def getVariable(Transition transition) {
		return transitionPairVariables.get(transition)
	}
	
	def isEmpty() {
		return transitionPairVariables.empty
	}
	
}

@Data
class VariablePair {
	VariableDeclaration first
	VariableDeclaration second
	
	def hasFirst() {
		return first !== null
	}
	
	def hasSecond() {
		return second !== null
	}
	
}

@Data
class TransitionAnnotation {
	Transition transition
	VariableDeclaration transitionVariable
	Long transitionId
}

@Data
class TransitionPairAnnotation {
	TransitionAnnotation incomingAnnotation
	TransitionAnnotation outgoingAnnotation
}

@Data
class Interaction {
	RaiseEventAction sender
	Transition receiver
	VariablePair variablePair
	Long senderId
	Long receiverId
}

class InteractionAnnotations {
	
	final Collection<Interaction> interactions
	Set<Interaction> interactionSet
	
	new(Collection<Interaction> interactions) {
		this.interactions = interactions
	}
	
	def getInteractions() {
		return this.interactions
	}
	
	def getUniqueInteractions() {
		// If the interactions are not "every-interaction", duplications can occur
		if (interactionSet === null) {
			interactionSet = newHashSet
			interactionSet += interactions
			
			// After this unique filter, some sender-receiver comments might not contain every element
			// Can be fixed by storing a list for the receivers, not a single element
			val interactionList = interactionSet.toList
			for (var i = 0; i < interactionList.size - 1; i++) {
				val lhs = interactionList.get(i)
				for (var j = i + 1; j < interactionList.size; j++) {
					val rhs = interactionList.get(j)
					if (lhs.variablePair.equals(rhs.variablePair)) { // == operator does not work for some reason
						val first = lhs.variablePair.first // == rhs.variablePair.first 
						val second = lhs.variablePair.second // == rhs.variablePair.second 
						if ((first === null || lhs.senderId.equals(rhs.senderId)) && 
								(second === null || lhs.receiverId.equals(rhs.receiverId))) {
							interactionSet -= rhs
						}
					}
				}
			}
		}
		return interactionSet
	}
	
	def isEmpty() {
		return this.interactions.empty
	}
	
}

interface DataflowDeclarationHandler {
	def Collection<DataflowReferenceVariable> getDefDataflowReferences(EObject defReference)
	def VariableDeclaration getUseVariable(ReferenceExpression useReference)
}

@Data
class DataflowReferenceVariable {
	EObject originalVariableReference // EventParameterReferenceExpression, DirectReferenceExpression or RaiseEventAction
	VariableDeclaration defUseVariable // Boolean variable denoting def or use
}

//
@Data
class DefVariableId {
	VariableDeclaration defVariable // Integer variable to store ids for the definitions
	Long defId // The id of the definition to store in defVariable
}

@Data
class DefUseVariablePair {
	VariableDeclaration defVariable // Integer variable to store ids for the definitions
	VariableDeclaration useVariable // Integer variable to store ids of last definition when uses happen
}

@Data
class DefReferenceId {
	EObject defReference
	Long defId // The id of the definition to store in defVariable
}

@Data
class UseVariable {
	ReferenceExpression useReference
	VariableDeclaration useVariable
}
//

class DefUseReferences {
	final Map<? extends Declaration, /* Original declaration (parameter or variable) whose def or use is marked */
		List<DataflowReferenceVariable> /* Reference-variable pairs denoting if the original declaration is set or read */>
			declarationDefs
	
	new(Map<? extends Declaration, List<DataflowReferenceVariable>> declarationDefs) {
		this.declarationDefs = declarationDefs
	}
	
	def getVariables() {
		return declarationDefs.keySet
	}
	
	def getAuxiliaryReferences(Declaration declaration) {
		if (declarationDefs.containsKey(declaration)) {
			return declarationDefs.get(declaration)
		}
		else {
			return #[]
		}
	}
	
	def getAuxiliaryVariables(Declaration declaration) {
		return declaration.getAuxiliaryReferences.map[it.getDefUseVariable].toList
	}
	
}

class AnnotationNamings {
	
	public static val PREFIX = "__id_"
	public static val POSTFIX = "_"
	
	int id = 0
	int defId = 0
	int useId = 0
	int interactionDefId = 0
	int interactionUseId = 0
	
	def String getVariableName(Transition transition)
		'''«IF transition.id !== null»«transition.id»«ELSE»«PREFIX»«transition.sourceState.name»_«id++»_«transition.targetState.name»«POSTFIX»«ENDIF»'''
	def String getFirstVariableName(StatechartDefinition statechart)
		'''«PREFIX»first_«statechart.name»«id++»«POSTFIX»'''
	def String getSecondVariableName(StatechartDefinition statechart)
		'''«PREFIX»second_«statechart.name»«id++»«POSTFIX»'''
	def String getParameterName(Event event)
		'''«PREFIX»«event.name»«POSTFIX»'''
	def String getDefVariableName(VariableDeclaration variable)
		'''«PREFIX»def_«variable.name»_«defId++»«POSTFIX»'''
	def String getUseVariableName(VariableDeclaration variable)
		'''«PREFIX»use_«variable.name»_«useId++»«POSTFIX»'''
	def String getInteractionDefVariableName(RaiseEventAction raise)
		'''«PREFIX»def_«raise.port.name»_«raise.event.name»_«interactionDefId++»«POSTFIX»'''
	def String getInteractionUseVariableName(EventParameterReferenceExpression reference)
		'''«PREFIX»use_«reference.port.name»_«reference.event.name»_«reference.parameter.name»_«interactionUseId++»«POSTFIX»'''
}

///
// Auxiliary data objects for specifying annotatable elements
///

enum InteractionCoverageCriterion {
	EVERY_INTERACTION, STATES_AND_EVENTS, EVENTS
}

enum DataflowCoverageCriterion {
	ALL_DEF, ALL_P_USE, ALL_C_USE, ALL_USE
}

@Data
class ComponentInstanceReferences {
	Collection<ComponentInstanceReference> include
	Collection<ComponentInstanceReference> exclude
}

@Data
class ComponentPortReferences {
	Collection<ComponentInstancePortReference> include
	Collection<ComponentInstancePortReference> exclude
}

@Data
class ComponentStateReferences {
	Collection<ComponentInstanceStateConfigurationReference> include
	Collection<ComponentInstanceStateConfigurationReference> exclude
}

@Data
class ComponentVariableReferences {
	Collection<ComponentInstanceVariableReference> include
	Collection<ComponentInstanceVariableReference> exclude
}

@Data
class ComponentTransitionReferences {
	Collection<ComponentInstanceTransitionReference> include
	Collection<ComponentInstanceTransitionReference> exclude
}

@Data
class ComponentInstancePortReferences {
	ComponentInstanceReferences instances
	ComponentPortReferences ports
}

@Data
class ComponentInstancePortStateTransitionReferences extends ComponentInstancePortReferences {
	ComponentStateReferences states
	ComponentTransitionReferences transitions
}

@Data
class ComponentInstanceVariableReferences {
	ComponentInstanceReferences instances
	ComponentVariableReferences variables
}