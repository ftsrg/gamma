/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.NamedElement
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstancePortReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceTransitionReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.TransitionIdAnnotation
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*

class UnfoldingTraceability {
	// Singleton
	public static final UnfoldingTraceability INSTANCE =  new UnfoldingTraceability
	protected new() {}
	//
	
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	// Folded -> unfolded mapping
	
	// Component instance transition references
	
	def getNewIncludedSimpleInstanceTransitions(
			Collection<ComponentInstanceTransitionReferenceExpression> includedOriginalReferences,
			Collection<ComponentInstanceTransitionReferenceExpression> excludedOriginalReferences,
			Component newType) {
		val newTransitions = newArrayList
		// The semantics is defined here: including has priority over excluding
		newTransitions -= excludedOriginalReferences.getNewSimpleInstanceTransitions(newType)
		newTransitions += includedOriginalReferences.getNewSimpleInstanceTransitions(newType)
		return newTransitions
	}
	
	def getNewSimpleInstanceTransitions(
			Collection<ComponentInstanceTransitionReferenceExpression> originalReferences,
			Component newType) {
		val newTransitions = newArrayList
		for (originalReference : originalReferences) {
			val originalInstance = originalReference.instance
			val originalTransition = originalReference.transitionId.getSelfOrContainerOfType(Transition)
			val newInstance = originalInstance.checkAndGetNewSimpleInstance(newType)
			val newTransition = newInstance.getNewTransition(originalTransition) 
			if (newTransition !== null) {
				newTransitions += newInstance.getNewTransition(originalTransition)
			} 
		}
		return newTransitions
	}
	
	def getNewTransition(SynchronousComponentInstance newInstance,
			Transition originalTransition) {
		val newType = newInstance.getStatechart
		for (transition : newType.transitions) {
			if (transition.helperEquals(originalTransition)) {
				return transition
			}
		}
		return null // Can be null due to reduction
	}
	
	def getNewTransitionId(SynchronousComponentInstance newInstance,
			TransitionIdAnnotation originalIdAnnotation) {
		val newType = newInstance.getStatechart
		for (annotation : newType.transitions.map[it.idAnnotation]) {
			if (annotation.helperEquals(originalIdAnnotation)) {
				return annotation
			}
		}
		return null // Can be null due to reduction
	}
	
	// Component instance state references
	
	def getNewIncludedSimpleInstanceStates(
			Collection<ComponentInstanceStateReferenceExpression> includedOriginalReferences,
			Collection<ComponentInstanceStateReferenceExpression> excludedOriginalReferences,
			Component newType) {
		val newStates = newArrayList
		// The semantics is defined here: including has priority over excluding
		newStates -= excludedOriginalReferences.getNewSimpleInstanceStates(newType)
		newStates += includedOriginalReferences.getNewSimpleInstanceStates(newType)
		return newStates
	}
	
	def getNewSimpleInstanceStates(
			Collection<ComponentInstanceStateReferenceExpression> originalReferences,
			Component newType) {
		val newStates = newArrayList
		for (originalReference : originalReferences) {
			val originalInstance = originalReference.instance
			val originalState= originalReference.state 
			val newInstance = originalInstance.checkAndGetNewSimpleInstance(newType)
			val newState = newInstance.getNewState(originalState)
			if (newState !== null) {
				newStates += newState
			} 
		}
		return newStates
	}
	
	def getNewState(SynchronousComponentInstance newInstance, State originalState) {
		val newType = newInstance.getStatechart
		for (state : newType.allStates) {
			// Not helper equals, as reduction can change the subregions
			if (state.equal(originalState)) {
				return state
			}
		}
		return null // Can be null due to reduction
	}
	
	private def equal(State lhs, State rhs) {
		return lhs.FQN == rhs.FQN
	}
	
	def getNewRegion(SynchronousComponentInstance newInstance, Region originalRegion) {
		val newType = newInstance.getStatechart
		for (region : newType.allRegions) {
			// Not helper equals, as reduction can change the subregions
			if (region.equal(originalRegion)) {
				return region
			}
		}
		return null // Can be null due to reduction
	}
	
	private def equal(Region lhs, Region rhs) {
		return lhs.FQN == rhs.FQN
	}
	
	// Component instance port references
	
