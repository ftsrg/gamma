/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.statechart.interface_.Component

class DeadlockCheckPostprocessor extends StateCheckPostprocessor {
	
	new(Component originalTopComponent) {
		super(originalTopComponent)
	}
	
	protected override selectState(StateFormula property) {  // G (state a -> G(!outoing_transition1_id && ...))
		return super.selectState(property) // Returns the first reference
	}
	
}