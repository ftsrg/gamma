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
package hu.bme.mit.gamma.uppaal.serializer

import uppaal.declarations.ArrayInitializer
import uppaal.declarations.CallType
import uppaal.declarations.ChannelVariableDeclaration
import uppaal.declarations.ClockVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.ExpressionInitializer
import uppaal.declarations.TypeIndex
import uppaal.declarations.ValueIndex
import uppaal.expressions.ArithmeticExpression
import uppaal.expressions.ArrayLiteralExpression
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.AssignmentOperator
import uppaal.expressions.BitShiftExpression
import uppaal.expressions.BitwiseExpression
import uppaal.expressions.CompareExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.ConditionExpression
import uppaal.expressions.Expression
import uppaal.expressions.FunctionCallExpression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.IncrementDecrementExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.expressions.MinusExpression
import uppaal.expressions.NegationExpression
import uppaal.expressions.PlusExpression
import uppaal.expressions.ScopedIdentifierExpression
import uppaal.statements.Block
import uppaal.statements.EmptyStatement
import uppaal.statements.ExpressionStatement
import uppaal.statements.ForLoop
import uppaal.statements.IfStatement
import uppaal.statements.Iteration
import uppaal.statements.ReturnStatement
import uppaal.statements.Statement
import uppaal.templates.Selection
import uppaal.types.DeclaredType
import uppaal.types.PredefinedType
import uppaal.types.RangeTypeSpecification
import uppaal.types.StructTypeSpecification
import uppaal.types.Type
import uppaal.types.TypeReference

class ExpressionTransformer {
	
	// Serializing expressions
	
	def static dispatch String transform(Expression expression) {
		throw new IllegalArgumentException("Not know expression: " + expression)
	}
	
	def static dispatch String transform(ArrayLiteralExpression expression) {
		return '''{ «FOR element : expression.elements SEPARATOR ', '»«element.transform»«ENDFOR» }'''
	}
	
	def static dispatch String transform(LiteralExpression expression) {
		return expression.text
	}
	
	def static dispatch String transform(IdentifierExpression expression) '''«expression.identifier.name»«FOR index : expression.index»[«index.transform»]«ENDFOR»'''
	
	def static dispatch String transform(ScopedIdentifierExpression expression) '''«expression.scope.transform».«expression.identifier.transform»'''
	
	def static dispatch String transform(AssignmentExpression expression) {
		return expression.firstExpr.transform + " " + expression.operator.transformAssignmentOperator + " " + expression.secondExpr.transform
	}
	
	private def static transformAssignmentOperator(AssignmentOperator operator) {
		switch (operator) {
			case AssignmentOperator.BIT_AND_EQUAL: 
				return "&amp;="
			case AssignmentOperator.BIT_LEFT_EQUAL: 
				return "&lt;&lt;="
			case AssignmentOperator.BIT_RIGHT_EQUAL: 
				return "&gt;&gt;="
			default: 
				return operator.literal
		}
	}
	
	def static dispatch String transform(NegationExpression expression) {
		return "!(" + expression.negatedExpression.transform + ")"
	}
	
	def static dispatch String transform(PlusExpression expression) {
		return "+" +  expression.confirmedExpression.transform
	}
	
	def static dispatch String transform(MinusExpression expression) {
		return "-" +  expression.invertedExpression.transform
	}
	
	def static dispatch String transform(ConditionExpression expression) {
		return "(" + expression.ifExpression.transform + " ? " + expression.thenExpression.transform + " : " + expression.elseExpression.transform + ")"
	}
	
	def static dispatch String transform(ArithmeticExpression expression) {
		return "(" + expression.firstExpr.transform + " " + expression.operator.literal + " " + expression.secondExpr.transform + ")"
	}
	
	def static dispatch String transform(LogicalExpression expression) {
		return "(" + expression.firstExpr.transform + " " + expression.operator.transformLogicalOperator + " " + expression.secondExpr.transform + ")"
	}
	
	private def static transformLogicalOperator(LogicalOperator operator) {
		switch (operator) {
			case LogicalOperator.AND: 
				return "&amp;&amp;"
			case LogicalOperator.OR: 
				return "||"
			case LogicalOperator.XOR: 
				return "^"
			default: 
				throw new IllegalArgumentException("The following operator is not supported: " + operator)
		}
	}
	
	def static dispatch String transform(CompareExpression expression) {
		return "(" + expression.firstExpr.transform + " " + expression.operator.transformCompareOperator + " " + expression.secondExpr.transform + ")"
	}
	
	private def static transformCompareOperator(CompareOperator operator) {
		switch (operator) {				
			case CompareOperator.LESS: 
				return "&lt;"
			case CompareOperator.LESS_OR_EQUAL: 
				return "&lt;="
			case CompareOperator.GREATER: 
				return "&gt;"
			case CompareOperator.GREATER_OR_EQUAL_VALUE: 
				return "&gt;="
			default: 
				return operator.literal
		}
	}
	
	def static dispatch String transform(IncrementDecrementExpression expression) {
		if (expression.position.value == 0) {
			return expression.operator.literal + expression.expression.transform
		}
		else {
			return expression.expression.transform + expression.operator.literal
		}
	}
	
	def static dispatch String transform(BitShiftExpression expression) {
		return "(" + expression.firstExpr.transform + " " + expression.operator.literal + " " + expression.secondExpr.transform + ")"
	}
	
