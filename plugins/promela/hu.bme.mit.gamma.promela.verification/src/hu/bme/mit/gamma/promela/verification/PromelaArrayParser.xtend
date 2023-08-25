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

import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.theta.verification.XstsArrayParser
import hu.bme.mit.gamma.xsts.promela.transformation.util.Namings
import java.util.List
import java.util.Map
import java.util.Set
import java.util.regex.Pattern

import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

class PromelaArrayParser implements XstsArrayParser {
	// Singleton
	public static final PromelaArrayParser INSTANCE = new PromelaArrayParser
	protected static Map<String, String> enumMapping
	
	protected new() {}

	override List<Pair<IndexHierarchy, String>> parseArray(String id, String value) {
		if (id.isArray(value)) { // If value is an array, it contains at least 1 " = "
			var values = newArrayList
			val arrayElements = value.split(Pattern.quote("|"))
			for (element : arrayElements) {
				val splitPair = element.split(" = ")
				val splitAccess = splitPair.get(0)
				val splitValue = splitPair.get(1).checkValue
				val access = splitAccess.replaceFirst(id, "") // ArrayAccess
				val splitIndices = access.split(Namings.arrayFieldAccess) // [0] [1] ...
				var indexHierarchy = new IndexHierarchy
				for (splitIndex : splitIndices) {
					val parsedIndex = Integer.parseInt(splitIndex.unwrap) // unwrap index [0] -> 0
					indexHierarchy.add(parsedIndex)
				}
				values += indexHierarchy -> splitValue
			}
			return values
		}
		else {
			val newValue = value.checkValue
			return #[new IndexHierarchy -> newValue]
		}
	}
	
	protected def String checkValue(String key) {
		val value = enumMapping.get(key)
		if (value === null) {
			return key
		}
		else {
			return value
		}
	}

	override boolean isArray(String id, String value) {
		return value.contains(" = ")
	}

	protected def unwrap(String index) {
		return index.substring(1, index.length - 1)
	}
	
	static def createMapping(Set<TypeDeclaration> typeDeclarations) {
		enumMapping = typeDeclarations.createEnumMapping
	}
}