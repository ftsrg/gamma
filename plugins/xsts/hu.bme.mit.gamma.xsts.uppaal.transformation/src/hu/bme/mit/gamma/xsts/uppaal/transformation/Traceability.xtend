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
import hu.bme.mit.gamma.xsts.model.XSTS
import java.util.Map
import uppaal.NTA
import uppaal.declarations.VariableContainer

class Traceability {
	
	final XSTS xSts
	final NTA nta
	
	final Map<VariableDeclaration, VariableContainer> variables = newHashMap
	
	new(XSTS xSts, NTA nta) {
		this.xSts = xSts
		this.nta = nta 
	}
	
	// Variables
	
	def put(VariableDeclaration xStsVariable, VariableContainer uppaalVariable) {
		variables.put(xStsVariable, uppaalVariable)
	}
	
	def isMapped(VariableDeclaration xStsVariable) {
		variables.containsKey(xStsVariable)
	}
	
	def get(VariableDeclaration xStsVariable) {
		variables.get(xStsVariable)
	}
	
	// Roots
	
	def getXSts() {
		return this.xSts
	}
	
	def getNta() {
		return this.nta
	}
	
}