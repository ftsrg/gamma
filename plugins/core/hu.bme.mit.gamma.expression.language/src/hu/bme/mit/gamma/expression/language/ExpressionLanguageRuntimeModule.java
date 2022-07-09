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
package hu.bme.mit.gamma.expression.language;

import org.eclipse.xtext.formatting.IFormatter;
import org.eclipse.xtext.scoping.IScopeProvider;

import com.google.inject.Binder;

import hu.bme.mit.gamma.expression.language.formatting.ExpressionLanguageFormatter;
import hu.bme.mit.gamma.expression.language.scoping.ExpressionLanguageScopeProvider;

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
public class ExpressionLanguageRuntimeModule extends AbstractExpressionLanguageRuntimeModule {
	
	public Class<? extends IScopeProvider> bindIScopeProvider() {
		return ExpressionLanguageScopeProvider.class;
	}
	
	@Override
	public Class<? extends IFormatter> bindIFormatter() {
		return ExpressionLanguageFormatter.class;
	}

	public void configureSerializerIScopeProvider(Binder binder) {
		binder.bind(org.eclipse.xtext.scoping.IScopeProvider.class).annotatedWith(org.eclipse.xtext.serializer.tokens.SerializerScopeProviderBinding.class).to(ExpressionLanguageScopeProvider.class);
	}
	
}
