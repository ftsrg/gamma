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
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference
import hu.bme.mit.gamma.property.model.ComponentInstancePortReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateExpression
import hu.bme.mit.gamma.property.model.ComponentInstanceTransitionReference
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
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
	protected final extension SimpleInstanceHandler instanceHandler = SimpleInstanceHandler.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(PropertyPackage propertyPackage, Component newTopComponent) {
		this.propertyPackage = propertyPackage
		this.newTopComponent = newTopComponent
	}
	
	def execute() {
		val newPropertyPackage = propertyPackage.unfoldPackage
		newPropertyPackage.import += newTopComponent.containingPackage
		newPropertyPackage.component = newTopComponent
		return newPropertyPackage
	}
	
	def PropertyPackage unfoldPackage(PropertyPackage propertyPackage) {
		val newPackage = propertyPackage.clone
		val contents = newPackage.getAllContentsOfType(ComponentInstanceStateExpression)
		val size = contents.size
		for (var i = 0; i < size; i++) {
			val content = contents.get(i)
			val newContent = content.unfold
			newContent.replace(content)
		}
		return newPackage
	}
	
	def dispatch EObject unfold(ComponentInstanceStateConfigurationReference reference) {
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
	
	def dispatch EObject unfold(ComponentInstanceVariableReference reference) {
		val oldInstance = reference.instance
		val newInstance = oldInstance.newSimpleInstance
		val newInstanceReference = newInstance.createInstanceReference
		val variable = reference.variable
		val newVariable = newInstance.getNewVariable(variable)
		return reference.clone	=> [
			it.instance = newInstanceReference
			it.variable = newVariable
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceEventReference reference) {
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
	
	def dispatch EObject unfold(ComponentInstanceEventParameterReference reference) {
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
	
	def dispatch EObject unfold(ComponentInstancePortReference reference) {
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
	
	def dispatch EObject unfold(ComponentInstanceTransitionReference reference) {
		val oldInstance = reference.instance
		val newInstance = oldInstance.newSimpleInstance
		val newInstanceReference = newInstance.createInstanceReference
		val transitionId = reference.transition
		val newTransitionId = newInstance.getNewTransitionId(transitionId)
		return reference.clone	=> [
			it.instance = newInstanceReference
			it.transition = newTransitionId
		]
	}
	
	protected def getNewSimpleInstance(ComponentInstanceReference instance) {
		return instance.checkAndGetNewSimpleInstance(newTopComponent)
	}
	
}