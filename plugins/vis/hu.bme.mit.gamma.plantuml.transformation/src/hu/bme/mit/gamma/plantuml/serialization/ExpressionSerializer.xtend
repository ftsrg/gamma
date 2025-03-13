/********************************************************************************
 * Copyright (c) 2024-2025 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.plantuml.serialization

import hu.bme.mit.gamma.expression.model.RecordLiteralExpression

class ExpressionSerializer extends hu.bme.mit.gamma.statechart.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer();
	protected new() {}
	//
	
	override _serialize(RecordLiteralExpression expression) {
		val fields = expression.fieldAssignments
		val DELIMETER = fields.size < 2 ? '' : '\\n'
		val INDENT = (fields.size > 1) ? "\t" : ""
		return '''# {«FOR field : fields BEFORE DELIMETER + INDENT SEPARATOR ',' + DELIMETER + INDENT AFTER DELIMETER»«
			field.reference.fieldDeclaration.name» := «field.value.serialize»«ENDFOR»}'''
	}
}