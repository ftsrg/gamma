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
package hu.bme.mit.gamma.ocra.verification

import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File

class OcraVerifier extends AbstractVerifier {
	//
	public static final String SET_OCRA_TIMED = "set ocra_timed 1"
	//
	
	override verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getHelpCommand() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getUnavailableBackendMessage() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getAnalysisLanguage() {
		return "OCRA"
	}
	
}