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
package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ExpressionSerializer extends hu.bme.mit.gamma.codegeneration.java.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer
	protected new() {}
	//
	
	override dispatch String serialize(DirectReferenceExpression expression) {
		val declaration = expression.declaration
		if (declaration instanceof VariableDeclaration) {
			// 'this' is important as without it, the reference would refer to the temporary variable
			// Not needed in the case of local variables though
			val originalVariable = declaration.originalVariable
			return '''«IF !originalVariable.local»this.«ENDIF»«originalVariable.name»'''
		}
		return declaration.name
	}
	
}