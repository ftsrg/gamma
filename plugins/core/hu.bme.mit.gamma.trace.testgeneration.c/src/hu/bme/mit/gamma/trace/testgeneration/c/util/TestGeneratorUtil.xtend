/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.testgeneration.c.util

import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.InjectedVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.impl.ArrayLiteralExpressionImpl
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.trace.model.Act
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.testgeneration.c.TypeSerializer
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2

class TestGeneratorUtil {
	
	static val TypeSerializer typeSerializer = new TypeSerializer
	
	static def String getArrayType(EObject expression) {
		if (expression instanceof ArrayLiteralExpressionImpl)
			return expression.operands.head.arrayType
		return '''«typeSerializer.serialize(expression as Expression, "")»'''
	}
	
	static def String getArraySize(EObject array) {
		if (array instanceof ArrayLiteralExpressionImpl)
			return '''[«array.operands.size»]«array.operands.head.arraySize»'''
		return ""
	}
	
	static def int getArraySizeSum(EObject object) {
		if (!(object instanceof ArrayLiteralExpressionImpl))
			return 1;
		val array = object as ArrayLiteralExpressionImpl
		return array.operands.size * array.operands.head.arraySizeSum
	}
	
	static def boolean containsElapse(List<Act> actions) {
		return actions.stream.anyMatch[it instanceof TimeElapse]
	}
	
	static def String getRealization(Port port) {
		switch(port.interfaceRealization.realizationMode) {
		case PROVIDED:
			return 'Out'
		case REQUIRED:
			return 'In'
		default:
			return 'In'
		}
	}
	
	static def boolean isNecessary(Expression expression) {
		val variables = EcoreUtil2.getAllContentsOfType(expression, ComponentInstanceVariableReferenceExpression).filter[it.variableDeclaration.annotations.stream.anyMatch[it instanceof InjectedVariableDeclarationAnnotation]]
		if (EcoreUtil2.getAllContentsOfType(expression, ComponentInstanceVariableReferenceExpression).size > 0)
			return false
		return true
	}
	
	static def boolean containsArray(Expression expression) {
		return EcoreUtil2.getAllContentsOfType(expression, ArrayLiteralExpressionImpl).size > 0
	}
	
	static def String getTestMethod(Expression expression) {
		if (expression.containsArray)
			return "TEST_ASSERT_EQUAL_INT_ARRAY"
		return "TEST_ASSERT_TRUE"
	}
	
	static def String getTestParameter(Expression expression) {
		if (expression.containsArray)
			return ''', «expression.arraySizeSum»'''
		return ''''''
	}
	
	static def boolean isComplexArray(Expression expression) {
		return expression.eContainer instanceof ArrayLiteralExpression
	}
		
}