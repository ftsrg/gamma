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
package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.querygenerator.serializer.UppaalPropertySerializer

class UppaalVerification extends AbstractUppaalVerification {
	// Singleton
	public static final UppaalVerification INSTANCE = new UppaalVerification
	protected new() {}
	//
	
	override protected getTraceabilityFileName(String fileName) {
		return fileName.gammaUppaalTraceabilityFileName
	}
	
	protected override createVerifier() {
		return new UppaalVerifier
	}
	
	override getDefaultArguments() {
		return #[ "-C -T -t0" ]
	}
	
	override protected createPropertySerializer() {
		return UppaalPropertySerializer.INSTANCE
	}

}
