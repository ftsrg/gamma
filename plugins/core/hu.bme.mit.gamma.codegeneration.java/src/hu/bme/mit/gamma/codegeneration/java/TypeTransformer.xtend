/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.codegeneration.java

import hu.bme.mit.gamma.codegeneration.java.util.TypeSerializer
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.Type

class TypeTransformer {
	
	public final String INT_TYPE = "int" // Long cannot be passed as an Object then recast to int
	
	protected final extension Trace trace
	
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	
	new(Trace trace) {
		this.trace = trace
	}
	
	def Trace getTrace(){
		return trace;
	}
	
//	/**
//	 * Returns the Java type of the given Yakindu type as a string.
//	 */
//	def getEventParameterType(org.yakindu.base.types.Type type) {
//		if (type !== null) {
//			return type.name.transformType
//		}
//		return ""
//	}
	
	/**
	 * Returns the Java type equivalent of the Yakindu type.
	 */
	def transformType(String type) {
		switch (type) {
			case "integer": 
				return INT_TYPE
			case "string": 
				return "String"
			case "real": 
				return "double"
			default:
				return type
		}
	}
	
	/**
	 * Returns the Java type equivalent of the Gamma type.
	 */
	def String transformType(Type type) {
		switch (type) {
			IntegerTypeDefinition: {
//				val types = type.getAllValuesOfFrom.filter(org.yakindu.base.types.Type).toSet
//				val strings = types.filter[it.name.equals("string")]
//				val integers = types.filter[it.name.equals("integer")]
//				if (strings.size > 0 && integers.size > 0) {
//					throw new IllegalArgumentException("Integers and string mapped to the same integer type: " + type)
//				}
//				if (strings.size > 0) {
//					return "string"
//				}
//				else {
					return INT_TYPE 
//				}
			}
			default:
				return type.serialize
		}
	}
}