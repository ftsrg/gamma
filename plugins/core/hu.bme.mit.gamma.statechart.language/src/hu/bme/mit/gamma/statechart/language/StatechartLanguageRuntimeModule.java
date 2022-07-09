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
package hu.bme.mit.gamma.statechart.language;

import org.eclipse.xtext.formatting.IFormatter;
import org.eclipse.xtext.linking.ILinkingService;
import org.eclipse.xtext.scoping.IScopeProvider;
import org.eclipse.xtext.serializer.tokens.ICrossReferenceSerializer;

import com.google.inject.Binder;

import hu.bme.mit.gamma.statechart.language.formatting.StatechartLanguageFormatter;
import hu.bme.mit.gamma.statechart.language.linking.StatechartLanguageLinker;
import hu.bme.mit.gamma.statechart.language.scoping.StatechartLanguageScopeProvider;
import hu.bme.mit.gamma.statechart.language.serializing.StatechartLanguageCrossReferenceSerializer;

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
public class StatechartLanguageRuntimeModule extends AbstractStatechartLanguageRuntimeModule {
	
	// Theoretically, needed for the serialization
	public Class<? extends IScopeProvider> bindIScopeProvider() {
		return StatechartLanguageScopeProvider.class;
	}

	public void configureSerializerIScopeProvider(Binder binder) {
		binder.bind(org.eclipse.xtext.scoping.IScopeProvider.class).annotatedWith(org.eclipse.xtext.serializer.tokens.SerializerScopeProviderBinding.class).to(StatechartLanguageScopeProvider.class);
	}
	//
	
	@Override
	public Class<? extends IFormatter> bindIFormatter() {
		return StatechartLanguageFormatter.class;
	}
	
	// Needed for importing
	@Override
	public Class<? extends ILinkingService> bindILinkingService() {
		return StatechartLanguageLinker.class;
	}
	
	// Needed for correct serialization of imports
	public Class<? extends ICrossReferenceSerializer> bindICrossReferenceSerializer() {
		return StatechartLanguageCrossReferenceSerializer.class;
	}	
	//
	
}
