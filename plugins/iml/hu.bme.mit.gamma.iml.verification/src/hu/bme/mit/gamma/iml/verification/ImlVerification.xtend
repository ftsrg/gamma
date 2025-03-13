/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.iml.verification

import hu.bme.mit.gamma.querygenerator.serializer.ImlPropertySerializer
import hu.bme.mit.gamma.verification.util.AbstractVerification
import java.io.File

class ImlVerification extends AbstractVerification {
	// Singleton
	public static final ImlVerification INSTANCE = new ImlVerification
	protected new() {}
	//
	
	override protected getTraceabilityFileName(String fileName) {
		return fileName.unfoldedPackageFileName
	}
	
	protected override createVerifier() {
		return new ImlVerifier
	}
	
	//
	
	override getDefaultArgumentsForInvarianceChecking(File modelFile) {
		return defaultArgumentsForInvarianceChecking
	}
	
	override getDefaultArgumentsForInvarianceChecking() {
		return defaultArguments
	}
	
	override getDefaultArguments(File modelFile) {
		return getDefaultArguments
	}
	
	override getDefaultArguments() { // ~upto:100, ~upto_bound:10
		return #[
			"" // Basic BMC with a predefined bound
//			"[@@auto]" // Induction - works only for verify calls?
			]
	}
	
	//
	
	override protected getArgumentPattern() {
		return ".*" // TODO
	}
	
	override protected createPropertySerializer() {
		return ImlPropertySerializer.INSTANCE
	}
	
}