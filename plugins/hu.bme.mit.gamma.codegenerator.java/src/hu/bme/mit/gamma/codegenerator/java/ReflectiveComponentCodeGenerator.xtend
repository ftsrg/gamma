package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class ReflectiveComponentCodeGenerator {
	
	protected final String PACKAGE_NAME
	// 
	protected final extension NameGenerator nameGenerator
	protected final extension TimingDeterminer timingDeterminer
	protected final extension TypeTransformer typeTransformer
	protected final extension ComponentCodeGenerator componentCodeGenerator
	//
	final String wrappedComponentName = "wrappedComponent"

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
		
		public class «component.generateReflectiveComponentClassName» {
			
			private «component.generateComponentClassName» «wrappedComponentName»;
			
			«IF component.needTimer»
				public «component.generateReflectiveComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«Namings.UNIFIED_TIMER_INTERFACE» timer) {
					this(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.name»«ENDFOR»);
					«wrappedComponentName».setTimer(timer);
				}
			«ENDIF»
			
			public «component.generateReflectiveComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				wrappedComponent = new «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.name»«ENDFOR»);
			}
			
			public void reset() {
				«wrappedComponentName».reset();
			}
			
			public «component.generateComponentClassName» get«wrappedComponentName.toFirstUpper»() {
				return «wrappedComponentName»;
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
						«FOR inEvent : port.getSemanticEvents(EventDirection.IN)»
							case "«port.name».«inEvent.name»":
								«wrappedComponentName».get«port.name.toFirstUpper»().raise«inEvent.name.toFirstUpper»(«FOR i : 0..< inEvent.parameterDeclarations.size SEPARATOR ", "»parameters[«i»]«ENDFOR»);
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
						«FOR outEvent : port.getSemanticEvents(EventDirection.OUT)»
							case "«port.name».«outEvent.name»":
								if («wrappedComponentName».get«port.name.toFirstUpper»().isRaised«outEvent.name.toFirstUpper»()) {
									«FOR i : 0..< outEvent.parameterDeclarations.size BEFORE "return " SEPARATOR " && " AFTER ";"»
										 parameters[«i»].equals(«wrappedComponentName».get«port.name.toFirstUpper»().get«outEvent.parameterDeclarations.get(i).name.toFirstUpper»())
									«ENDFOR»
									«IF outEvent.parameterDeclarations.empty»return true;«ENDIF»
								}
								break;
						«ENDFOR»
					«ENDFOR»
					default:
						throw new IllegalArgumentException("Not known port-out event combination: " + portEvent);
				}
				return false;
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
	'''
	
	protected def generateScheduling(Component component) '''
		«IF component instanceof SynchronousComponent»
			public void schedule() {
				«wrappedComponentName».runCycle();
			}
		«ELSEIF component instanceof AsynchronousAdapter»
			public void schedule() {
				«wrappedComponentName».schedule();
			}
		«ELSE»
			public void schedule(String instance) {
«««				TODO
			}
		«ENDIF»
	'''
	
	protected def generateIsActiveState(Component component) '''
		public boolean isStateActive(String region, String state) {
			«IF component instanceof StatechartDefinition»
				return «wrappedComponentName».isStateActive(region, state);
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
							return «wrappedComponentName».get«variable.name.toFirstUpper»();
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
		public Object getComponent(String component) {
			switch (component) {
				«IF component instanceof CompositeComponent»
					«FOR containedComponent : component.derivedComponents»
						case "«containedComponent.name»":
							return «wrappedComponentName».get«containedComponent.name.toFirstUpper»();
					«ENDFOR»
				«ELSEIF component instanceof AsynchronousAdapter»
					case "«component.generateWrappedComponentName»":
						return «wrappedComponentName».get«component.generateWrappedComponentName.toFirstUpper»();
				«ENDIF»
			}
			throw new IllegalArgumentException("Not known component: " + component);
		}
	'''
	
}