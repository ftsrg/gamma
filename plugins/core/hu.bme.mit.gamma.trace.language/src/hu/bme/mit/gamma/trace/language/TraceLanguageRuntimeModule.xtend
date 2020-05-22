/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.language

import com.google.inject.Binder
import hu.bme.mit.gamma.trace.language.formatting.TraceLanguageFormatter
import hu.bme.mit.gamma.trace.language.linking.TraceLanguageLinker
import hu.bme.mit.gamma.trace.language.scoping.TraceLanguageScopeProvider
import hu.bme.mit.gamma.trace.language.serializing.TraceLanguageCrossReferenceSerializer
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.serializer.tokens.ICrossReferenceSerializer
import org.eclipse.xtext.serializer.tokens.SerializerScopeProviderBinding

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
class TraceLanguageRuntimeModule extends AbstractTraceLanguageRuntimeModule {
		
	// Needed for importing
	override bindILinkingService() {
		return TraceLanguageLinker
	}
	
	// Theoretically, needed for serialization
	override bindIScopeProvider() {
		return TraceLanguageScopeProvider;
	}

	override configureSerializerIScopeProvider(Binder binder) {
		binder.bind(IScopeProvider).annotatedWith(SerializerScopeProviderBinding).to(TraceLanguageScopeProvider);
	}
	//
	
	override bindIFormatter() {
		return TraceLanguageFormatter
	}
	
	// Needed for import serialization: return value type is needed!
	def Class<? extends ICrossReferenceSerializer> bindICrossReferenceSerializer() {
		return TraceLanguageCrossReferenceSerializer;
	}	
	
}