	def static dispatch String transform(BitwiseExpression expression) {
		return "(" + expression.firstExpr.transform + " " + expression.operator.literal + " " + expression.secondExpr.transform + ")"
	}
	
	def static dispatch String transform(FunctionCallExpression expression) '''«expression.function.name»(«FOR argument : expression.argument SEPARATOR ", "»«argument.transform»«ENDFOR»)'''
	
	// Serializing selections
	
	def static serialize(Selection select) '''«FOR variable : select.variable»«variable.name»«ENDFOR» : «select.typeDefinition.serializeTypeDefinition»'''
	
	// Serializing statements
	
	def static dispatch String transformStatement(Statement statement) {
		throw new IllegalArgumentException("The transformation of this statement is not supported: " + statement)
	}
	
	def static dispatch String transformStatement(ForLoop forLoop) '''
		for («forLoop.initialization.transform»; «forLoop.condition.transform»; «forLoop.iteration.transform») {
			«forLoop.statement.transformStatement»
		}
	'''
	
	def static dispatch String transformStatement(Iteration iteration) '''
		for («iteration.variable.head.name» : «iteration.typeDefinition.serializeTypeDefinition») {
			«iteration.statement.transformStatement»
		}
	'''
	
	def static dispatch String transformStatement(IfStatement statement) '''
		if («statement.ifExpression.transform») «statement.thenStatement.transformStatement»
		«IF statement.elseStatement !== null»
			else «statement.elseStatement.transformStatement»
		«ENDIF»
	'''
	
	def static dispatch String transformStatement(Block block) '''
		{
			«IF block.declarations !== null»
				«FOR declaration : block.declarations.declaration.filter(DataVariableDeclaration)»
					«declaration.serializeVariable»
				«ENDFOR»
			«ENDIF»
			«FOR statement: block.statement»
				«statement.transformStatement»
			«ENDFOR»
		}
	'''
	
	def static dispatch String transformStatement(ExpressionStatement statement) '''«statement.expression.transform»;'''
	
	def static dispatch String transformStatement(ReturnStatement statement) '''return «IF statement.returnExpression !== null»«statement.returnExpression.transform»«ENDIF»;'''
	
	def static dispatch String transformStatement(EmptyStatement statement) '''{ /* Empty */ }'''
	
	// Serializing types
		
	def dispatch static serializeType(Type type) {
		throw new IllegalArgumentException("The transformation of this type is not supported: " + type)		
	}
	
	def dispatch static serializeType(PredefinedType type) {
		type.type.literal
	}
	
	def dispatch static serializeType(DeclaredType type) {
		type.name
	}
	
	def dispatch static String serializeTypeDefinition(TypeReference typeReference) '''«typeReference.referredType.serializeType»'''
	
	def dispatch static String serializeTypeDefinition(StructTypeSpecification typeSpec) '''«FOR declaration : typeSpec.declaration»«declaration.serializeVariable»«ENDFOR»'''
	
	def dispatch static String serializeTypeDefinition(RangeTypeSpecification rangeSpec) '''int[«rangeSpec.bounds.lowerBound.transform», «rangeSpec.bounds.upperBound.transform»]'''
	
	// Serializing declarations
	
	def dispatch static serializeVariable(DataVariableDeclaration declaration) '''
		«declaration.prefix.serializePrefix»«declaration.typeDefinition.serializeTypeDefinition» «FOR variable : declaration.variable SEPARATOR ", "»«variable.name»«FOR index : variable.index»«index.serializeIndex»«ENDFOR»«IF variable.initializer !== null» = «variable.initializer.serializeInitializer»«ENDIF»«ENDFOR»;
	'''
	
	def dispatch static serializeVariable(ClockVariableDeclaration declaration) '''
		«declaration.typeDefinition.serializeTypeDefinition» «FOR variable : declaration.variable SEPARATOR ", "»«variable.name»«ENDFOR»;
	'''
	
	def dispatch static serializeVariable(ChannelVariableDeclaration declaration) '''
		«IF declaration.isBroadcast»broadcast «ENDIF»«IF declaration.isUrgent»urgent «ENDIF»«declaration.typeDefinition.serializeTypeDefinition» «FOR variable : declaration.variable SEPARATOR ", "»«variable.name»«ENDFOR»;
	'''
	
	// Serializing initializers
	
	def dispatch static String serializeInitializer(ExpressionInitializer initializer) '''«initializer.expression.transform»'''
	
	def dispatch static String serializeInitializer(ArrayInitializer initializer) '''{«FOR exprInit: initializer.initializer SEPARATOR ", "»«exprInit.serializeInitializer»«ENDFOR»}'''
	
	// Serializing indexes
	
	def dispatch static serializeIndex(ValueIndex index) '''[«index.sizeExpression.transform»]'''
	
	def dispatch static serializeIndex(TypeIndex index) '''[«index.typeDefinition.serializeTypeDefinition»]'''
	
	// Serializing enums
	
	def static serializePrefix(DataVariablePrefix prefix) {
		switch (prefix) {
			case NONE:
				return ""
			case CONST:
				return "const "
			case META:
				return "meta "
			default:
				throw new IllegalArgumentException("This prefix is not supported: " + prefix)			
		}
	}
	
	def static serializeCallType(CallType callType) {
		switch (callType) {
			case CALL_BY_VALUE:
				return ""
			case CALL_BY_REFERENCE:
				return "&"
			default:
				throw new IllegalArgumentException("This call type is not supported: " + callType)			
		}
	}
	
}