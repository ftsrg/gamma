/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.xsts.promela.transformation.util.Namings

class PromelaPropertyExpressionSerializer extends ThetaPropertyExpressionSerializer {
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof EnumerationLiteralExpression) {
			return Namings.customizeEnumLiteralName(expression)
		}
		return super.serialize(expression)
	}
	
	//
	
	override protected serializeIfThenElseExpression(IfThenElseExpression expression) {
		return '''(«expression.condition.serialize» -> «expression.then.serialize» : «expression.^else.serialize»)'''
	}
	
}