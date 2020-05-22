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
package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.codegenerator.java.util.Namings
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EnumerableTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import org.eclipse.xtext.xbase.scoping.batch.SuperConstructorDescription

class ReflectiveComponentCodeGenerator {
	
	protected final String PACKAGE_NAME
	// 
	protected final extension NameGenerator nameGenerator
	protected final extension TimingDeterminer timingDeterminer
	protected final extension TypeTransformer typeTransformer
	protected final extension ComponentCodeGenerator componentCodeGenerator

	new(String packageName, Trace trace) {
		this.PACKAGE_NAME = packageName
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
		this.timingDeterminer = new TimingDeterminer 
		this.typeTransformer = new TypeTransformer(trace)
		this.componentCodeGenerator = new ComponentCodeGenerator(trace)
	}
	
	/**
	 * Generates fields for parameter declarations
	 */
	def CharSequence generateReflectiveClass(Component component) '''
		package «component.generateComponentPackageName»;
		
		«component.generateReflectiveImports»
		
		public class «component.generateReflectiveComponentClassName» implements «Namings.REFLECTIVE_INTERFACE» {
			
			private «component.generateComponentClassName» «Namings.REFLECTIVE_WRAPPED_COMPONENT»;
			// Wrapped contained components
			«IF component instanceof CompositeComponent»
				«FOR containedComponent : component.derivedComponents»
					private «Namings.REFLECTIVE_INTERFACE» «containedComponent.name.toFirstLower» = null;
				«ENDFOR»
			«ELSEIF component instanceof AsynchronousAdapter»
				private «Namings.REFLECTIVE_INTERFACE» «component.generateWrappedComponentName» = null;
			«ENDIF»
			
			«IF component.needTimer»
				public «component.generateReflectiveComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«Namings.UNIFIED_TIMER_INTERFACE» timer) {
					this(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.name»«ENDFOR»);
					«Namings.REFLECTIVE_WRAPPED_COMPONENT».setTimer(timer);
				}
			«ENDIF»
			
			public «component.generateReflectiveComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				«Namings.REFLECTIVE_WRAPPED_COMPONENT» = new «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.name»«ENDFOR»);
			}
			
			public «component.generateReflectiveComponentClassName»(«component.generateComponentClassName» «Namings.REFLECTIVE_WRAPPED_COMPONENT») {
				this.«Namings.REFLECTIVE_WRAPPED_COMPONENT» = «Namings.REFLECTIVE_WRAPPED_COMPONENT»;
			}
			
			public void reset() {
				«Namings.REFLECTIVE_WRAPPED_COMPONENT».reset();
			}
			
			public «component.generateComponentClassName» get«Namings.REFLECTIVE_WRAPPED_COMPONENT.toFirstUpper»() {
				return «Namings.REFLECTIVE_WRAPPED_COMPONENT»;
			}
			
			public String[] getPorts() {
				return new String[] { «FOR port : component.ports SEPARATOR ", "»"«port.name»"«ENDFOR» };
			}
			
			public String[] getEvents(String port) {
				switch (port) {
					«FOR port : component.ports»
						case "«port.name»":
							return new String[] { «FOR event : port.interfaceRealization.interface.events SEPARATOR ", "»"«event.event.name»"«ENDFOR» };
					«ENDFOR»
					default:
						throw new IllegalArgumentException("Not known port: " + port);
				}
			}
			
			public void raiseEvent(String port, String event, Object[] parameters) {
				String portEvent = port + "." + event;
				switch (portEvent) {
					«FOR port : component.ports»
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
			
			public boolean isRaisedEvent(String port, String event, Object[] parameters) {
				String portEvent = port + "." + event;
				switch (portEvent) {
					«FOR port : component.ports»
						«FOR outEvent : port.outputEvents»
							case "«port.name».«outEvent.name»":
								if («Namings.REFLECTIVE_WRAPPED_COMPONENT».get«port.name.toFirstUpper»().isRaised«outEvent.name.toFirstUpper»()) {
									«FOR i : 0..< outEvent.parameterDeclarations.size BEFORE "return " SEPARATOR " && " AFTER ";"»
										 parameters[«i»].equals(«Namings.REFLECTIVE_WRAPPED_COMPONENT».get«port.name.toFirstUpper»().get«outEvent.parameterDeclarations.get(i).name.toFirstUpper»()«IF outEvent.parameterDeclarations.get(i).toBeConvertedToString».toString()«ENDIF»)
									«ENDFOR»
									«IF outEvent.parameterDeclarations.empty»return true;«ENDIF»
								}
								break;
						«ENDFOR»
					«ENDFOR»
					default:
						throw new IllegalArgumentException("Not known port-out event combination: " + portEvent);
				}
				«IF !component.ports.map[it.outputEvents].flatten.empty»return false;«ENDIF»
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
		import «PACKAGE_NAME».*;
		«IF component instanceof CompositeComponent»
			«FOR containedComponentType : component.derivedComponents.map[it.derivedType].toSet»
				import «containedComponentType.generateComponentPackageName».*;
			«ENDFOR»
		«ELSEIF component instanceof AsynchronousAdapter»
			import «component.generateComponentPackageName».*;
		«ENDIF»
	'''
	
