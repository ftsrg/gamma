/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.codegeneration.c.serializer

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference

/**
 * Serializes different types of definitions and expressions into their string representation.
 * Supports boolean, integer, decimal, rational, and enumeration types.
 * Also supports direct reference expressions.
 */
class HavocSerializer {
	
	/**
	 * The HavocSerializer class provides methods for serializing Havoc-related components.
	 * This class is intended for serialization purposes.
	 */
	public static val HavocSerializer INSTANCE = new HavocSerializer
	
	/**
	 * Constructs a new instance of the HavocSerializer class.
	 * This constructor is marked as protected to prevent direct instantiation.
	 */
	protected new() {
	}

	/**
     * Throws an exception for unsupported types.
     *
     * @param type the type to be serialized
     * @param name the name of the type to be serialized
     * @return an exception message for unsupported types
     * @throws IllegalArgumentException if the type is not supported
     */
	def dispatch String serialize(Type type, String name) {
		throw new IllegalArgumentException("Not supported type: " + type)
	}
	
	/**
     * Serializes boolean types into their string representation.
     *
     * @param type the boolean type to be serialized
     * @param name the name of the boolean type to be serialized
     * @return the string representation of the serialized boolean type
     */
	def dispatch String serialize(BooleanTypeDefinition type, String name) {
		return '''havoc_bool()'''
	}
	
	/**
     * Serializes integer types into their string representation.
     *
     * @param type the integer type to be serialized
     * @param name the name of the integer type to be serialized
     * @return the string representation of the serialized integer type
     */
	def dispatch String serialize(IntegerTypeDefinition type, String name) {
		return '''havoc_int()'''
	}
	
	/**
     * Serializes decimal types into their string representation.
     *
     * @param type the decimal type to be serialized
     * @param name the name of the decimal type to be serialized
     * @return the string representation of the serialized decimal type
     */
	def dispatch String serialize(DecimalTypeDefinition type, String name) {
		return '''havoc_float()'''
	}
	
	/**
     * Serializes rational types into their string representation.
     *
     * @param type the rational type to be serialized
     * @param name the name of the rational type to be serialized
     * @return the string representation of the serialized rational type
     */
	def dispatch String serialize(RationalTypeDefinition type, String name) {
		return '''havoc_float()'''
	}
	
	/**
     * Serializes enumeration types into their string representation.
     *
     * @param type the enumeration type to be serialized
     * @param name the name of the enumeration type to be serialized
     * @return the string representation of the serialized enumeration type
     */
	def dispatch String serialize(TypeReference type, String name) {
		return '''havoc_«type.reference.name»()'''
	}
	
	/**
     * Serializes the given expression.
     * 
     * @param expression the expression to serialize
     * @return the serialized expression as a string
     * @throws IllegalArgumentException if the expression is not supported
     */
	def dispatch String serialize(Expression expression) {
		throw new IllegalArgumentException("Not supported expression: " + expression)
	}
	
	/**
     * Serializes direct reference expressions into their string representation.
     *
     * @param expression the direct reference expression to be serialized
     * @return the string representation of the serialized direct reference expression
     */
	def dispatch String serialize(DirectReferenceExpression expression) {
		return expression.declaration.type.serialize(expression.declaration.name)
	}
	
}