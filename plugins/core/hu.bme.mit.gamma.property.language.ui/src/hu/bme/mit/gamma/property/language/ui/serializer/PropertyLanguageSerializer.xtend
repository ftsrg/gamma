/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.property.language.ui.serializer

import hu.bme.mit.gamma.language.util.serialization.GammaLanguageSerializer
import hu.bme.mit.gamma.property.language.ui.internal.LanguageActivator
import java.io.File
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject

class PropertyLanguageSerializer {
	
	def void serialize(EObject rootElem, String parentFolder, String fileName) {
		// This is how an injected object can be retrieved
		val injector = LanguageActivator.getInstance()
				.getInjector(LanguageActivator.HU_BME_MIT_GAMMA_PROPERTY_LANGUAGE_PROPERTYLANGUAGE);
		val serializer = injector.getInstance(GammaLanguageSerializer);
		serializer.save(rootElem, URI.decode(parentFolder + File.separator + fileName));
	}
	
}
