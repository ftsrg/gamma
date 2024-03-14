/********************************************************************************
 * Copyright (c) 2021-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.util.IndexHierarchy
import java.util.List

class ThetaArrayParser implements XstsArrayParser {
	// Singleton
	public static final ThetaArrayParser INSTANCE = new ThetaArrayParser
	protected new() {}
	//
	
	override List<Pair<IndexHierarchy, String>> parseArray(String id, String value) {
		// In the case of Theta, id is not relevant
		return value.parseArray
	}
	
	// Not every index is retrieved - if an index is missing, its value is the default value
	protected def List<Pair<IndexHierarchy, String>> parseArray(String value) {
		// (array (0 10) (1 11) (default 0))
		val values = newArrayList
		if ("".isArray(value)) {
			val unwrapped = value.unwrap.substring("array ".length) // (0 10) (default 0)
			val splits = unwrapped.parseAlongParentheses // 0 10, default array
			for (split : splits) {
				val splitPair = split.split(" ") // 0, 10
				val index = splitPair.get(0) // 0
				if (!index.equals("default")) { // Not parsing default values
					val parsedIndex = Integer.parseInt(index) // 0
					val storedValue = splitPair.get(1) // 10
					val parsedValues = storedValue.parseArray
					for (parsedValue : parsedValues) {
						val indexHierarchy = parsedValue.key
						indexHierarchy.prepend(parsedIndex) // So the "parent index" will be retrieved earlier
						val stringValue = parsedValue.value
						values += indexHierarchy -> stringValue
					}
				}
			}
			// Parsing default values if there are no other values in the array
			if (values.empty && unwrapped.startsWith("(default")) {
				val i = value.lastIndexOf("default")
				val defaultValue = value.substring(i + "default".length + 1 /* Space */)
				values += new IndexHierarchy(0) -> defaultValue
			}
			
			return values
		}
		else {
			return #[new IndexHierarchy -> value]
		}
	}
	
	protected def parseAlongParentheses(String line) {
		val result = newArrayList
		var unclosedParanthesisCount = 0
		var firstParanthesisIndex = 0
		for (var i = 0; i < line.length; i++) {
			val character = line.charAt(i).toString
			if (character == "(") {
				unclosedParanthesisCount++
				if (unclosedParanthesisCount == 1) {
					firstParanthesisIndex = i
				}
			}
			else if (character == ")") {
				unclosedParanthesisCount--
				if (unclosedParanthesisCount == 0) {
					result += line.substring(firstParanthesisIndex + 1, i)
				}
			}
		}
		return result
	}
	
	override isArray(String id, String value) {
		return value.startsWith("(array ")
	}
	
	protected def unwrap(String id) {
		return id.substring(1, id.length - 1)
	}
	
}