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

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*

class ImlArrayParser implements XstsArrayParser {
	// Singleton
	public static final ImlArrayParser INSTANCE = new ImlArrayParser
	protected new() {}
	//

	override List<Pair<IndexHierarchy, String>> parseArray(String id, String value) {
		if (id.isArray(value.trim)) {
			val values = newArrayList
			
			if (value.defaultMapArray) { // (Map.const (Map.const 0))
				var parsedValue = value.deparenthesize // Map.const (Map.const 0)
				val parsableValue = parsedValue.substring(parsedValue.indexOf(" ")).trim // (Map.const 0)
				
				val parsed = id.parseArray(parsableValue)
				parsed.forEach[it.key.prepend(0)] // This index surely exists in the array
				
				values += parsed
			}
			else if (value.mapArray) { // (Map.of_list ~default:(Map.const 0) [(1, (Map.of_list ~default:0 [(0, 736)]))])
				var parsedValue = value.deparenthesize // Map.of_list ~default:(Map.const 0) [(1, (Map.of_list ~default:0 [(0, 736)]))]
				parsedValue = parsedValue.substring(parsedValue.indexOf("[")) // [(1, (Map.of_list ~default:0 [(0, 736)]))]
				for (element : parsedValue
						.substring(1, parsedValue.length - 1) // Removing '[' and ']'
						.split(";")
						.map[it.trim]
						.reject[it.nullOrEmpty]) {
					val split = element.deparenthesize.split(",", 2) // (1, (Map.of_list ~default:0 [(0, 736)]))
					val index = split.head.trim // 1
					val parsableValue = split.lastOrNull.trim // (Map.of_list ~default:0 [(0, 736)])
					
					val intIndex = Integer.parseInt(index)
					val parsed = id.parseArray(parsableValue)
					parsed.forEach[it.key.prepend(intIndex)]
					
					values += parsed
				}
				
				if (values.empty) {
					values += new IndexHierarchy(0) -> "0" // Default value
				}
			}
			else {
				checkState(value.queue)
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
			}
			
			return values
		}
		else {
			val newValue = value.checkValue
			return #[new IndexHierarchy -> newValue]
		}
	}
	
	protected def String checkValue(String value) {
		if (value.contains(".")) { // Checking enums
			val typeLiteral = value.split("\\.")
			val literal = typeLiteral.lastOrNull
			if (literal.startsWith(ENUM_LITERAL_PREFIX)) {
				return literal.substring(ENUM_LITERAL_PREFIX.length)
			}
		}
		return value
	}
	//

	override boolean isArray(String id, String value) {
		return value.defaultMapArray || value.mapArray || value.queue
	}
	
	protected def boolean isMapArray(String value) {
		val mapString = "Map.of_list "
		return value.startsWith("(" + mapString) || value.startsWith(mapString)
	}
	
	protected def boolean isDefaultMapArray(String value) {
		val mapString = "Map.const "
		return value.startsWith("(" + mapString) || value.startsWith(mapString)
	}
	
	protected def boolean isQueue(String value) {
		return value.startsWith("[")
	}
	
	//
	
	protected def deparenthesize(String string) {
		val trim = string.trim
		if (trim.startsWith("(")) {
			return trim.substring(1, string.length - 1).trim
		}
	}
	
}