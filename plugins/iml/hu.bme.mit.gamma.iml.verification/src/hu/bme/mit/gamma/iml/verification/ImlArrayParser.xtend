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

import hu.bme.mit.gamma.theta.verification.XstsArrayParser

class ImlArrayParser implements XstsArrayParser {
	// Singleton
	public static final ImlArrayParser INSTANCE = new ImlArrayParser
	protected new() {}
	//
	
	override parseArray(String id, String value) {
		throw new UnsupportedOperationException
	}
	
	override isArray(String id, String value) {
		throw new UnsupportedOperationException
	}
	
}