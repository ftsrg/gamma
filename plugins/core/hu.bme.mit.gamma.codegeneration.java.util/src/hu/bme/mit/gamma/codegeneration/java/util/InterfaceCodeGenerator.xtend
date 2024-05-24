/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface
import java.util.Collections
import java.util.HashSet
import java.util.Set

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class InterfaceCodeGenerator {
	
	final String BASE_PACKAGE_NAME
	
	final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	
	new(String basePackageName) {
		this.BASE_PACKAGE_NAME = basePackageName
	}
	

	
	def createInterface(Interface _interface) '''
		package «_interface.getPackageString(BASE_PACKAGE_NAME)»;
		
		import java.util.List;
		import «BASE_PACKAGE_NAME».*;
		«FOR importedPackage : _interface.containingPackage.imports»
			import «importedPackage.getPackageString(BASE_PACKAGE_NAME)».*;
		«ENDFOR»
		
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
				
			interface Provided«IF !_interface.parents.empty» extends «FOR parent : _interface.parents
						SEPARATOR ', '»«parent.implementationName».Listener.Provided«ENDFOR»«ENDIF» {
				«_interface.createListenerInterface(EventDirection.OUT)»
				}
				
			interface Required«IF !_interface.parents.empty» extends «FOR parent : _interface.parents
						SEPARATOR ', '»«parent.implementationName».Listener.Required«ENDFOR»«ENDIF» {
				«_interface.createListenerInterface(EventDirection.IN)»
				}
				
			}
		
		}
	'''
	
	protected def Set<Event> collectAllEvents(Interface anInterface, EventDirection oppositeDirection) {
		if (anInterface === null) {
			return Collections.EMPTY_SET
		}
		val eventSet = new HashSet<Event>
		for (parentInterface : anInterface.parents) {
			eventSet.addAll(parentInterface.collectAllEvents(oppositeDirection))
		}
		for (event : anInterface.events
				.filter[it.direction != oppositeDirection]
				.map[it.event]) {
			eventSet.add(event)
		}
		return eventSet
	}
	
	private def createInterface(Interface _interface, EventDirection eventDirection)  {
		val notCorrectDirection = eventDirection.opposite
		'''
			«FOR event : collectAllEvents(_interface,notCorrectDirection)»
				boolean isRaised«event.name.toFirstUpper»();
				«FOR parameter : event.parameterDeclarations»
					«parameter.type.serialize» get«parameter.name.toFirstUpper»();
				«ENDFOR»
			«ENDFOR»
		'''
	}
	
	private def createListenerInterface(Interface _interface, EventDirection eventDirection) {
		val notCorrectDirection = eventDirection.opposite
		'''
			«FOR event : collectAllEvents(_interface,notCorrectDirection)»
				void raise«event.name.toFirstUpper»(«FOR parameter : event.parameterDeclarations SEPARATOR ", "»«parameter.type.serialize» «parameter.name»«ENDFOR»);
			«ENDFOR»
		'''
	}
	
		
	def createReflectiveInterface() '''
		package «BASE_PACKAGE_NAME»;
		
		import java.util.Objects;
		
		public interface «Namings.REFLECTIVE_INTERFACE» {
			
			void reset();
					
			String[] getPorts();
					
			String[] getEvents(String port);
					
			void raiseEvent(String port, String event, Object[] parameters);
			
			default boolean isRaisedEvent(String port, String event) {
				return isRaisedEvent(port, event, null);
			}
			
			boolean isRaisedEvent(String port, String event, Object[] parameters);
			
			Object[] getEventParameterValues(String port, String event);
			
			void schedule(String instance);
			
			default void schedule() {
				schedule(null);
			}
			
			boolean isStateActive(String region, String state);
			
			String[] getRegions();
			
			String[] getStates(String region);
			
			String[] getVariables();
			
			Object getValue(String variable);
			
			default boolean checkVariableValue(String variable, Object expectedValue) {
				return Objects.deepEquals(getValue(variable), expectedValue);
			}
			
			String[] getComponents();
			
			ReflectiveComponentInterface getComponent(String component);
			
		}
	'''
	
}