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

import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.theta.verification.XstsArrayParser

class NuxmvArrayParser implements XstsArrayParser {
	// Singleton
	public static final NuxmvArrayParser INSTANCE = new NuxmvArrayParser
	protected new() {}
	//
	
	override parseArray(String id, String value) {
		if (id.isArray(value)) { // If value is an array, it contains at least 1 " [ "
			val splittedId = id.split("[a-zA-Z_]+\\[")
			val tail = splittedId.get(1) // "1][2][3]"
			val valuesWithDelimiter = tail.substring(0, tail.length - 1) // "1][2][3"
			
			val values = valuesWithDelimiter.split("\\]\\[") // 1, 2, 3
			val intValues = values.map[Integer.parseInt(it)].toList
			
			val indexHierarchy = new IndexHierarchy(intValues)
			
			return #[indexHierarchy -> value]
		}
		else {
			return #[new IndexHierarchy -> value]
		}
	}
	
	override isArray(String id, String value) {
		val pattern = ".*\\[[0-9]+\\]+"
		return id.matches(pattern)
	}
	
}