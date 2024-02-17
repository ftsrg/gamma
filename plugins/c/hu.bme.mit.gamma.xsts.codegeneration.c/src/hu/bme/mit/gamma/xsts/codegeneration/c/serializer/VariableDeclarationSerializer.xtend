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

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition
import hu.bme.mit.gamma.expression.model.impl.ArrayTypeDefinitionImpl
import hu.bme.mit.gamma.xsts.codegeneration.c.util.GeneratorUtil
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import java.math.BigInteger

import static extension hu.bme.mit.gamma.xsts.codegeneration.c.util.GeneratorUtil.*

/**
 * Serializer for variable declarations.
 */
class VariableDeclarationSerializer {
	
	public static val UINT32_MAX = new BigInteger("4294967295")
	
	/**
	 * The VariableDeclarationSerializer class provides methods for serializing variable declarations.
	 * This class is intended for serialization purposes.
	 */
	public static val INSTANCE = new VariableDeclarationSerializer
	
	/**
	 * Constructs a new instance of the VariableDeclarationSerializer class.
	 * This constructor is marked as protected to prevent direct instantiation.
	 */
	protected new() {
	}
	
	val ExpressionSerializer expressionSerializer = new ExpressionSerializer
	
	/**
	 * Serialize a Declaration into a String.
	 *
	 * @param declaration the Declaration to be serialized
	 * @return throws an exception.
	 * @throws IllegalArgumentException if the provided declaration is not supported
	 */
	def dispatch String serialize(Declaration declaration) {
		throw new IllegalArgumentException("Not supported declaration: " + declaration)
	}
	
	/**
	 * Serializes a variable declaration into a String.
	 *
	 * @param declaration the variable declaration to serialize.
	 * @return the serialized variable declaration as a String.
	 */
	def dispatch String serialize(VariableDeclaration declaration) {
		val rhs = declaration.eContainer instanceof VariableDeclarationAction
		val clock = declaration.annotations.exists[it instanceof ClockVariableDeclarationAnnotation]
		val vtype = (declaration.type instanceof ArrayTypeDefinitionImpl) ? GeneratorUtil.getArrayType(declaration.type as ArrayTypeDefinition, clock, declaration.name) : serialize(declaration.type, clock, declaration.name)
		val postfix = (declaration.type instanceof ArrayTypeDefinitionImpl) ? serialize(declaration.type, clock, declaration.name) : ""
		return '''«vtype» «declaration.name»«postfix»«IF rhs» = «expressionSerializer.serialize(declaration.expression)»«ENDIF»;'''
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
		throw new IllegalArgumentException("Not supported type: " + type)
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
		return '''«type.reference.type.serialize(clock, type.reference.name)»'''
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
		return '''bool'''
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
		val size = (type.eContainer instanceof VariableDeclaration && type.eContainer.eContainer instanceof XSTS) ? new BigInteger((type.eContainer as VariableDeclaration).getInitialValueEvaluated(type.eContainer.eContainer as XSTS).toString) : UINT32_MAX
		val unsigned = (size > UINT32_MAX) ? 'uint64_t' : 'uint32_t'
		return clock ? unsigned : '''int32_t'''
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
		return '''float'''
	}
	
	/**
     * Serializes the VoidTypeDefinition object as 'void'.
     * 
     * @param type the VoidTypeDefinition object to serialize
     * @param clock true if the variable is being used in timeout events
     * @param name the name of the variable declaration
     * @return the serialized void type as a string
     */
	def dispatch String serialize(VoidTypeDefinition type, boolean clock, String name) {
		return '''void'''
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
		return '''float'''
	}
	
	/**
	 * Serializes an array of the specified type.
	 *
	 * @param type the type definition of the array
	 * @param clock true if the variable is being used in timeout events
	 * @param name the name of the array
	 * @return a serialized representation of the array
	 */
	def dispatch String serialize(ArrayTypeDefinition type, boolean clock, String name) {
		val inner = type.elementType instanceof ArrayTypeDefinitionImpl
		return '''[«expressionSerializer.serialize(type.size)»]«IF inner»«type.elementType.serialize(clock, name)»«ENDIF»'''
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
		return '''enum «name.transformString»'''
	}
	
}