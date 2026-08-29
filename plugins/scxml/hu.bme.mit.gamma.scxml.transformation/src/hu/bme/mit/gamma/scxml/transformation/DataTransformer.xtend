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
package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlDataType
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import java.util.logging.Level

class DataTransformer extends AtomicElementTransformer {
	
	new(StatechartTraceability traceability) {
		super(traceability)
	}

	// Note: the type of the parameter declaration is inferred from the provided expr of the <data> element.
	def ParameterDeclaration transformParameter(ScxmlDataType scxmlData) {
		logger.log(Level.INFO, "Transforming <data> element (" + scxmlData + ")")
		
		val id = scxmlData.id
		val expr = scxmlData.expr
		val expression = expressionLanguageParser.parse(expr, traceability.variables)
		val type = expressionTypeDeterminator.getType(expression)
		
		val gammaDeclaration = createParameterDeclaration(type, id);
		
		traceability.put(scxmlData, gammaDeclaration)
		
		return gammaDeclaration
	}
	
	def VariableDeclaration transformVariable(ScxmlDataType scxmlData) {
		logger.log(Level.INFO, "Transforming <data> element (" + scxmlData + ")")
		
		val id = scxmlData.id
		val expr = scxmlData.expr
		val expression = expressionLanguageParser.parse(expr, traceability.variables)
		val type = expressionTypeDeterminator.getType(expression)
		
		val gammaDeclaration = createVariableDeclaration(type, id, expression);
		
		traceability.put(scxmlData, gammaDeclaration)
		
		return gammaDeclaration
	}
	
}