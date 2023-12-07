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

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ReflectiveComponentCodeGenerator {
	
	protected final String BASE_PACKAGE_NAME
	protected Component component
	// 
	protected final extension TimingDeterminer timingDeterminer = TimingDeterminer.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE

	new(String BASE_PACKAGE_NAME, Component component) {
		this.BASE_PACKAGE_NAME = BASE_PACKAGE_NAME
		this.component = component
	}
	
	/**
	 * Generates fields for parameter declarations
	 */
	def CharSequence createReflectiveClass() '''
		package «component.getPackageString(BASE_PACKAGE_NAME)»;
		
		«component.generateReflectiveImports»
		
		public class «component.getReflectiveClassName» implements «Namings.REFLECTIVE_INTERFACE» {
			
			private «component.getComponentClassName» «Namings.REFLECTIVE_WRAPPED_COMPONENT»;
			// Wrapped contained components
			«IF component instanceof CompositeComponent»
				«FOR containedComponent : component.derivedComponents»
					private «Namings.REFLECTIVE_INTERFACE» «containedComponent.name.toFirstLower» = null;
				«ENDFOR»
			«ELSEIF component instanceof AsynchronousAdapter»
				private «Namings.REFLECTIVE_INTERFACE» «component.getWrappedComponentName» = null;
			«ENDIF»
			
			«IF component.needTimer»
				public «component.getReflectiveClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«Namings.UNIFIED_TIMER_INTERFACE» timer) {
					this(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.name»«ENDFOR»);
					«Namings.REFLECTIVE_WRAPPED_COMPONENT».setTimer(timer);
				}
			«ENDIF»
			
			public «component.getReflectiveClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				«Namings.REFLECTIVE_WRAPPED_COMPONENT» = new «component.getComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.name»«ENDFOR»);
			}
			
			public «component.getReflectiveClassName»(«component.getComponentClassName» «Namings.REFLECTIVE_WRAPPED_COMPONENT») {
				this.«Namings.REFLECTIVE_WRAPPED_COMPONENT» = «Namings.REFLECTIVE_WRAPPED_COMPONENT»;
			}
			
			public void reset() {
				«Namings.REFLECTIVE_WRAPPED_COMPONENT».reset();
			}
			
			public «component.getComponentClassName» get«Namings.REFLECTIVE_WRAPPED_COMPONENT.toFirstUpper»() {
				return «Namings.REFLECTIVE_WRAPPED_COMPONENT»;
			}
			
			public String[] getPorts() {
				return new String[] { «FOR port : component.allPorts SEPARATOR ", "»"«port.name»"«ENDFOR» };
			}
			
			public String[] getEvents(String port) {
				switch (port) {
					«FOR port : component.allPorts»
						case "«port.name»":
							return new String[] { «FOR event : port.interfaceRealization.interface.events SEPARATOR ", "»"«event.event.name»"«ENDFOR» };
					«ENDFOR»
					default:
						throw new IllegalArgumentException("Not known port: " + port);
				}
			}
			
			public void raiseEvent(String port, String event) {
				raiseEvent(port, event, null);
			}
			
			public void raiseEvent(String port, String event, Object[] parameters) {
				String portEvent = port + "." + event;
				switch (portEvent) {
					«FOR port : component.allPorts»
						«FOR inEvent : port.inputEvents»
							case "«port.name».«inEvent.name»":
								«Namings.REFLECTIVE_WRAPPED_COMPONENT».get«port.name.toFirstUpper»().raise«inEvent.name.toFirstUpper»(«FOR i : 0..< inEvent.parameterDeclarations.size SEPARATOR ", "»«inEvent.parameterDeclarations.get(i).type.generateParameterCast('''parameters[«i»]''')»«ENDFOR»);
								break;
						«ENDFOR»
					«ENDFOR»
					default:
						throw new IllegalArgumentException("Not known port-in event combination: " + portEvent);
				}
			}
			
			public boolean isRaisedEvent(String port, String event) {
				return isRaisedEvent(port, event, null);
			}
			
			public boolean isRaisedEvent(String port, String event, Object[] parameters) {
				String portEvent = port + "." + event;
				switch (portEvent) {
					«FOR port : component.allPorts»
						«FOR outEvent : port.outputEvents»
							case "«port.name».«outEvent.name»":
								if («Namings.REFLECTIVE_WRAPPED_COMPONENT».get«port.name.toFirstUpper»().isRaised«outEvent.name.toFirstUpper»()) {
									«IF outEvent.parameterDeclarations.empty»
										return true;
									«ELSE»
										if (parameters != null) {
											return
												«FOR i : 0..< outEvent.parameterDeclarations.size SEPARATOR " && "»
													Objects.deepEquals(parameters[«i»], «port.generateEventParameterValuesGetter(outEvent.parameterDeclarations.get(i))»)
												«ENDFOR»;
										}
										else {
											return true;
										}
									«ENDIF»
								}
								break;
						«ENDFOR»
					«ENDFOR»
					default:
						throw new IllegalArgumentException("Not known port-out event combination: " + portEvent);
				}
				«IF !component.allPorts.map[it.outputEvents].flatten.empty»return false;«ENDIF»
			}
			
			public Object[] getEventParameterValues(String port, String event) {
				String portEvent = port + "." + event;
				switch (portEvent) {
					«FOR port : component.allPorts»
						«FOR outEvent : port.outputEvents»
							case "«port.name».«outEvent.name»":
«««								if («Namings.REFLECTIVE_WRAPPED_COMPONENT».get«port.name.toFirstUpper»().isRaised«outEvent.name.toFirstUpper»()) {
								«IF outEvent.parameterDeclarations.empty»
									return new Object[0];
								«ELSE»
									return new Object[] {
										«FOR parameter : outEvent.parameterDeclarations SEPARATOR ", "»
											«port.generateEventParameterValuesGetter(parameter)»
										«ENDFOR»
									};
								«ENDIF»
«««								}
«««								break;
						«ENDFOR»
					«ENDFOR»
					default:
						throw new IllegalArgumentException("Not known port-out event combination: " + portEvent);
				}
«««				«IF !component.allPorts.map[it.outputEvents].flatten.empty»return new Object[0];«ENDIF»
			}
			
			«component.generateIsActiveState»
			
			«component.generateRegionGetter»
			
			«component.generateStateGetter»
			
			«component.generateScheduling»
			
			«component.generateVariableGetters»
			
			«component.generateVariableValueGetters»
			
			«component.generateComponentGetters»
			
			«component.generateComponentValueGetters»
			
		}
	'''
	
	protected def generateReflectiveImports(Component component) '''
		import «BASE_PACKAGE_NAME».*;
		import java.util.Objects;
		«FOR _package : component.containingPackage.componentImports /* For type declarations */
				.filter[it.containsComponentsOrInterfacesOrTypes]»
			import «_package.getPackageString(BASE_PACKAGE_NAME)».*;
		«ENDFOR»
	'''
	
	protected def generateScheduling(Component component) '''
		public void schedule(String instance) {
			«IF component instanceof SynchronousComponent || component instanceof StatechartDefinition»
					«Namings.REFLECTIVE_WRAPPED_COMPONENT».runCycle();
			«ELSEIF component instanceof AsynchronousAdapter ||
				component instanceof ScheduledAsynchronousCompositeComponent»
					«Namings.REFLECTIVE_WRAPPED_COMPONENT».schedule();
			«ELSE»
«««					TODO
			«ENDIF»
		}
	'''
	
	protected def generateIsActiveState(Component component) '''
		public boolean isStateActive(String region, String state) {
			«IF component instanceof StatechartDefinition»
				return «Namings.REFLECTIVE_WRAPPED_COMPONENT».isStateActive(region, state);
			«ELSE»
				return false;
			«ENDIF»
		}
	'''
	
	protected def generateRegionGetter(Component component) '''
		public String[] getRegions() {
			return new String[] { «IF component instanceof StatechartDefinition»«FOR region : component.allRegions SEPARATOR ", "»"«region.name»"«ENDFOR»«ENDIF» };
		}
	'''
	
	protected def generateStateGetter(Component component) '''
		public String[] getStates(String region) {
			switch (region) {
				«IF component instanceof StatechartDefinition»
					«FOR region : component.allRegions»
						case "«region.name»":
							return new String[] { «FOR state : region.states SEPARATOR ", "»"«state.name»"«ENDFOR» };
					«ENDFOR»
				«ENDIF»
			}
			throw new IllegalArgumentException("Not known region: " + region);
		}
	'''
	
	protected def generateVariableGetters(Component component) '''
		public String[] getVariables() {
			return new String[] { «IF component instanceof StatechartDefinition»«FOR variable : component.variableDeclarations SEPARATOR ", "»"«variable.name»"«ENDFOR»«ENDIF» };
		}
	'''
	
	protected def generateEventParameterValuesGetter(Port port, ParameterDeclaration parameter) '''«Namings.REFLECTIVE_WRAPPED_COMPONENT».get«port.name.toFirstUpper»().get«parameter.name.toFirstUpper»()'''
	
	protected def generateVariableValueGetters(Component component) '''
		public Object getValue(String variable) {
			switch (variable) {
				«IF component instanceof StatechartDefinition»
					«FOR variable : component.variableDeclarations.filter[!it.transient]»
						case "«variable.name»":
							return «Namings.REFLECTIVE_WRAPPED_COMPONENT».get«variable.name.toFirstUpper»();
					«ENDFOR»
				«ENDIF»
			}
			throw new IllegalArgumentException("Not known variable: " + variable);
		}
	'''
	
	protected def generateComponentGetters(Component component) '''
		public String[] getComponents() {
			return new String[] { «IF component instanceof CompositeComponent»«FOR containedComponent : component.derivedComponents SEPARATOR ", "»"«containedComponent.name»"«ENDFOR»«ELSEIF component instanceof AsynchronousAdapter»"«component.getWrappedComponentName»"«ENDIF»};
		}
	'''
	
	protected def generateComponentValueGetters(Component component) '''
		public «Namings.REFLECTIVE_INTERFACE» getComponent(String component) {
			switch (component) {
				«IF component instanceof CompositeComponent»
					«FOR containedComponent : component.derivedComponents»
						case "«containedComponent.name»":
							if («containedComponent.name.toFirstLower» == null) {
								«containedComponent.name.toFirstLower» = new «containedComponent.derivedType.getReflectiveClassName»(«Namings.REFLECTIVE_WRAPPED_COMPONENT».get«containedComponent.name.toFirstUpper»());
							}
							return «containedComponent.name.toFirstLower»;
					«ENDFOR»
				«ELSEIF component instanceof AsynchronousAdapter»
					case "«component.getWrappedComponentName»":
						if («component.getWrappedComponentName» == null) {
							«component.getWrappedComponentName» = new «component.wrappedComponent.type.getReflectiveClassName»(«Namings.REFLECTIVE_WRAPPED_COMPONENT».get«component.getWrappedComponentName.toFirstUpper»());
						}
						return «component.getWrappedComponentName»;
				«ENDIF»
				«IF component instanceof StatechartDefinition || component instanceof AsynchronousAdapter»
					// If the class name is given, then it will return itself
					case "«component.getComponentClassName»":
						return this;
				«ENDIF»
			}
			throw new IllegalArgumentException("Not known component: " + component);
		}
	'''
	
	protected def generateParameterCast(Type type, String parameter) {
		return '''(«type.transformType») «parameter»'''
	}
	
	protected def transformType(Type type) '''«type.serialize»'''
	
	def getClassName() {
		return component.reflectiveClassName
	}
	
}