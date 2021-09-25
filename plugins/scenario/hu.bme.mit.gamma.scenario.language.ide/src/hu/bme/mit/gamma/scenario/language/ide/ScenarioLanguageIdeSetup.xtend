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
package hu.bme.mit.gamma.scenario.language.ide

import com.google.inject.Guice
import hu.bme.mit.gamma.scenario.language.ScenarioLanguageRuntimeModule
import hu.bme.mit.gamma.scenario.language.ScenarioLanguageStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class ScenarioLanguageIdeSetup extends ScenarioLanguageStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new ScenarioLanguageRuntimeModule, new ScenarioLanguageIdeModule))
	}
	
}