	def getNewIncludedSimpleInstancePorts(
			Collection<ComponentInstancePortReferenceExpression> includedOriginalReferences,
			Collection<ComponentInstancePortReferenceExpression> excludedOriginalReferences,
			Component newType) {
		val newPorts = newArrayList
		// The semantics is defined here: including has priority over excluding
		newPorts -= excludedOriginalReferences.getNewSimpleInstancePorts(newType)
		newPorts += includedOriginalReferences.getNewSimpleInstancePorts(newType)
		return newPorts
	}
	
	def getNewSimpleInstancePorts(
			Collection<ComponentInstancePortReferenceExpression> originalReferences,
			Component newType) {
		val newPorts = newArrayList
		for (originalReference : originalReferences) {
			val originalInstance = originalReference.instance
			val originalPort = originalReference.port 
			val newInstance = originalInstance.checkAndGetNewSimpleInstance(newType)
			newPorts += newInstance.getNewPort(originalPort) 
		}
		return newPorts
	}
	
	def getNewPort(SynchronousComponentInstance newInstance, Port originalPort) {
		val newType = newInstance.type
		for (port : newType.allPorts) {
			if (port.nameEquals(originalPort)) {
				return port // Port names must be unique
			}
		}
		throw new IllegalStateException("Not found port: " + originalPort)
	}
	
	private def nameEquals(NamedElement lhs, NamedElement rhs) {
		return lhs.name == rhs.name
	}
	
	// Component variable references
	
	def getNewSimpleInstanceVariables(
			Collection<ComponentInstanceVariableReferenceExpression> originalReferences,
			Component newType) {
		val newVariables = newArrayList
		for (originalReference : originalReferences) {
			val originalInstance = originalReference.instance
			val originalVariable = originalReference.variableDeclaration 
			val newVariable = originalInstance.getNewVariable(originalVariable, newType)
			newVariables += newVariable
		}
		return newVariables
	}
	
	def getNewVariable(ComponentInstanceReferenceExpression originalInstance,
			VariableDeclaration originalVariable, Component newType) {
		val newInstance = originalInstance.checkAndGetNewSimpleInstance(newType)
		val newVariable = newInstance.getNewVariable(originalVariable)
		return newVariable
	}
	
	def getNewVariable(SynchronousComponentInstance newInstance,
			VariableDeclaration originalVariable) {
		val newType = newInstance.getStatechart
		for (variable : newType.variableDeclarations) {
			if (variable.nameEquals(originalVariable)) {
				return variable // Variable names must be unique
			}
		}
		throw new IllegalStateException("Not found variable: " + originalVariable)
	}
	
	// Component instance references
	
	def getNewSimpleInstances(
			Collection<ComponentInstanceReferenceExpression> includedOriginalInstances,
			Collection<ComponentInstanceReferenceExpression> excludedOriginalInstances,
			Component newType) {
		val newInstances = newArrayList
		if (includedOriginalInstances.empty) {
			// If it is empty, it means all simple instances must be covered
			newInstances += newType.allSimpleInstances
		}
		// The semantics is defined here: including has priority over excluding
		newInstances -= excludedOriginalInstances.getNewSimpleInstances(newType)
		newInstances += includedOriginalInstances.getNewSimpleInstances(newType)
		return newInstances
	}
	
	def getNewSimpleInstances(
			Collection<ComponentInstanceReferenceExpression> originalInstances,
			Component newType) {
		val accpedtedNewInstances = newArrayList
		for (originalInstance : originalInstances) {
			accpedtedNewInstances += originalInstance.getNewSimpleInstances(newType)
		}
		return accpedtedNewInstances
	}
	
	def getNewSimpleInstances(ComponentInstanceReferenceExpression originalInstance, Component newType) {
		val newInstances = newType.allSimpleInstances
		val acceptedNewInstances = newArrayList
		// This instance can be a composite instance, thus more than one new instance can be here
		val lastInstance = originalInstance.lastInstance
		val lastInstanceType = lastInstance.derivedType
		val originalPackage = lastInstance.containingPackage
		val isUnfolded = originalPackage.unfolded
		if (isUnfolded) {
			val name = lastInstance.name
			acceptedNewInstances += newInstances.filter[it.name == name]
		}
		else {
			for (newInstance : newInstances) {
				if (originalInstance.contains(newInstance)) {
					acceptedNewInstances += newInstance
				}
			}
		}
		val size = acceptedNewInstances.size
		if (lastInstanceType instanceof StatechartDefinition) {
			checkState(size == 1, size)
		}
		else {
			checkState(size >= 1, size)
		}
		return acceptedNewInstances
	}
	
