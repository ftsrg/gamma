/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.util.ExpressionTypeDeterminator
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer
	protected new() {}
	//
	protected final extension ExpressionTypeDeterminator typeDeterminator = ExpressionTypeDeterminator.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	
	override String _serialize(EnumerationLiteralExpression expression) '''«expression.reference.name»'''
	
	override String serialize(Expression expression) {
		return super.serialize(expression)
	}
	
	override String _serialize(TrueExpression expression) '''TRUE'''

	override String _serialize(FalseExpression expression) '''FALSE'''
	
	override String _serialize(OrExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' | '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(XorExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' xor '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(AndExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' & '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(ImplyExpression expression) '''(«expression.leftOperand.serialize» -> «expression.rightOperand.serialize»)'''

	override String _serialize(EqualityExpression expression) '''(«expression.leftOperand.serialize» = «expression.rightOperand.serialize»)'''

	override String _serialize(IfThenElseExpression expression) '''((«expression.condition.serialize») ? («expression.then.serialize») : («expression.^else.serialize»))'''

	override String _serialize(ArrayAccessExpression arrayAccessExpression) '''READ(«arrayAccessExpression.operand.serialize», «arrayAccessExpression.index.serialize»)'''
	
	override String _serialize(ArrayLiteralExpression expression) {
		val operands = expression.operands
		val typeDefinition = expression.typeDefinition as ArrayTypeDefinition
		val smvType = typeDefinition.serializeType
		
		val defaultExpression = typeDefinition.elementType.defaultExpression
		val smvDefaultValue = defaultExpression.serialize
		
		val smvArrayLiteral = new StringBuilder
		smvArrayLiteral.append('''CONSTARRAY(«smvType», «smvDefaultValue»)''')
		
		val evaluatedDefaultExpression = defaultExpression.evaluate
		if (operands.forall[it.helperEquals(defaultExpression) || it.isEvaluable && it.evaluate == evaluatedDefaultExpression]) {
			return smvArrayLiteral.toString // No need for WRITE commands
		}
		
		for (var i = 0; i < operands.size; i++) {
			val operand = operands.get(i)
			smvArrayLiteral.insert(0, '''WRITE(''') // Prepend
			smvArrayLiteral.append(''', «i», «operand.serialize»)''')
		} 
		
		return smvArrayLiteral.toString
	}
	
}