package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter

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
				public «component.generateReflectiveComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«Namings.YAKINDU_TIMER_INTERFACE» timer) {
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
						throw new IllegalArgumentException("Not known port-event combination: " + portEvent);
				}
			}
			
			«component.generateScheduling»
			
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
}