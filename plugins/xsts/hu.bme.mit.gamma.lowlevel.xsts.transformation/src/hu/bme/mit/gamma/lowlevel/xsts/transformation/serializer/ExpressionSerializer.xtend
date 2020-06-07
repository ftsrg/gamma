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
package hu.bme.mit.gamma.lowlevel.xsts.transformation.serializer

import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.xsts.model.model.PrimedVariable

import static extension hu.bme.mit.gamma.xsts.model.derivedfeatures.XSTSDerivedFeatures.*

class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	
	override String _serialize(ElseExpression expression) {
		// No op, this cannot be transformed on this level
		throw new IllegalArgumentException("Cannot be transformed")
	}
	
	override String _serialize(IfThenElseExpression expression) '''(if «expression.condition.serialize» then «expression.then.serialize» else «expression.^else.serialize»)'''
	
	override String _serialize(EnumerationLiteralExpression expression) '''«expression.reference.name»'''
	
	override String _serialize(ReferenceExpression expression) {
		val declaration = expression.declaration
		if (declaration instanceof PrimedVariable) {
			return '''next(«declaration.originalVariable.name»)'''
		}
		return '''«declaration.name»'''
	}
	
}