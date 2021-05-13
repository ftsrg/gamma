package hu.bme.mit.gamma.scenario.language.util

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.EcoreUtil2

class EcoreUtilWrapper {
	
	static def isNull(EObject obj){
		obj === null
	}

	static def getAllContainers(EObject obj) {
		return EcoreUtil2::getAllContainers(obj)
	}

	static def equals(EObject obj1, EObject obj2) {
		return new EcoreUtil.EqualityHelper().equals(obj1, obj2)
	}

	static def <T extends EObject> getContainedObjectsByType(EObject container, Class<T> cls) {
		switch (container) {
			case null: null
			default: EcoreUtil2::getAllContentsOfType(container, cls)
		}

	}
}
