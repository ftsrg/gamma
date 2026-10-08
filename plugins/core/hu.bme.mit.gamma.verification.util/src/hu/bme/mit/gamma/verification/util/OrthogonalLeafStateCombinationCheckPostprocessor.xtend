/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class OrthogonalLeafStateCombinationCheckPostprocessor extends OrthogonalStateCombinationCheckPostprocessor {
	
	new(Component originalTopComponent) {
		super(originalTopComponent)
	}
	
	protected override calculateAllOrthogonalStateCombinations(StatechartDefinition statechart) {
		return statechart.allOrthogonalLeafStateCombinations
	}
	
}