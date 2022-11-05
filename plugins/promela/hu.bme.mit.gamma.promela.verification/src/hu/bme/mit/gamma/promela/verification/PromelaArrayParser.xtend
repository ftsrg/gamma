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

import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.theta.verification.XstsArrayParser
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.promela.transformation.util.Namings
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List
import java.util.regex.Pattern

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

class PromelaArrayParser implements XstsArrayParser{
	// Singleton
	public static final PromelaArrayParser INSTANCE = new PromelaArrayParser
	protected static final extension XstsActionUtil xstsActionUtil = XstsActionUtil.INSTANCE
	
	protected static XSTS xsts
	
	protected new() {}

	override List<Pair<IndexHierarchy, String>> parseArray(String id, String value) {
		if (value.isArray) { // If value is an array, it contains at least 1 " = "
			var values = newArrayList
			val arrayElements = value.split(Pattern.quote("|"))
			for (element : arrayElements) {
				val splitPair = element.split(" = ")
				val splitAccess = splitPair.get(0)
				val splitValue = id.checkArrayValue(splitPair.get(1))
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
			val newValue = id.checkValue(value)
			return #[new IndexHierarchy -> newValue]
		}
	}
	
	protected def checkArrayValue(String id, String value) {
		val variable = xsts.checkVariable(id)
		if (variable.type.arrayElementType instanceof EnumerationTypeDefinition) {
			return variable.customizeEnumLiteralNameInverse(value)
		}
		return value
	}
	
	protected def checkValue(String id, String value) {
		val variable = xsts.checkVariable(id)
		if (variable.type.typeDefinition instanceof EnumerationTypeDefinition) {
			return variable.customizeEnumLiteralNameInverse(value)
		}
		return value
	}

	protected def boolean isArray(String value) {
		return value.contains(" = ")
	}

	protected def unwrap(String index) {
		return index.substring(1, index.length - 1)
	}
}