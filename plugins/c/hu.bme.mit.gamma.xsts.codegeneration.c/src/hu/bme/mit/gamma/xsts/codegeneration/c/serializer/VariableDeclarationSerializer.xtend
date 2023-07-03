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
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference

/**
 * Serializer for variable declarations.
 */
class VariableDeclarationSerializer {
	
	/**
	 * Transforms a string with underscores to camel case by converting each word's first letter
	 * after an underscore to uppercase.
	 *
	 * @param input the string to transform
	 * @return the transformed string in camel case
	 */
	def String transformString(String input) {
  		val parts = input.split("_")
  		val transformedParts = parts.map [ it.toFirstUpper ]
  		return transformedParts.join("_")
	}

	/**
	 * Converts a string to title case by capitalizing the first letter.
	 *
	 * @param input the string to convert
	 * @return the converted string in title case
	 */
	def static String toFirstUpper(String input) {
  		return input.substring(0,1).toUpperCase + input.substring(1)
	}
	
	/**
   	 * Throws an IllegalArgumentException since the Type class is not supported.
     * 
     * @param type the Type object to serialize
     * @param clock true if the variable is being used in timeout events
     * @param name the name of the variable declaration
     * @return nothing, an exception is thrown
     * @throws IllegalArgumentException always
     */
	def dispatch String serialize(Type type, boolean clock, String name) {
		throw new IllegalArgumentException("Not supported type: " + type);
	}
	
	/**
     * Serializes the TypeReference object by calling the serialize method on the referenced type.
     * 
     * @param type the TypeReference object to serialize
     * @param clock true if the variable is being used in timeout events
     * @param name the name of the variable declaration
     * @return the serialized type reference as a string
     */
	def dispatch String serialize(TypeReference type, boolean clock, String name) {
		return '''«type.reference.type.serialize(clock, type.reference.name)»''';
	}
	
	/**
     * Serializes the BooleanTypeDefinition object as 'bool'.
     * 
     * @param type the BooleanTypeDefinition object to serialize
     * @param clock true if the variable is being used in timeout events
     * @param name the name of the variable declaration
     * @return the serialized boolean type as a string
     */
	def dispatch String serialize(BooleanTypeDefinition type, boolean clock, String name) {
		return '''bool''';
	}
	
	/**
     * Serializes the IntegerTypeDefinition object as 'int'.
     * 
     * @param type the IntegerTypeDefinition object to serialize
     * @param clock true if the variable is being used in timeout events
     * @param name the name of the variable declaration
     * @return the serialized integer type as a string
     */
	def dispatch String serialize(IntegerTypeDefinition type, boolean clock, String name) {
		return clock ? '''unsigned int''' : '''int''';
	}
	
	/**
     * Serializes the DecimalTypeDefinition object as 'float'.
     * 
     * @param type the DecimalTypeDefinition object to serialize
     * @param clock true if the variable is being used in timeout events
     * @param name the name of the variable declaration
     * @return the serialized decimal type as a string
     */
	def dispatch String serialize(DecimalTypeDefinition type, boolean clock, String name) {
		return '''float''';
	}
	
	/**
     * Serializes the RationalTypeDefinition object as 'float'.
     * 
     * @param type the RationalTypeDefinition object to serialize
     * @param clock true if the variable is being used in timeout events
     * @param name the name of the variable declaration
     * @return the serialized rational type as a string
     */
	def dispatch String serialize(RationalTypeDefinition type, boolean clock, String name) {
		return '''float''';
	}
	
	/**
     * Serializes the EnumerationTypeDefinition object as an enum with the transformed name.
     * 
     * @param type the EnumerationTypeDefinition object to serialize
     * @param clock true if the variable is being used in timeout events
     * @param name the name of the variable declaration
     * @return the serialized enum name as a string
     */
	def dispatch String serialize(EnumerationTypeDefinition type, boolean clock, String name) {
		return '''enum «transformString(name)»''';
	}
	
}