	def checkAndGetNewSimpleInstance(ComponentInstanceReferenceExpression originalInstance, Component newType) {
		val newInstances = originalInstance.getNewSimpleInstances(newType)
		// Only one instance is expected
		checkState(newInstances.size == 1)
		return newInstances.head
	}
	
	
	def getNewAsynchronousSimpleInstances(ComponentInstanceReferenceExpression original, Component newType) {
		return newType.allAsynchronousSimpleInstances
				.filter[original.contains(it)].toList
	}
	
	def contains(ComponentInstanceReferenceExpression original, ComponentInstance copy) {
		val originalInstances = original.componentInstanceChain
		 // If the (AA) component is wrapped, the original will not contain the wrapper instance
		val lastOriginalInstance = originalInstances.lastOrNull
		if (lastOriginalInstance.unfolded && copy.unfolded) {
			// We handle if both are already unfolded - incorrect call, though: original is not actually original
			return copy.name.startsWith(lastOriginalInstance.name)
		}
		
		// Correct call, original is not unfolded
		
		val copyInstances = copy.componentInstanceChain
		// copy might have a wrapper instance at front
		if (copy.wrapped) {
			val originalFirstInstance = originalInstances.head
			val originalComponent = originalFirstInstance.containingComponent
			val wrappedComponent = originalComponent.wrapComponent
			val wrapperInstance = wrappedComponent.instances.head
			
			// "Adding" the wrapper instance to match the copy
			originalInstances.add(0, wrapperInstance)
		}
		
//		if (lastOriginalInstance.asynchronousStatechart) {
//			val asynchronousStatechart = lastOriginalInstance.derivedType
//			
//			val wrappedStatechart = asynchronousStatechart.wrapComponent
//			val wrapperInstance = wrappedStatechart.instances.head
//			
//			originalInstances += wrapperInstance
//		}
		
		// The naming conventions are clear
		// Without originalInstances.head.name == copyInstances.head.name,
		// ambiguous naming situations could occur, e.g.,
		// the FQN of the chain "a -> b" is equal to the name of instance "a_b"
		val copyName = copy.name
		val originalFqn = originalInstances.FQN
		
		return originalInstances.head.name == copyInstances.head.name &&
			copyName.startsWith(originalFqn)
	}
	
	// Currently not used - maybe in the future?
	
	protected def <T extends NamedElement> getNewObject(ComponentInstanceReferenceExpression originalInstance,
			T originalObject, Component newTopComponent) {
		val originalFqn = originalObject.FQNUpToComponent
		val newInstance = originalInstance.checkAndGetNewSimpleInstance(newTopComponent)
		val newComponent = newInstance.type
		val contents = newComponent.getAllContentsOfType(originalObject.class)
		for (content : contents) {
			val fqn = content.FQNUpToComponent
			// Structural properties during reduction change, names do not change
			// FQN does not work for elements without named element containment chains, e.g., transitions
			if (originalFqn == fqn) {
				return content as T
			}
		}
		throw new IllegalStateException("New object not found: " + originalObject + 
			"Known Xtext bug: for generated gdp, the variables references are not resolved")
	}
	
	// Unfolded -> folded mapping
	
	def getOriginalSimpleInstanceReferences(Component originalType) {
		return originalType.allSimpleInstanceReferences
	}
	
	def getOriginalSimpleInstanceReference(
			SynchronousComponentInstance newInstance, Component originalType) {
		// NewInstance is statechart, only one result is accepted; if we want to handle
		// composite new instances, "newInstance.contains(originalInstance)" has to be introduced
		checkState(newInstance.isStatechart)
		
		val originalSimpleInstances = originalType.originalSimpleInstanceReferences
		
//		val needsWrapping = originalType.needsWrapping
//		if (needsWrapping) {
//			for (originalSimpleInstance : originalSimpleInstances.toSet) {
//				originalSimpleInstances -= originalSimpleInstance
//				val wrapperInstance = originalType.instantiateComponent
//				val wrappedOriginalSimpleInstance = originalSimpleInstance.prepend(wrapperInstance)
//				originalSimpleInstances += wrappedOriginalSimpleInstance
//			}
//		}
		
		for (originalSimpleInstance : originalSimpleInstances) {
			// There are some AA and CCC wrappings of statecharts in the unfolding process, which
			// should be handled by the below method call ("contains" instead of "equals")
			if (originalSimpleInstance.contains(newInstance)) {
				 // Only one is expected
//				if (needsWrapping) {
//					return originalSimpleInstance.getChild // Removing wrapper instance
//				}
				return originalSimpleInstance
			}
		}
		throw new IllegalStateException("Not found original instance for " + newInstance)
	}
	
