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

import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.DivideExpression
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.expression.model.ModExpression
import hu.bme.mit.gamma.expression.model.MultiplyExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression
import hu.bme.mit.gamma.expression.model.SubtractExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.expression.model.impl.DirectReferenceExpressionImpl
import hu.bme.mit.gamma.xsts.codegeneration.c.CodeBuilder
import hu.bme.mit.gamma.xsts.codegeneration.c.util.GeneratorUtil

/**
 * Serializer for expressions in the C code generation.
 */
class ExpressionSerializer {
	
	/**
	 * The ExpressionSerializer class provides methods for serializing expressions.
	 * This class is intended for serialization purposes.
	 */
	public static val ExpressionSerializer INSTANCE = new ExpressionSerializer
	
	/**
	 * Constructs a new instance of the ExpressionSerializer class.
	 * This constructor is marked as protected to prevent direct instantiation.
	 */
	protected new() {
	}
	
	val VariableDeclarationSerializer variableDeclarationSerializer = VariableDeclarationSerializer.INSTANCE
	
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
     * Serializes the given ElseExpression.
     * 
     * @param expression the ElseExpression to serialize
     * @return the serialized ElseExpression as a string
     * @throws IllegalArgumentException if the expression cannot be transformed
     */
	def dispatch String serialize(ElseExpression expression) {
		throw new IllegalArgumentException("Cannot be transformed")
	}
	
	/**
     * Serializes the given DirectReferenceExpression.
     * 
     * @param expression the DirectReferenceExpression to serialize
     * @return the serialized DirectReferenceExpression as a string
     */
	def dispatch String serialize(DirectReferenceExpression expression) {
		val declaration = expression.declaration
		if (CodeBuilder.componentVariables.contains(declaration.name)) {
			return '''statechart->«declaration.name»'''
		}
		return declaration.name
	}
	
	/**
     * Serializes the given EnumerationLiteralExpression.
     * 
     * @param expression the EnumerationLiteralExpression to serialize
     * @return the serialized EnumerationLiteralExpression as a string
     */
	def dispatch String serialize(EnumerationLiteralExpression expression) {
		val definition = expression.reference;
		val enumerationType = definition.eContainer as EnumerationTypeDefinition
		val typeDeclaration = enumerationType.eContainer as TypeDeclaration
		return definition.name + "_" + typeDeclaration.name.toLowerCase
	}
	
	/**
     * Serializes the given IntegerLiteralExpression.
     * 
     * @param expression the IntegerLiteralExpression to serialize
     * @return the serialized IntegerLiteralExpression as a string
     */
	def dispatch String serialize(IntegerLiteralExpression expression) {
		return expression.value.toString
	}
	
	/**
     * Serializes the given DecimalLiteralExpression.
     * 
     * @param expression the DecimalLiteralExpression to serialize
     * @return the serialized DecimalLiteralExpression as a string
     */
	def dispatch String serialize(DecimalLiteralExpression expression) {
		return expression.value.toString
	}
	
	/**
     * Serializes the given RationalLiteralExpression.
     * 
     * @param expression the RationalLiteralExpression to serialize
     * @return the serialized RationalLiteralExpression as a string
     */
	def dispatch String serialize(RationalLiteralExpression expression) {
		return '''(((float) «expression.numerator.toString») / «expression.denominator.toString»)'''
	}
	
	/**
     * Serializes the given TrueExpression.
     * 
     * @param expression the TrueExpression to serialize
     * @return the serialized TrueExpression as a string
     */
	def dispatch String serialize(TrueExpression expression) {
		return '''true'''
	}
	
	/**
     * Serializes the given FalseExpression.
     * 
     * @param expression the FalseExpression to serialize
     * @return the serialized FalseExpression as a string
     */
	def dispatch String serialize(FalseExpression expression) {
		return '''false'''
	}
	
	/**
     * Serializes the given NotExpression.
     * 
     * @param expression the NotExpression to serialize
     * @return the serialized NotExpression as a string
     */
	def dispatch String serialize(NotExpression expression) {
		return '''!(«expression.operand.serialize»)'''
	}
	
