/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File

class PromelaVerification extends AbstractVerification {
	// Singleton
	public static final PromelaVerification INSTANCE = new PromelaVerification
	protected new() {}
	
	protected final extension PromelaQueryAdapter promelaQueryAdapter = PromelaQueryAdapter.INSTANCE
	
	override Result execute(File modelFile, File queryFile, String[] arguments) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new PromelaVerifier
		val argument = arguments.head
		
		argument.sanitizeArgument
		
		return verifier.verifyQuery(gammaPackage, argument, modelFile, queryFile)
	}
	
	override getDefaultArguments() {
		return #[
//			 "-search -a -b" // default
			 "-search -a -b -m10000000 -DVECTORSZ=4096" // recommended for models with ParallelAction
		]
	}
	
	protected override String getArgumentPattern() {
		return "(-([A-Za-z])*([0-9])*(=)?([0-9])*( )*)*"
	}
}