	def getOriginalScheduledInstanceReferences(Component originalType) {
		return originalType.allScheduledInstanceReferences
	}
	
	def getOriginalScheduledInstanceReference(
			ComponentInstance newInstance, Component originalType) {
		val originalScheduledInstances = originalType.originalScheduledInstanceReferences

		for (originalScheduledInstance : originalScheduledInstances) {
			if (originalScheduledInstance.contains(newInstance)) {
				return originalScheduledInstance
			}
		}
		throw new IllegalStateException("Not found original instance for " + newInstance)
	}
	
	// getOriginal.. methods
	
	def getOriginalPort(ComponentInstanceReferenceExpression originalInstance, Port newPort) {
		val statechartInstance = originalInstance.lastInstance
		return statechartInstance.getOriginalPort(newPort)
	}
	
	def getOriginalPort(ComponentInstance originalInstance, Port newPort) {
		val originalType = originalInstance.getStatechart
		return originalType.getOriginalPort(newPort)
	}
	
	def getOriginalPort(Component originalComponent, Port newPort) {
		for (originalPort : originalComponent.allPorts) {
			if (originalPort.nameEquals(newPort)) {
				return originalPort // Port names must be unique
			}
		}
		throw new IllegalArgumentException("Not found port: " + newPort)
	}
	
	def getOriginalEvent(Component originalComponent, Event newEvent) {
		for (originalEvent : originalComponent.allPorts
				.map[it.allEvents].flatten ) {
			if (originalEvent.containingInterface.nameEquals(newEvent.containingInterface) &&
					originalEvent.nameEquals(newEvent)) {
				return originalEvent
			}
		}
		throw new IllegalArgumentException("Not found event: " + newEvent)
	}
	
	def getOriginalState(ComponentInstanceReferenceExpression originalInstance, State newState) {
		val statechartInstance = originalInstance.lastInstance
		return statechartInstance.getOriginalState(newState)
	}
	
	def getOriginalState(ComponentInstance originalInstance, State newState) {
		val originalType = originalInstance.getStatechart
		for (originalState : originalType.allStates) {
			if (originalState.equal(newState)) {
				return originalState
			}
		}
		throw new IllegalArgumentException("Not found state: " + newState)
	}
	
	def getOriginalVariable(ComponentInstanceReferenceExpression originalInstance, VariableDeclaration newVariable) {
		val statechartInstance = originalInstance.lastInstance
		return statechartInstance.getOriginalVariable(newVariable)
	}
	
	def getOriginalVariable(ComponentInstance originalInstance, VariableDeclaration newVariable) {
		val originalType = originalInstance.getStatechart
		for (originalVariable : originalType.variableDeclarations) {
			if (originalVariable.nameEquals(newVariable)) {
				return originalVariable // Variable names must be unique
			}
		}
		throw new IllegalArgumentException("Not found variable: " + newVariable)
	}
	
	def getOriginalTypeDeclaration(Component originalComponent, TypeDeclaration newTypeDeclaration) {
		val originalTypeDeclarations = originalComponent.originalTypeDeclarations
		for (originalTypeDeclaration : originalTypeDeclarations) {
			if (originalTypeDeclaration.nameEquals(newTypeDeclaration)) {
				return originalTypeDeclaration // Type declaration names must be unique
			}
		}
		throw new IllegalArgumentException("Not found type declaration: " + newTypeDeclaration)
	}
	
	def getOriginalEnumLiteral(Component originalComponent, EnumerationLiteralDefinition newEnumLiteral) {
		val originalEnumLiterals = originalComponent.originalTypeDeclarations
				.map[it.type].filter(EnumerationTypeDefinition)
				.map[it.literals].flatten
				.toSet
		for (originalEnumLiteral : originalEnumLiterals) {
			if (originalEnumLiteral.typeDeclaration.nameEquals(newEnumLiteral.typeDeclaration) &&
					originalEnumLiteral.nameEquals(newEnumLiteral)) {
				return originalEnumLiteral
			}
		}
		throw new IllegalArgumentException("Not found enum literal: " + newEnumLiteral)
	}
	
	//
	
	protected def getOriginalTypeDeclarations(Component originalComponent) {
		return originalComponent.containingPackage
				.selfAndAllImports.map[it.typeDeclarations].flatten
				.toSet
	}
	
}