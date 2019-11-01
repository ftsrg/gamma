package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import java.util.HashSet

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class ComponentInterfaceGenerator {
	
	protected final String PACKAGE_NAME
	//
	protected final extension NameGenerator nameGenerator
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
	}
	
	/**
	 * Generates the Java interface code (implemented by the component) of the given component.
	 */
	protected def generateComponentInterface(Component component) {
		var ports = new HashSet<Port>
		if (component instanceof CompositeComponent) {
			val composite = component as CompositeComponent
			// Only bound ports are created
			ports += composite.portBindings.map[it.compositeSystemPort]
		}
		else if (component instanceof AsynchronousAdapter) {
			ports += component.allPorts
		}
		else {
			ports += component.ports
		}
		val interfaceCode = '''
			package «component.generateComponentPackageName»;
			
			«FOR interfaceName : ports.map[it.interfaceRealization.interface.generateName].toSet»
				import «PACKAGE_NAME».«Namings.INTERFACE_PACKAGE_POSTFIX».«interfaceName»;
			«ENDFOR»
			
			public interface «component.generatePortOwnerInterfaceName» {
				
				«FOR port : ports»
					«port.implementedJavaInterfaceName» get«port.name.toFirstUpper»();
				«ENDFOR»
				
				void reset();
				
				«IF component instanceof SynchronousComponent»void runCycle();«ENDIF»
				«IF component instanceof AbstractSynchronousCompositeComponent»void runFullCycle();«ENDIF»
				«IF component instanceof AsynchronousComponent»void start();«ENDIF»
				
			}
		'''
		return interfaceCode
	}
	
	protected def generateReflectiveInterface() '''
		package «PACKAGE_NAME»;
		
		public interface «Namings.REFLECTIVE_INTERFACE» {
			
			public void reset();
					
			public String[] getPorts();
					
			public String[] getEvents(String port);
					
			public void raiseEvent(String port, String event, Object[] parameters);
					
			public boolean isRaisedEvent(String port, String event, Object[] parameters);
			
			public void schedule(String instance);
			
			public boolean isStateActive(String region, String state);
			
			public String[] getRegions();
			
			public String[] getStates(String region);
			
			public String[] getVariables();
			
			public Object getValue(String variable);
			
			public String[] getComponents();
			
			public ReflectiveComponentInterface getComponent(String component);
			
		}
	'''
	
}