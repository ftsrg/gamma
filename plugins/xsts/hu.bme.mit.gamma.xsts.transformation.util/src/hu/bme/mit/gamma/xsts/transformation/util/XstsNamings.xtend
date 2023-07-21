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
package hu.bme.mit.gamma.xsts.transformation.util

class XstsNamings {
	
	static def String getTypeName(String lowlevelName) '''«lowlevelName»'''
	static def String getEnumLiteralName(String lowlevelName) '''«lowlevelName»'''
	static def String getVariableName(String lowlevelName) '''«lowlevelName»'''
	static def String getEventName(String lowlevelName) '''«lowlevelName»'''
	
	static def String getStateEnumLiteralName(String lowlevelName) '''«lowlevelName»'''
	static def String getStateInactiveHistoryEnumLiteralName(String lowlevelName) '''«lowlevelName»_Inactive_'''
	static def String getRegionTypeName(String lowlevelName) '''«lowlevelName.toFirstUpper»'''
	static def String getRegionVariableName(String lowlevelName) '''«lowlevelName.toFirstLower»'''
	
	// SSA
	static def String getPrimedVariableNameInInitTransition(String xStsName, int index) '''«xStsName»_init_«index»'''
	static def String getPrimedVariableNameInInoutTransition(String xStsName, int index) '''«xStsName»_inout_«index»'''
	static def String getPrimedVariableNameInTransition(String xStsName, int transitionIndex, int index)
		'''«xStsName»_tran_«transitionIndex»_«index»'''
		
	static def String getOriginalNameOfPrimedVariableNameInInoutTransition(String xStsName, int index) {
		val length = xStsName.length
		val differenceInLength = xStsName.getPrimedVariableNameInInoutTransition(index).length - length
		val originalName = xStsName.substring(0, length - differenceInLength)
		return originalName
	}
	//
	
}