	/**
	 * Serializes the given OrExpression object.
	 * 
	 * @param expression The OrExpression object to serialize.
	 * @return The serialized OrExpression object as a string.
	 */
	def dispatch String serialize(OrExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " || "»«operand.serialize»«ENDFOR»)'''
	}
	
	/**
	 * Serializes the given XorExpression object.
	 * 
	 * @param expression The XorExpression object to serialize.
	 * @return The serialized XorExpression object as a string.
	 */
	def dispatch String serialize(XorExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " ^ "»«operand.serialize»«ENDFOR»)'''
	}
	
	/**
	 * Serializes the given AndExpression object.
	 * 
	 * @param expression The AndExpression object to serialize.
	 * @return The serialized AndExpression object as a string.
	 */
	def dispatch String serialize(AndExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " && "»(«operand.serialize»)«ENDFOR»)'''
	}
	
	/**
	 * Serializes the given ImplyExpression object.
	 * 
	 * @param expression The ImplyExpression object to serialize.
	 * @return The serialized ImplyExpression object as a string.
	 */
	def dispatch String serialize(ImplyExpression expression) {
		return '''(!(«expression.leftOperand.serialize») || «expression.rightOperand.serialize»)'''
	}
	
	/**
	 * Serializes the given IfThenElseExpression object.
	 * 
	 * @param expression The IfThenElseExpression object to serialize.
	 * @return The serialized IfThenElseExpression object as a string.
	 */
	def dispatch String serialize(IfThenElseExpression expression) {
		return '''(«expression.condition.serialize» ? «expression.then.serialize» : «expression.^else.serialize»)'''
	}
	
	/**
	 * Serializes the given EqualityExpression object.
	 * 
	 * @param expression The EqualityExpression object to serialize.
	 * @return The serialized EqualityExpression object as a string.
	 */
	def dispatch String serialize(EqualityExpression expression) {
		return '''(«expression.leftOperand.serialize» == «expression.rightOperand.serialize»)'''
	}
	
	/**
	 * Serializes the given InequalityExpression object.
	 * 
	 * @param expression The InequalityExpression object to serialize.
	 * @return The serialized InequalityExpression object as a string.
	 */
	def dispatch String serialize(InequalityExpression expression) {
		return '''(«expression.leftOperand.serialize» != «expression.rightOperand.serialize» )'''
	}
	
	/**
	 * Serializes the given GreaterExpression object.
	 * 
	 * @param expression The GreaterExpression object to serialize.
	 * @return The serialized GreaterExpression object as a string.
	 */
	def dispatch String serialize(GreaterExpression expression) {
		return '''(«expression.leftOperand.serialize» > «expression.rightOperand.serialize»)'''
	}
	
	/**
	 * Serializes the given GreaterEqualExpression object.
	 * 
	 * @param expression The GreaterEqualExpression object to serialize.
	 * @return The serialized GreaterEqualExpression object as a string.
	 */
	def dispatch String serialize(GreaterEqualExpression expression) {
		return '''(«expression.leftOperand.serialize» >= «expression.rightOperand.serialize»)'''
	}
	
	/**
	 * Serializes the given LessExpression object.
	 * 
	 * @param expression The LessExpression object to serialize.
	 * @return The serialized LessExpression object as a string.
	 */
	def dispatch String serialize(LessExpression expression) {
		return '''(«expression.leftOperand.serialize» < «expression.rightOperand.serialize»)'''
	}
	
	/**
	 * Serializes the given LessEqualExpression object.
	 * 
	 * @param expression The LessEqualExpression object to serialize.
	 * @return The serialized LessEqualExpression object as a string.
	 */
	def dispatch String serialize(LessEqualExpression expression) {
		return '''(«expression.leftOperand.serialize» <= «expression.rightOperand.serialize»)'''
	}
	
	/**
	 * Serializes an AddExpression into a string representation.
	 * 
	 * @param expression the AddExpression to serialize
	 * @return the string representation of the AddExpression
	 */
	def dispatch String serialize(AddExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " + "»«operand.serialize»«ENDFOR»)'''
	}
	
	/**
	 * Serializes a SubtractExpression into a string representation.
	 * 
	 * @param expression the SubtractExpression to serialize
	 * @return the string representation of the SubtractExpression
	 */
	def dispatch String serialize(SubtractExpression expression) {
		return '''(«expression.leftOperand.serialize» - «expression.rightOperand.serialize»)'''
	}
	
	/**
	 * Serializes a MultiplyExpression into a string representation.
	 * 
	 * @param expression the MultiplyExpression to serialize
	 * @return the string representation of the MultiplyExpression
	 */
	def dispatch String serialize(MultiplyExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " * "»«operand.serialize»«ENDFOR»)'''
	}
	
	/**
	 * Serializes a DivideExpression into a string representation.
	 * 
	 * @param expression the DivideExpression to serialize
	 * @return the string representation of the DivideExpression
	 */
	def dispatch String serialize(DivideExpression expression) {
		return '''(«expression.leftOperand.serialize» / «expression.rightOperand.serialize»)'''
	}
	
	/**
	 * Serializes a ModExpression into a string representation.
	 * 
	 * @param expression the ModExpression to serialize
	 * @return the string representation of the ModExpression
	 */
	def dispatch String serialize(ModExpression expression) {
		return '''(«expression.leftOperand.serialize» % «expression.rightOperand.serialize»)'''
	}
	
	/**
	 * Serializes an UnaryPlusExpression into a string representation.
	 * 
	 * @param expression the UnaryPlusExpression to serialize
	 * @return the string representation of the UnaryPlusExpression
	 */
	def dispatch String serialize(UnaryPlusExpression expression) {
		return '''+«expression.operand.serialize»'''
	}
	
	/**
	 * Serializes an UnaryMinusExpression into a string representation.
	 * 
	 * @param expression the UnaryMinusExpression to serialize
	 * @return the string representation of the UnaryMinusExpression
	 */
	def dispatch String serialize(UnaryMinusExpression expression) {
		return '''-«expression.operand.serialize»'''
	}
	
	/**
	 * Serializes an array access expression into a string representation.
	 *
	 * @param expression the array access expression to be serialized
	 * @return a serialized representation of the array access expression
	 */
	def dispatch String serialize(ArrayAccessExpression expression) {
		return '''«expression.operand.serialize»[«expression.index.serialize»]'''
	}
	
	/**
	 * Serializes an array literal expression into a string representation.
	 *
	 * @param expression the array literal expression to be serialized
	 * @return a serialized representation of the array literal expression
	 */
	def dispatch String serialize(ArrayLiteralExpression expression) {
		return '''{«expression.operands.map[it.serialize].join(', ')»}'''
	}
	
	/**
	 * Serialize an ArrayAccessExpression and an ArrayLiteralExpression into String.
	 *
	 * @param access the ArrayAccessExpression to be serialized
	 * @param literal the ArrayLiteralExpression to be serialized
	 * @return a String representing an array access
	 */
	def dispatch String serialize(ArrayAccessExpression access, ArrayLiteralExpression literal) {
		val bgd = (access.operand as DirectReferenceExpressionImpl).basicGetDeclaration as VariableDeclaration
		val type = GeneratorUtil.getArrayType(bgd.type as ArrayTypeDefinition, bgd.annotations.exists[it instanceof ClockVariableDeclarationAnnotation], bgd.name)
		return '''
			«type» temp«access.hashCode»«GeneratorUtil.getLiteralSize(literal)» = «literal.serialize»;
			memcpy(«access.serialize», temp«access.hashCode», sizeof(«access.serialize»));'''
	}
	
	/**
	 * Serialize a DirectReferenceExpression and an ArrayLiteralExpression into String.
	 *
	 * @param reference the DirectReferenceExpression to be serialized
	 * @param literal the ArrayLiteralExpression to be serialized
	 * @return a String representing an array access
	 */
	def dispatch String serialize(DirectReferenceExpressionImpl reference, ArrayLiteralExpression literal) {
		val bgd = reference.basicGetDeclaration as VariableDeclaration
		val type = GeneratorUtil.getArrayType(bgd.type as ArrayTypeDefinition, false, bgd.name)
		val postfix = variableDeclarationSerializer.serialize(bgd.type, bgd.annotations.exists[it instanceof ClockVariableDeclarationAnnotation], bgd.name)
		return '''
			«type» temp«reference.hashCode»«postfix» = «literal.serialize»;
			memcpy(«reference.serialize», temp«reference.hashCode», sizeof(«reference.serialize»));'''
	}
	
}