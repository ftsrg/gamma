/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class GammaToLowlevelTransformer {
	
	protected final extension StatechartToLowlevelTransformer transformer = new StatechartToLowlevelTransformer
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package execute(Package _package) {
		checkState(!_package.name.nullOrEmpty)
		
		val lowlevelPackage = _package.transform // This does not transform components anymore
		// Interfaces are not transformed, the events are transformed (thus, "instantiated") when referred
		for (statechart : _package.components.filter(StatechartDefinition)) {
			lowlevelPackage.components += statechart.transform
		}
		
		return lowlevelPackage
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package transform(Package _package) {
		return transformer.execute(_package)
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transform(StatechartDefinition statechart) {
		return statechart.execute
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package transformAndWrap(StatechartDefinition statechart) {
		val gammaPackage = statechart.containingPackage
		
		// Always a new Package (traced because of potential type declaration transformations)
		val lowlevelPackage = gammaPackage.createAndTracePackage
		lowlevelPackage.components += statechart.transform
		
		return lowlevelPackage
	}
	
	//
	
	def getTrace() {
		return transformer.getTrace
	}
	
}
