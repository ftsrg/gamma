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

import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstancePortReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceTransitionReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class PropertyUnfolder {
	
	protected final PropertyPackage propertyPackage
	protected final Component newTopComponent
	
	protected final extension CompositeModelFactory compositeFactory =
			CompositeModelFactory.eINSTANCE
	protected final extension UnfoldingTraceability traceability = UnfoldingTraceability.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(PropertyPackage propertyPackage, Component newTopComponent) {
		this.propertyPackage = propertyPackage
		this.newTopComponent = newTopComponent
	}
	
	def execute() {
		val newPropertyPackage = propertyPackage.unfoldPackage
		newPropertyPackage.imports += newTopComponent.containingPackage
		newPropertyPackage.component = newTopComponent
		return newPropertyPackage
	}
	
	def PropertyPackage unfoldPackage(PropertyPackage propertyPackage) {
		val newPackage = propertyPackage.clone
		val contents = newPackage.getAllContentsOfType(ComponentInstanceElementReferenceExpression)
		val size = contents.size
		for (var i = 0; i < size; i++) {
			val content = contents.get(i)
			val newContent = content.unfold
			newContent.replace(content)
		}
		return newPackage
	}
	
	def dispatch EObject unfold(ComponentInstanceStateReferenceExpression reference) {
		val oldInstance = reference.instance
		val newInstance = oldInstance.newSimpleInstance
		val newInstanceReference = newInstance.createInstanceReference
		val region = reference.region
		val newRegion = newInstance.getNewRegion(region)
		val state = reference.state
		val newState = newInstance.getNewState(state)
		return reference.clone	=> [
			it.instance = newInstanceReference
			it.region = newRegion
			it.state = newState
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceVariableReferenceExpression reference) {
		val oldInstance = reference.instance
		val newInstance = oldInstance.newSimpleInstance
		val newInstanceReference = newInstance.createInstanceReference
		val variable = reference.variableDeclaration
		val newVariable = newInstance.getNewVariable(variable)
		return reference.clone	=> [
			it.instance = newInstanceReference
			it.variableDeclaration = newVariable
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceEventReferenceExpression reference) {
		val oldInstance = reference.instance
		val newInstance = oldInstance.newSimpleInstance
		val newInstanceReference = newInstance.createInstanceReference
		val port = reference.port
		val newPort = newInstance.getNewPort(port)
		return reference.clone	=> [
			it.instance = newInstanceReference
			it.port = newPort
			// Event is the same
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceEventParameterReferenceExpression reference) {
		val oldInstance = reference.instance
		val newInstance = oldInstance.newSimpleInstance
		val newInstanceReference = newInstance.createInstanceReference
		val port = reference.port
		val newPort = newInstance.getNewPort(port)
		return reference.clone	=> [
			it.instance = newInstanceReference
			it.port = newPort
			// Event and parameter are the same
		]
	}
	
	def dispatch EObject unfold(ComponentInstancePortReferenceExpression reference) {
		val oldInstance = reference.instance
		val newInstance = oldInstance.newSimpleInstance
		val newInstanceReference = newInstance.createInstanceReference
		val port = reference.port
		val newPort = newInstance.getNewPort(port)
		return reference.clone	=> [
			it.instance = newInstanceReference
			it.port = newPort
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceTransitionReferenceExpression reference) {
		val oldInstance = reference.instance
		val newInstance = oldInstance.newSimpleInstance
		val newInstanceReference = newInstance.createInstanceReference
		val transitionId = reference.transitionId
		val newTransitionId = newInstance.getNewTransitionId(transitionId)
		return reference.clone	=> [
			it.instance = newInstanceReference
			it.transitionId = newTransitionId
		]
	}
	
	protected def getNewSimpleInstance(ComponentInstanceReferenceExpression instance) {
		return instance.checkAndGetNewSimpleInstance(newTopComponent)
	}
	
}