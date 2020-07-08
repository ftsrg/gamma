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
package hu.bme.mit.gamma.property.language

import hu.bme.mit.gamma.property.language.formatting.PropertyLanguageFormatter
import hu.bme.mit.gamma.property.language.linking.PropertyLanguageLinker
import hu.bme.mit.gamma.property.language.serializing.PropertyLanguageCrossReferenceSerializer
import org.eclipse.xtext.serializer.tokens.ICrossReferenceSerializer

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
class PropertyLanguageRuntimeModule extends AbstractPropertyLanguageRuntimeModule {
	
	override bindIFormatter() {
		return PropertyLanguageFormatter
	}
	
	// Needed for importing
	override bindILinkingService() {
		return PropertyLanguageLinker
	}
	
	// Needed for import serialization: return value type is needed!
	def Class<? extends ICrossReferenceSerializer> bindICrossReferenceSerializer() {
		return PropertyLanguageCrossReferenceSerializer
	}
	
}
