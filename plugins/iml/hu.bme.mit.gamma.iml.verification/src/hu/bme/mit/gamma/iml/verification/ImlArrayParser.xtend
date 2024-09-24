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

import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.theta.verification.XstsArrayParser
import java.util.List

import static hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*

class ImlArrayParser implements XstsArrayParser {
	// Singleton
	public static final ImlArrayParser INSTANCE = new ImlArrayParser
	protected new() {}
	//

	override List<Pair<IndexHierarchy, String>> parseArray(String id, String value) {
		if (id.isArray(value)) {
			val values = newArrayList
			var i = 0
			for (element : value
					.substring(1, value.length - 1) // Removing '[' and ']'
					.split(";")
					.map[it.trim]
					.reject[it.nullOrEmpty]) {
				val storedValue = element // 10
				val parsedValues = id.parseArray(storedValue)
				for (parsedValue : parsedValues) {
					val indexHierarchy = parsedValue.key
					indexHierarchy.prepend(i++) // So the "parent index" will be retrieved earlier
					val stringValue = parsedValue.value
					values += indexHierarchy -> stringValue
				}
			}
			// Parsing default values if there are no other values in the array
			if (values.empty) {
//				values += new IndexHierarchy(0) -> "0" // TODO default value
			}
			
			return values
		}
		else {
			val newValue = value.checkValue
			return #[new IndexHierarchy -> newValue]
		}
	}
	
	protected def String checkValue(String value) {
		if (value.contains("\\.")) { // Checking enums
			val typeLiteral = value.split("\\.")
			val literal = typeLiteral.last
			if (literal.startsWith(ENUM_LITERAL_PREFIX)) {
				return literal.substring(ENUM_LITERAL_PREFIX.length)
			}
		}
		return value
	}

	override boolean isArray(String id, String value) {
		return value.startsWith("[")
	}
	
}