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
package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.statechart.interface_.Component

class NuxmvQueryGenerator extends ThetaQueryGenerator {
	//
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	//
	new(Component component) {
		super(component)
	}
	
	// nuXmv returns array values like this "b[1][2]" and here we need only "b"
	
	override getSourceVariable(String id) {
		val bracketLessId = id.bracketLessId
		return super.getSourceVariable(bracketLessId)
	}
	
	override getSourceVariableFieldHierarchy(String id) {
		val bracketLessId = id.bracketLessId
		return super.getSourceVariableFieldHierarchy(bracketLessId)
	}
	
	override getSourceOutEventParameterFieldHierarchy(String id) {
		val bracketLessId = id.bracketLessId
		return super.getSourceOutEventParameterFieldHierarchy(bracketLessId)
	}
	
	override getSynchronousSourceInEventParameterFieldHierarchy(String id) {
		val bracketLessId = id.bracketLessId
		return super.getSynchronousSourceInEventParameterFieldHierarchy(bracketLessId)
	}
	
	override getAsynchronousSourceMessageQueue(String id) {
		val bracketLessId = id.bracketLessId
		return super.getAsynchronousSourceMessageQueue(bracketLessId)
	}
	
	override getAsynchronousSourceInEventParameter(String id) {
		val bracketLessId = id.bracketLessId
		return super.getAsynchronousSourceInEventParameter(bracketLessId)
	}
	
	override getAsynchronousSourceInEventParameterFieldHierarchy(String id) {
		val bracketLessId = id.bracketLessId
		return super.getAsynchronousSourceInEventParameterFieldHierarchy(bracketLessId)
	}
	
}