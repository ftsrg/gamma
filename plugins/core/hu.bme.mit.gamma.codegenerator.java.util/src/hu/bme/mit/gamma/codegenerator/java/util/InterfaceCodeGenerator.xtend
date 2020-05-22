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
package hu.bme.mit.gamma.codegenerator.java.util

import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.Interface

import static extension hu.bme.mit.gamma.codegenerator.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class InterfaceCodeGenerator {
	
	final String BASE_PACKAGE_NAME
	final String INTERFACE_PACKAGE_NAME
	
	final extension TypeSerializer typeSerializer = new TypeSerializer
	
	new(String basePackageName) {
		this.BASE_PACKAGE_NAME = basePackageName
		this.INTERFACE_PACKAGE_NAME = basePackageName + "." + Namings.INTERFACE_PACKAGE_POSTFIX
	}
	
	def createInterface(Interface _interface) '''
		package «INTERFACE_PACKAGE_NAME»;
		
		import java.util.List;
		import «BASE_PACKAGE_NAME».*;
		
		public interface «_interface.implementationName» {
		
			interface Provided extends Listener.Required {
				
				«_interface.createInterface(EventDirection.OUT)»
				
				void registerListener(Listener.Provided listener);
				List<Listener.Provided> getRegisteredListeners();
			}
			
			interface Required extends Listener.Provided {
				
				«_interface.createInterface(EventDirection.IN)»
				
				void registerListener(Listener.Required listener);
				List<Listener.Required> getRegisteredListeners();
			}
			
			interface Listener {
				
			interface Provided«IF !_interface.parents.empty» extends «FOR parent : _interface.parents»«parent.implementationName».Listener.Provided«ENDFOR»«ENDIF» {
				«_interface.createListenerInterface(EventDirection.OUT)»
				}
				
			interface Required«IF !_interface.parents.empty» extends «FOR parent : _interface.parents»«parent.implementationName».Listener.Required«ENDFOR»«ENDIF» {
				«_interface.createListenerInterface(EventDirection.IN)»
				}
				
			}
		
		}
	'''
	
	private def createInterface(Interface _interface, EventDirection eventDirection)  {
		val notCorrectDirection = eventDirection.opposite
		'''
			«FOR eventDeclaration : _interface.events.filter[it.direction != notCorrectDirection]»
				boolean isRaised«eventDeclaration.event.name.toFirstUpper»();
				«FOR parameter : eventDeclaration.event.parameterDeclarations»
					«parameter.type.serialize» get«parameter.name.toFirstUpper»();
				«ENDFOR»
			«ENDFOR»
		'''
	}
	
	private def createListenerInterface(Interface _interface, EventDirection eventDirection) {
		val notCorrectDirection = eventDirection.opposite
		'''
			«FOR eventDeclaration : _interface.allEventDeclarations.filter[it.direction != notCorrectDirection]»
				void raise«eventDeclaration.event.name.toFirstUpper»(«FOR parameter : eventDeclaration.event.parameterDeclarations SEPARATOR ", "»«parameter.type.serialize» «parameter.name»«ENDFOR»);
			«ENDFOR»
		'''
	}
	
}