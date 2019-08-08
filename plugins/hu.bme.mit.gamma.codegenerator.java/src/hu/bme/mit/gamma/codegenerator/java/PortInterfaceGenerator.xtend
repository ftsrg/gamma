package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.Interface

class PortInterfaceGenerator {
	
	final String PACKAGE_NAME
	final extension EventDeclarationHandler gammaEventDeclarationHandler
	final extension NameGenerator nameGenerator
	
	new(String packageName, Trace trace) {
		this.PACKAGE_NAME = packageName
		this.gammaEventDeclarationHandler = new EventDeclarationHandler(trace)
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
	}
	
	def generatePortInterfaces(Interface anInterface) '''
		package «PACKAGE_NAME»;
		
		import java.util.List;
		
		public interface «anInterface.generateName» {
			
			interface Provided extends Listener.Required {
				
				«anInterface.generateIsRaisedInterfaceMethods(EventDirection.IN)»
				
				void registerListener(Listener.Provided listener);
				List<Listener.Provided> getRegisteredListeners();
			}
			
			interface Required extends Listener.Provided {
				
				«anInterface.generateIsRaisedInterfaceMethods(EventDirection.OUT)»
				
				void registerListener(Listener.Required listener);
				List<Listener.Required> getRegisteredListeners();
			}
			
			interface Listener {
				
				interface Provided «IF !anInterface.parents.empty»extends «FOR parent : anInterface.parents»«parent.generateName».Listener.Provided«ENDFOR»«ENDIF» {
					«FOR event : anInterface.events.filter[it.direction != EventDirection.IN]»
						void raise«event.event.name.toFirstUpper»(«event.generateParameter»);
					«ENDFOR»							
				}
				
				interface Required «IF !anInterface.parents.empty»extends «FOR parent : anInterface.parents»«parent.generateName».Listener.Required«ENDFOR»«ENDIF» {
					«FOR event : anInterface.events.filter[it.direction != EventDirection.OUT]»
						void raise«event.event.name.toFirstUpper»(«event.generateParameter»);
					«ENDFOR»  					
				}
				
			}
		}
	'''
		
	private def generateIsRaisedInterfaceMethods(Interface anInterface, EventDirection oppositeDirection) '''
	«««		Simple flag checks
		«FOR event : anInterface.events.filter[it.direction != oppositeDirection].map[it.event]»
			public boolean isRaised«event.name.toFirstUpper»();
	«««		ValueOf checks	
			«IF event.parameterDeclarations.size > 0»
				public «event.parameterDeclarations.eventParameterType» get«event.name.toFirstUpper»Value();
			«ENDIF»
		«ENDFOR»
	'''
}