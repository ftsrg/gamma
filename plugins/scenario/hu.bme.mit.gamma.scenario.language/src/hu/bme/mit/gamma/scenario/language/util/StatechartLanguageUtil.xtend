package hu.bme.mit.gamma.scenario.language.util

import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.Package
import org.eclipse.emf.ecore.EObject

class StatechartLanguageUtil {
	// helper methods for the Interfaces and Events in the statechart model 
	static def Iterable<Interface> collectParentInterfaces(Interface interf) {
		val parentInterfaces = interf.parents
		if (parentInterfaces.isEmpty) {
			return #[interf]
		} else {
			return parentInterfaces.map[collectParentInterfaces(it)].flatten
		}
	}

	static def Iterable<Event> collectInterfaceEvents(Interface interf) {
		return collectParentInterfaces(interf).map[it.events.map[it.event]].flatten
	}

	static def Iterable<EventDeclaration> collectInterfaceEventDeclarations(Interface interf) {
		return collectParentInterfaces(interf).map[it.events].flatten
	}

	// helper methods to query in statechart specification
	static def <T extends EObject> filterContainedObjectsByType(Package gammaPackage, Class<T> cls) {
		val componentDeclaration = gammaPackage.components.head
		return EcoreUtilWrapper::getContainedObjectsByType(componentDeclaration, cls)
	}

}
