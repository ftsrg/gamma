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
package hu.bme.mit.gamma.xsts.ocra.transformation;

import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.XorExpression

class ExpressionSerializer extends hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer.ExpressionSerializer{
	
	override String _serialize(TrueExpression expression) '''true'''
	
	override String _serialize(FalseExpression expression) '''false'''
	
	override String _serialize(DirectReferenceExpression expression) '''«expression.declaration.name»'''
	
	override String _serialize(IntegerLiteralExpression expression) '''«expression.getValue.toString»'''
	
	override String _serialize(RationalLiteralExpression expression) ''''''
	
	override String _serialize(OrExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' or '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(XorExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' xor '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(AndExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' and '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(ImplyExpression expression) '''(«expression.leftOperand.serialize» -> «expression.rightOperand.serialize»)''' //??

	override String _serialize(EqualityExpression expression) '''(«expression.leftOperand.serialize» = «expression.rightOperand.serialize»)''' //??

	override String _serialize(IfThenElseExpression expression) '''((«expression.condition.serialize») ? («expression.then.serialize») : («expression.^else.serialize»))'''	
	
}