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

import hu.bme.mit.gamma.scenario.language.formatting.ScenarioLanguageFormatter
import hu.bme.mit.gamma.scenario.language.linking.ScenarioLanguageLinker
import org.eclipse.xtext.formatting.IFormatter

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
class ScenarioLanguageRuntimeModule extends AbstractScenarioLanguageRuntimeModule {

	override Class<? extends IFormatter> bindIFormatter() {
		return ScenarioLanguageFormatter
	}
	
	// Needed for importing
	override bindILinkingService() {
		return ScenarioLanguageLinker
	}

}
