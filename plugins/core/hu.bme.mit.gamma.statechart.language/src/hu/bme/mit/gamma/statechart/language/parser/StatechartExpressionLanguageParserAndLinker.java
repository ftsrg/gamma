/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.language.parser;

import org.eclipse.xtext.parser.antlr.AbstractAntlrParser;

import com.google.inject.Injector;

import hu.bme.mit.gamma.expression.language.parser.ExpressionLanguageParserAndLinker;
import hu.bme.mit.gamma.statechart.language.StatechartLanguageStandaloneSetup;

public class StatechartExpressionLanguageParserAndLinker extends ExpressionLanguageParserAndLinker {
	
	@Override
	protected Injector getInjector() {
//		ExpressionLanguageStandaloneSetup.doSetup();
//		ActionLanguageStandaloneSetup.doSetup();
		return new StatechartLanguageStandaloneSetup().createInjectorAndDoEMFRegistration();
	}
	
	protected Class<? extends AbstractAntlrParser> getParserClass() {
		return CustomStatechartExpressionLanguageParser.class;
	}
	
}