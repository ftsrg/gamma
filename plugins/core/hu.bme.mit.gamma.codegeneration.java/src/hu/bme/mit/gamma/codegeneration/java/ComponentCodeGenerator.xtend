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
package hu.bme.mit.gamma.codegeneration.java

import hu.bme.mit.gamma.statechart.interface_.Component

class ComponentCodeGenerator {
	
	protected final extension EventDeclarationHandler gammaEventDeclarationHandler
	protected final extension TypeTransformer typeTransformer
	
	new(Trace trace) {
		this.gammaEventDeclarationHandler = new EventDeclarationHandler(trace)
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	/**
	 * Generates fields for parameter declarations
	 */
	def generateParameterDeclarationFields(Component component) '''
		«IF !component.parameterDeclarations.empty»// Fields representing parameters«ENDIF»
		«FOR parameter : component.parameterDeclarations»
			private final «parameter.type.transformType» «parameter.name»;
		«ENDFOR»
	'''
	
}