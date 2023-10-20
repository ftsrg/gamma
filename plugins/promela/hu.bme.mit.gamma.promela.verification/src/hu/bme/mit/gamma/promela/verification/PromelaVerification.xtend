/********************************************************************************
 * Copyright (c) 2022-2023 Contributors to the Gamma project
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

class PromelaVerification extends AbstractVerification {
	// Singleton
	public static final PromelaVerification INSTANCE = new PromelaVerification
	protected new() {}
	//
	
	override protected getTraceabilityFileName(String fileName) {
		return fileName.unfoldedPackageFileName
	}
	
	protected override createVerifier() {
		return new PromelaVerifier
	}
	
	override getDefaultArguments() {
		val MAX_DEPTH = 350000
		return #[
//			"-search -a -b" // default: -a search for acceptance cycles, -b bounded search mode, makes it an error to exceed the search depth, triggering and error trail
			'''-search -n -I -m«MAX_DEPTH» -w32 -DVECTORSZ=6144''',
//			'''-search -i -m«MAX_DEPTH» -w32 -DVECTORSZ=4096'''
			 '''-search -n -bfs -DVECTORSZ=6144'''
		]
		// -A apply slicing algorithm
		// -m Changes the semantics of send events. Ordinarily, a send action will be (blocked) if the target message buffer is full. With this option a message sent to a full buffer is lost.
		// -b bounded search mode, makes it an error to exceed the search depth, triggering and error trail
		// -I like -i, but approximate and faster
		// -i search for shortest path to error (causes an increase of complexity)
		// -n no listing of unreached states at the end of the run
		// -PN for models with embedded C code, reproduce trail, but print only steps from the process with pid N
	}
	
	protected override String getArgumentPattern() {
		return "(-([A-Za-z])*([0-9])*(=)?([0-9])*( )*)*"
	}
	
}