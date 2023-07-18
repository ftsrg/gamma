/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.nuxmv.verification

import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File

class NuxmvVerification extends AbstractVerification {
	// Singleton
	public static final NuxmvVerification INSTANCE = new NuxmvVerification
	protected new() {}
	
	override Result execute(File modelFile, File queryFile, String[] arguments) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new NuxmvVerifier
		val argument = arguments.head
		
		argument.sanitizeArgument
		
		return verifier.verifyQuery(gammaPackage, argument, modelFile, queryFile)
	}
	
	override getDefaultArguments() {
		return #['check_ltlspec_ic3']
	}
	
	override protected getArgumentPattern() {
		return ".*" // TODO
	}
	
}