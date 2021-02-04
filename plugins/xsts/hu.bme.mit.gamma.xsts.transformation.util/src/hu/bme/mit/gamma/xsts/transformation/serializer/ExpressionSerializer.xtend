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
package hu.bme.mit.gamma.xsts.transformation.serializer

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.DivExpression
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ModExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.xsts.model.PrimedVariable

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XSTSDerivedFeatures.*

class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer
	protected new() {}
	//
	
	override String _serialize(ElseExpression expression) {
		// No op, this cannot be transformed on this level
		throw new IllegalArgumentException("Cannot be transformed")
	}
	
	override String _serialize(IfThenElseExpression expression) '''(if «expression.condition.serialize» then «expression.then.serialize» else «expression.^else.serialize»)'''
	
	override String _serialize(EnumerationLiteralExpression expression) '''«expression.reference.name»'''
	
	override String _serialize(ModExpression expression) '''(«expression.leftOperand.serialize» % «expression.rightOperand.serialize»)'''
	
	override String _serialize(DivExpression expression) '''(«expression.leftOperand.serialize» / «expression.rightOperand.serialize»)'''
	
	override String _serialize(NotExpression expression) '''(«super._serialize(expression)»)'''
	
	override String _serialize(DirectReferenceExpression expression) {
		val declaration = expression.declaration
		if (declaration instanceof PrimedVariable) {
			return '''next(«declaration.originalVariable.name»)'''
		}
		return '''«declaration.name»'''
	}
	
}