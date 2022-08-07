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
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory

class PackageTransformer {
	// Low-level statechart model factory
	protected final extension StatechartModelFactory factory = StatechartModelFactory.eINSTANCE
	// Trace object for storing the mappings
	protected final Trace trace

	new(Trace trace) {
		this(trace, true, 10)
	}

	new(Trace trace, boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
	}

	def hu.bme.mit.gamma.statechart.lowlevel.model.Package transformPackage(Package _package) {
		if (trace.isMapped(_package)) {
			// It is already transformed
			return trace.get(_package)
		}
		val lowlevelPackage = _package.createAndTracePackage
		// Transforming other type declarations in ExpressionTransformer during variable transformation
		// Not transforming imports as it is unnecessary (Traces.getLowlevelPackage would not work either)
		return lowlevelPackage
	}
	
	protected def createAndTracePackage(Package _package) {
		val lowlevelPackage = createPackage => [
			it.name = _package.name
		]
		trace.put(_package, lowlevelPackage) // Saving in trace
		
		return lowlevelPackage
	}
		
}