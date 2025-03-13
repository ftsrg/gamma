/********************************************************************************
 * Copyright (c) 2020-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.language.ui.serializer

import com.google.inject.Injector
import hu.bme.mit.gamma.language.util.serialization.GammaLanguageSerializer
import hu.bme.mit.gamma.trace.language.TraceLanguageStandaloneSetupGenerated
import hu.bme.mit.gamma.trace.language.ui.internal.LanguageActivator
import java.io.File
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject

class TraceLanguageSerializer {
	
	def void serialize(EObject rootElem, String parentFolder, String fileName) {
		// This is how an injected object can be retrieved
		var Injector injector = null
		val activator = LanguageActivator.instance
		if (activator === null) { // Headless Eclipse
			val setup = new TraceLanguageStandaloneSetupGenerated
			injector = setup.createInjectorAndDoEMFRegistration
		}
		else { // "Normal" Eclipse
			injector = activator.getInjector(
				LanguageActivator.HU_BME_MIT_GAMMA_TRACE_LANGUAGE_TRACELANGUAGE)
		}
		val serializer = injector.getInstance(GammaLanguageSerializer)
		serializer.save(rootElem, URI.decode(parentFolder + File.separator + fileName))
	}
	
}