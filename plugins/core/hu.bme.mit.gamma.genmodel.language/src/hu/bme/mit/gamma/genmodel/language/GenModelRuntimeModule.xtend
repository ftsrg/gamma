/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.language

import hu.bme.mit.gamma.genmodel.language.formatting.GenModelFormatter
import hu.bme.mit.gamma.genmodel.language.linking.GenModelLinker

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
class GenModelRuntimeModule extends AbstractGenModelRuntimeModule {
	
	// Needed for importing
	override bindILinkingService() {
		return GenModelLinker
	}
	
	override bindIFormatter() {
		return GenModelFormatter
	}
	
}
