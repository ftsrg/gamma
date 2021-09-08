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

import hu.bme.mit.gamma.expression.model.NamedElement
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.transformation.util.Namings.*

class ComponentInstanceReferenceMapper {
	// Singleton
	public static final ComponentInstanceReferenceMapper INSTANCE = new ComponentInstanceReferenceMapper
	protected new() {}
	//
	protected final SimpleInstanceHandler simpleInstanceHandler = SimpleInstanceHandler.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def checkAndGetNewSimpleInstance(ComponentInstanceReference originalInstance, Component newTopComponent) {
		return simpleInstanceHandler.checkAndGetNewSimpleInstance(originalInstance, newTopComponent)
	}
	
	def <T extends NamedElement> getNewObject(ComponentInstanceReference originalInstance,
			T originalObject, Component newTopComponent) {
		val originalFqn = originalObject.FQNUpToComponent
		val newInstance = originalInstance.checkAndGetNewSimpleInstance(newTopComponent)
		val newComponent = newInstance.type
		val contents = newComponent.getAllContentsOfType(originalObject.class)
		for (content : contents) {
			val fqn = content.FQNUpToComponent
			// Structural properties during reduction change, names do not change
			// TODO FQN?
			if (originalFqn == fqn) {
				return content as T
			}
		}
		throw new IllegalStateException("New object not found: " + originalObject + 
			"Known Xtext bug: for generated gdp, the variables references are not resolved.")
	}
	
}