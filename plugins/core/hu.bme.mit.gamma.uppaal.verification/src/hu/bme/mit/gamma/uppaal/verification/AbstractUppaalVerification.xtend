/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.verification.util.AbstractVerification

abstract class AbstractUppaalVerification extends AbstractVerification {
	
	protected override getArgumentPattern() {
		return "((-A|-C|-H[0-9]*|-n[0-4]|-o[0-4]|-S[0-2]|-T|-Z|-N|-t[0-2])( )?)*"
	}
	
	protected override createVerifier() {
		return new UppaalVerifier
	}
	
	override getDefaultArguments() {
		return #[ "-C -t0" ]
//		-C Difference Bound Matrix
//		-Z Bit-state hashing. Under-approximates states.
//		-A Convex-hull approximation. Over-approximates states.

//		-T Reuse state space.
	}
	
}