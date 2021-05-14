/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
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
