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
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.uppaal.util.TypeTransformer
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.OrthogonalAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XSTS
import uppaal.NTA

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XSTSDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.uppaal.transformation.Namings.*

class XSTSToUppaalTransformer {
	
	protected final XSTS xSts
	protected final Traceability traceability
	protected final NTA nta
	// Auxiliary
	protected final extension NtaBuilder ntaBuilder
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension TypeTransformer typeTransformer
	
	new(XSTS xSts) {
		this.xSts = xSts
		this.ntaBuilder = new NtaBuilder(xSts.name, false)
		this.nta = ntaBuilder.nta
		this.traceability = new Traceability(xSts, nta)
		this.expressionTransformer = new ExpressionTransformer(traceability)
		this.typeTransformer = new TypeTransformer(nta)
	}
	
	def execute() {
		val initialLocation = createTemplateWithInitLoc(templateName, initialLocationName)
		val initializingAction = xSts.initializingAction
		val environmentalAction = xSts.environmentalAction
		val mergedAction = xSts.mergedAction
		
		xSts.transformVariables
		
		return ntaBuilder.nta
	}
	
	protected def transformVariables(XSTS xSts) {
		for (xStsVariable : xSts.variableDeclarations) {
			val uppaalVariable = xStsVariable.transformVariable
			nta.globalDeclarations.declaration += uppaalVariable
			traceability.put(xStsVariable, uppaalVariable)
		}
	}
	
	protected def transformVariable(VariableDeclaration variable) {
		val uppaalType = variable.type.transformType
		val uppaalVariable = uppaalType.createVariable(variable.uppaalId)
		return uppaalVariable
	}
	
	protected def dispatch transformAction(AssignmentAction action) {
		
	}
	
	protected def dispatch transformAction(AssumeAction action) {
		
	}
	
	protected def dispatch transformAction(SequentialAction action) {
		
	}
	
	protected def dispatch transformAction(OrthogonalAction action) {
		
	}
	
	protected def dispatch transformAction(NonDeterministicAction action) {
		
	}
	
	protected def void optimize() {
		// Empty edges
		// Subsequent edges with only updates
	}
	
}