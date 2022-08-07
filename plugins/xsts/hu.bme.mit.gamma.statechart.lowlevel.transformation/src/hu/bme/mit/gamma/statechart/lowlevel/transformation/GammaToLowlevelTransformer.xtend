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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition

import static com.google.common.base.Preconditions.checkState
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

import hu.bme.mit.gamma.statechart.ActivityComposition.ActivityDefinition

class GammaToLowlevelTransformer {	
	protected final Trace trace = new Trace
	
	protected final extension PackageTransformer pTransformer = new PackageTransformer(trace)
	protected final extension StatechartToLowlevelTransformer scTransformer = new StatechartToLowlevelTransformer(trace)
	protected final extension ActivityToLowlevelTransformer aTransformer = new ActivityToLowlevelTransformer(trace)
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package execute(Package _package) {
		checkState(!_package.name.nullOrEmpty)
		
		val lowlevelPackage = _package.transformPackage // This does not transform components anymore
		// Interfaces are not transformed, the events are transformed (thus, "instantiated") when referred
		for (activity : _package.components.filter(ActivityDefinition)) {
			lowlevelPackage.components += activity.transformComponent
		}
		for (statechart : _package.components.filter(StatechartDefinition)) {
			lowlevelPackage.components += statechart.transformComponent
		}
		
		return lowlevelPackage
	}
	
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package transform(Package _package) {
		return _package.transformPackage
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transform(StatechartDefinition statechart) {
		return statechart.transformComponent as hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.ActivityDefinition transform(ActivityDefinition activity) {
		return activity.transformComponent as hu.bme.mit.gamma.statechart.lowlevel.model.ActivityDefinition
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package transformAndWrap(StatechartDefinition statechart) {
		val gammaPackage = statechart.containingPackage
		
		// Always a new Package (traced because of potential type declaration transformations)
		val lowlevelPackage = gammaPackage.createAndTracePackage
		lowlevelPackage.components += statechart.transformComponent
		
		return lowlevelPackage
	}
	
}
