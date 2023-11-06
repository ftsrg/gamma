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
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.querygenerator.serializer.ThetaPropertySerializer

class ThetaVerification extends AbstractVerification {
	// Singleton
	public static final ThetaVerification INSTANCE = new ThetaVerification
	protected new() {}
	//
	
	override protected getTraceabilityFileName(String fileName) {
		return fileName.unfoldedPackageFileName
	}
	
	protected override createVerifier() {
		return new ThetaVerifier
	}
	
	override getDefaultArguments() {
		return #[
				"",
				"--domain EXPL --refinement SEQ_ITP --maxenum 250 --initprec CTRL",
				"--domain EXPL_PRED_COMBINED --autoexpl NEWOPERANDS --initprec CTRL"
			]
		// --domain PRED_CART --refinement SEQ_ITP // default - cannot be used with loops
		// --domain EXPL --refinement SEQ_ITP --maxenum 250 // --initprec CTRL should be used to support loops
		// --domain EXPL_PRED_COMBINED --autoexpl NEWOPERANDS --initprec CTRL
	}
	
	protected override String getArgumentPattern() {
		return "(--[a-z]+( )[_0-9A-Z]+( )*)*"
	}
	
	override protected createPropertySerializer() {
		return ThetaPropertySerializer.INSTANCE
	}
	
}