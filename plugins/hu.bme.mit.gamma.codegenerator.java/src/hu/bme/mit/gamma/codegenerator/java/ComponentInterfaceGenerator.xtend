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
	
	final String PACKAGE_NAME
	//
	final extension NameGenerator nameGenerator
	
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
			package «component.componentPackageName»;
			
			«FOR interfaceName : ports.map[it.interfaceRealization.interface.generateName].toSet»
				import «PACKAGE_NAME».«Namings.INTERFACE_PACKAGE_POSTFIX».«interfaceName»;
			«ENDFOR»
			
			public interface «component.portOwnerInterfaceName» {
				
				«FOR port : ports»
					«port.implementedJavaInterface» get«port.name.toFirstUpper»();
				«ENDFOR»
				
				void reset();
				
				«IF component instanceof SynchronousComponent»void runCycle();«ENDIF»
				«IF component instanceof AbstractSynchronousCompositeComponent»void runFullCycle();«ENDIF»
				«IF component instanceof AsynchronousComponent»void start();«ENDIF»
				
			}
		'''
		return interfaceCode
	}
}