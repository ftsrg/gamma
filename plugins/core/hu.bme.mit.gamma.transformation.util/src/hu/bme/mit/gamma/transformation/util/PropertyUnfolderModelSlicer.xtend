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

import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class PropertyUnfolderModelSlicer {
	
	protected final Component newTopComponent
	protected final PropertyPackage oldPropertyPackage
	protected final boolean removeOutEventRaisings
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(Component newTopComponent, PropertyPackage oldPropertyPackage, boolean removeOutEventRaisings) {
		this.newTopComponent = newTopComponent
		this.oldPropertyPackage = oldPropertyPackage
		this.removeOutEventRaisings = removeOutEventRaisings
	}
	
	def void execute() {
		val newPackage = newTopComponent.containingPackage
		// Slicing the model with respect to the optional properties
		if (oldPropertyPackage !== null) {
			val propertyUnfolder = new PropertyUnfolder(oldPropertyPackage, newTopComponent)
			val unfoldedPropertyPackage = propertyUnfolder.execute
			val slicer = new ModelSlicer(unfoldedPropertyPackage, removeOutEventRaisings)
			slicer.execute
			ecoreUtil.save(newPackage)
		}
	}
	
}