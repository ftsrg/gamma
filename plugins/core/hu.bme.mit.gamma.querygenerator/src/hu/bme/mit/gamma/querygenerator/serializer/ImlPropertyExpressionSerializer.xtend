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
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*

class ImlPropertyExpressionSerializer extends ThetaPropertyExpressionSerializer {
	//
	protected final extension ExpressionTypeDeterminator2 typeDeterminator = ExpressionTypeDeterminator2.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	//
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	override String _serialize(TrueExpression expression) '''true'''

	override String _serialize(FalseExpression expression) '''false'''
	
	override String _serialize(NotExpression expression) '''(not («expression.operand.serialize»))'''
	
	override String _serialize(ImplyExpression expression) '''(«expression.leftOperand.serialize» ==> «expression.rightOperand.serialize»)'''
	
	override String _serialize(XorExpression expression) '''(«FOR operand : expression.operands SEPARATOR " <> "»«operand.serialize»«ENDFOR»)'''
	
	override String _serialize(EqualityExpression expression) '''(«expression.leftOperand.serialize» = «expression.rightOperand.serialize»)'''
	
	override String _serialize(InequalityExpression expression) '''(«expression.leftOperand.serialize» <> «expression.rightOperand.serialize»)'''
	
	override String _serialize(IfThenElseExpression expression) '''(if «expression.condition.serialize» then «expression.then.serialize» else «expression.^else.serialize»)'''

	override String _serialize(EnumerationLiteralExpression expression) '''«expression.typeReference.reference.serializeName».«expression.serializeName»''' // See module elements when serializing type declarations
	
	override String _serialize(DirectReferenceExpression expression) {
		val declaration = expression.declaration
		return '''«declaration.id».«declaration.serializeName»'''
	}
	
	override String _serialize(ArrayAccessExpression arrayAccessExpression) '''(Map.get «arrayAccessExpression.index.serialize» «arrayAccessExpression.operand.serialize»)'''
	
	override String _serialize(ArrayLiteralExpression expression) {
		val operands = expression.operands
		val typeDefinition = expression.typeDefinition as ArrayTypeDefinition
		
		val defaultExpression = typeDefinition.elementType.defaultExpression
		val imlDefaultValue = defaultExpression.serialize
		
		var imlArrayLiteral = '''(Map.const «imlDefaultValue»)'''
		
		if (!defaultExpression.typeDefinition.array) {
			val evaluatedDefaultExpression = defaultExpression.evaluate
			if (operands.forall[it.helperEquals(defaultExpression) || it.evaluable && it.evaluate == evaluatedDefaultExpression]) {
				return imlArrayLiteral.toString // No need for Map.add commands
			}
		}
		
		for (var i = 0; i < operands.size; i++) {
			val operand = operands.get(i)
			imlArrayLiteral = '''(Map.add «i» «operand.serialize» «imlArrayLiteral»)'''
		} 
		
		return imlArrayLiteral
	}
	
	//
	
	def String serializeName(Declaration declaration) {
		val customizedName = (declaration.local) ?
			declaration.customizeLocalDeclarationName : // To avoid having the same names in different record types
			declaration.customizeName
		return customizedName
	}
	
	def String serializeName(TypeDeclaration declaration) {
		val customizedName = declaration.customizeName
		return customizedName
	}
	
	def String serializeName(EnumerationLiteralExpression literal) {
		val customizedName = literal.customizeName
		return customizedName
	}
	
	def String serializeName(EnumerationLiteralDefinition literal) {
		val customizedName = literal.customizeName
		return customizedName
	}
	
	//
	
	def getId(Declaration declaration) {
		return ImlReferenceSerializer.recordIdentifier
	}
	
}