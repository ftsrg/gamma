/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.uppaal.util.TypeTransformer
import hu.bme.mit.gamma.xsts.model.XSTS
import java.util.List
import uppaal.NTA
import uppaal.declarations.ValueIndex

import static extension de.uni_paderborn.uppaal.derivedfeatures.UppaalModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.util.XstsNamings.*

class VariableTransformer {
	
	protected final NTA nta
	protected final Traceability traceability
	
	protected final extension NtaBuilder ntaBuilder
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension TypeTransformer typeTransformer
	
	new (NtaBuilder ntaBuilder, Traceability traceability) {
		this.ntaBuilder = ntaBuilder
		this.nta = ntaBuilder.nta
		this.traceability = traceability
		this.typeTransformer = new TypeTransformer(nta)
		this.expressionTransformer = new ExpressionTransformer(traceability)
	}
	
	protected def transformVariables(XSTS xSts) {
		for (xStsVariable : xSts.variableDeclarations) {
			xStsVariable.transformAndTraceVariable
		}
	}
	
	protected def transformAndTraceVariable(VariableDeclaration variable) {
		val uppaalVariable = variable.transformVariable
		nta.globalDeclarations.declaration += uppaalVariable
		traceability.put(variable, uppaalVariable)
		return uppaalVariable
	}
	
	protected def transformVariable(VariableDeclaration variable) {
		val type = variable.type
		val uppaalType =
		if (variable.clock) {
			nta.clock.createTypeReference
		}
		else if (variable.scheduledClock) {
			// Clock integers
			"0".createLiteralExpression.createRange(
				"65535".createLiteralExpression) // 16 bits
		}
		else {
			type.transformType
		}
		val uppaalVariable = uppaalType.createVariable(variable.uppaalId)
		// In UPPAAL, array sizes are stuck to variables
		uppaalVariable.onlyVariable.index += type.transformArrayIndexes
		
		return uppaalVariable
	}
	
	protected def List<ValueIndex> transformArrayIndexes(Type type) {
		val indexes = newArrayList
		val typeDefinition = type.typeDefinition
		if (typeDefinition instanceof ArrayTypeDefinition) {
			val size = typeDefinition.size
			val elementType = typeDefinition.elementType
			indexes += size.transform.createIndex
			indexes += elementType.transformArrayIndexes
		}
		return indexes
	}
	
	//
	
	protected def transformAndTraceParameter(ParameterDeclaration parameter) {
		val uppaalVariable = parameter.transformParameter
		nta.globalDeclarations.declaration += uppaalVariable
		traceability.put(parameter, uppaalVariable)
		return uppaalVariable
	}
	
	protected def transformParameter(ParameterDeclaration parameter) {
		val type = parameter.type
		val uppaalType = type.transformType
		val uppaalVariable = uppaalType.createVariable(parameter.uppaalId)
		// In UPPAAL, array sizes are stuck to variables
		uppaalVariable.onlyVariable.index += type.transformArrayIndexes
		
		return uppaalVariable
	}
	
}