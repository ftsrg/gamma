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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class VariableDeclarationTransformer {
	// Trace needed for variable references
	protected final Trace trace
	protected final extension ExpressionTransformer expressionTransformer
	// Auxiliary objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension AnnotationTransformer annotationTransformer = AnnotationTransformer.INSTANCE
	
	
	new(Trace trace) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(this.trace)
	}
	
	def transformParameterDeclaration(ParameterDeclaration lowlevelParameter) {
		val xStsParameter = lowlevelParameter.clone
		trace.put(lowlevelParameter, xStsParameter) // Tracing
		return xStsParameter
	}
	
	def transformVariableDeclaration(VariableDeclaration lowlevelVariable) {
		val xStsVariable = createVariableDeclaration => [
			it.name = lowlevelVariable.name.variableName
			it.type = lowlevelVariable.type.transformType
		]
		for (lowlevelAnnotation : lowlevelVariable.annotations) {
			xStsVariable.annotations += lowlevelAnnotation.transform
		}
		trace.put(lowlevelVariable, xStsVariable) // Tracing
		return xStsVariable
	}
	
	def transformVariableDeclarationAndInitialExpression(VariableDeclaration lowlevelVariable) {
		val xStsVariable = lowlevelVariable.transformVariableDeclaration
		xStsVariable.expression = lowlevelVariable.expression?.transformExpression
		return xStsVariable
	}
	
	
}