	protected def generateScheduling(Component component) '''
		public void schedule(String instance) {
			«IF component instanceof SynchronousComponent»
					«Namings.REFLECTIVE_WRAPPED_COMPONENT».runCycle();
			«ELSEIF component instanceof AsynchronousAdapter»
					«Namings.REFLECTIVE_WRAPPED_COMPONENT».schedule();
			«ELSE»
	«««				TODO
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
	
	protected def generateVariableValueGetters(Component component) '''
		public Object getValue(String variable) {
			switch (variable) {
				«IF component instanceof StatechartDefinition»
					«FOR variable : component.variableDeclarations»
						case "«variable.name»":
							return «Namings.REFLECTIVE_WRAPPED_COMPONENT».get«variable.name.toFirstUpper»()«IF variable.toBeConvertedToString».toString()«ENDIF»;
					«ENDFOR»
				«ENDIF»
			}
			throw new IllegalArgumentException("Not known variable: " + variable);
		}
	'''
	
	protected def generateComponentGetters(Component component) '''
		public String[] getComponents() {
			return new String[] { «IF component instanceof CompositeComponent»«FOR containedComponent : component.derivedComponents SEPARATOR ", "»"«containedComponent.name»"«ENDFOR»«ELSEIF component instanceof AsynchronousAdapter»"«component.generateWrappedComponentName»"«ENDIF»};
		}
	'''
	
	protected def generateComponentValueGetters(Component component) '''
		public «Namings.REFLECTIVE_INTERFACE» getComponent(String component) {
			switch (component) {
				«IF component instanceof CompositeComponent»
					«FOR containedComponent : component.derivedComponents»
						case "«containedComponent.name»":
							if («containedComponent.name.toFirstLower» == null) {
								«containedComponent.name.toFirstLower» = new «containedComponent.derivedType.generateReflectiveComponentClassName»(«Namings.REFLECTIVE_WRAPPED_COMPONENT».get«containedComponent.name.toFirstUpper»());
							}
							return «containedComponent.name.toFirstLower»;
					«ENDFOR»
				«ELSEIF component instanceof AsynchronousAdapter»
					case "«component.generateWrappedComponentName»":
						if («component.generateWrappedComponentName» == null) {
							«component.generateWrappedComponentName» = new «component.generateReflectiveComponentClassName»(«Namings.REFLECTIVE_WRAPPED_COMPONENT».get«component.generateWrappedComponentName.toFirstUpper»());
						}
						return «component.generateWrappedComponentName»;
				«ENDIF»
				«IF component instanceof StatechartDefinition»
					// If the class name is given, then it will return itself
					case "«component.generateComponentClassName»":
						return this;
				«ENDIF»
			}
			throw new IllegalArgumentException("Not known component: " + component);
		}
	'''
	
	protected def generateParameterCast(Type type, String parameter) {
		if (type instanceof TypeReference) {
			val typeDeclaration = type.reference
			if (typeDeclaration.type instanceof EnumerableTypeDefinition) {
				return '''«typeDeclaration.name».valueOf(«parameter».toString())'''
			}
		}
		return '''(«type.transformType») «parameter»'''
	}
	
	/**
	 * Enums are returned as strings.
	 */
	protected def toBeConvertedToString(Declaration variable) {
		val type = variable.type
		if (type instanceof EnumerableTypeDefinition) {
			return true
		}
		if (type instanceof TypeReference) {
			val reference = type.reference
			if (reference.type instanceof EnumerableTypeDefinition) {
				return true
			}
		}
		return false
	}
	
}