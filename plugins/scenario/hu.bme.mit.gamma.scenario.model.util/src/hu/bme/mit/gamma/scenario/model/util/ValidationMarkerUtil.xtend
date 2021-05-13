package hu.bme.mit.gamma.scenario.model.util

import hu.bme.mit.gamma.scenario.language.validation.ValidatorBridge
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature

class ValidationMarkerUtil {

	static val ValidatorBridge validator = ValidatorBridge::INSTANCE

	static def void clearExtraMarkers() {
		validator.clear
	} 

	static def void addErrorMarker(String message, EObject obj, EStructuralFeature feature, int index) {
		validator.showError(message, obj, feature, index)
	}

	static def void addWarningMarker(String message, EObject obj, EStructuralFeature feature, int index) {
		validator.showWarning(message, obj, feature, index)
	}

	static def void addInfoMarker(String message, EObject obj, EStructuralFeature feature, int index) {
		validator.showInfo(message, obj, feature, index)
	}

}
