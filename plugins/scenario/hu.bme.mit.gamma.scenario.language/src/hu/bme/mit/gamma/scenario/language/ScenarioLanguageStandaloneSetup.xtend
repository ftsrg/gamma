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
package hu.bme.mit.gamma.scenario.language

/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class ScenarioLanguageStandaloneSetup extends ScenarioLanguageStandaloneSetupGenerated {

	def static void doSetup() {
		new ScenarioLanguageStandaloneSetup().createInjectorAndDoEMFRegistration
	}
}
