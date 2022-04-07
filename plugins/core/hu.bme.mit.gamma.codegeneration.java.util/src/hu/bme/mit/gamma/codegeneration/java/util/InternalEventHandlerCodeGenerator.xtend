/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.statechart.interface_.Component

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class InternalEventHandlerCodeGenerator {
	// Singleton
	public static final InternalEventHandlerCodeGenerator INSTANCE = new InternalEventHandlerCodeGenerator
	protected new() {}
	//
	
	def createInternalEventHandlingCode(Component component) '''
		«IF component.hasInternalPort»
			private void handleInternalEvents() {
				«FOR internalPort : component.allInternalPorts»
					«FOR internalEvent : internalPort.internalEvents»
						if («internalPort.name.toFirstLower».isRaised«internalEvent.name.toFirstUpper»()) {
							«internalPort.name.toFirstLower».raise«internalEvent.name.toFirstUpper»(«FOR parameter : internalEvent.parameterDeclarations SEPARATOR ', '»«internalPort.name.toFirstLower».get«parameter.name.toFirstUpper»()«ENDFOR»);
						}
					«ENDFOR»
				«ENDFOR»
			}
		«ENDIF»
	'''
	
}