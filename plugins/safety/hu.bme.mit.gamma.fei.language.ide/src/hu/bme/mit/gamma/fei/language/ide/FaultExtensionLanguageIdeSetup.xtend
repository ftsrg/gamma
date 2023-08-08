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
package hu.bme.mit.gamma.fei.language.ide

import com.google.inject.Guice
import hu.bme.mit.gamma.fei.language.FaultExtensionLanguageRuntimeModule
import hu.bme.mit.gamma.fei.language.FaultExtensionLanguageStandaloneSetup
import org.eclipse.xtext.util.Modules2

class FaultExtensionLanguageIdeSetup extends FaultExtensionLanguageStandaloneSetup {

	override createInjector() {
		Guice.createInjector(
			Modules2.mixin(new FaultExtensionLanguageRuntimeModule, new FaultExtensionLanguageIdeModule))
	}

}
