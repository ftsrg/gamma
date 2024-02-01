/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.txsts.transformation.serializer

import hu.bme.mit.gamma.expression.model.ScheduledClockVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.xsts.model.PrimedVariable
import hu.bme.mit.gamma.xsts.model.XSTS

class DeclarationSerializer extends hu.bme.mit.gamma.xsts.transformation.serializer.DeclarationSerializer{
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	protected new() {}
	
	override String serializeDeclarations(XSTS xSts, boolean serializePrimedVariables) '''
		«FOR typeDeclaration : xSts.typeDeclarations»
					«typeDeclaration.serializeTypeDeclaration»
		«ENDFOR»
		«FOR variableDeclaration : xSts.variableDeclarations
				.filter[serializePrimedVariables || !(it instanceof PrimedVariable)]»
			«variableDeclaration.serializeVariableDeclaration»
		«ENDFOR»
	'''

	
	override String serializeVariableDeclaration(VariableDeclaration variable) {
		for (annotation : variable.annotations) {
			if (annotation instanceof ScheduledClockVariableDeclarationAnnotation) {
				return '''var «variable.name» : clock'''
			} 
		}
		return super.serializeVariableDeclaration(variable)
	}
}