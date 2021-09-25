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
package hu.bme.mit.gamma.scenario.language.linking

import hu.bme.mit.gamma.language.util.linking.GammaLanguageLinker
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioModelPackage
import java.util.Collections

class ScenarioLanguageLinker extends GammaLanguageLinker {

	override getContext() {
		return Collections.singletonMap(ScenarioDeclaration,
			Collections.singletonList(ScenarioModelPackage.eINSTANCE.scenarioDeclaration_Package));
	}
}
