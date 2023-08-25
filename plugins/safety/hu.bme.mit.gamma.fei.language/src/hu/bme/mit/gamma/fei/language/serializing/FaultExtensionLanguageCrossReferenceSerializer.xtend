/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.fei.language.serializing

import hu.bme.mit.gamma.fei.model.FaultExtensionInstructions
import hu.bme.mit.gamma.language.util.serialization.GammaLanguageCrossReferenceSerializer
import hu.bme.mit.gamma.statechart.interface_.Package

class FaultExtensionLanguageCrossReferenceSerializer extends GammaLanguageCrossReferenceSerializer {

	override getContext() {
		return FaultExtensionInstructions;
	}

	override getTarget() {
		return Package;
	}

}