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

import hu.bme.mit.gamma.statechart.language.parser.antlr.StatechartLanguageParser;

public class CustomStatechartExpressionLanguageParser extends StatechartLanguageParser {
	
	// Set default rule to "Expression" from "Package"
	@Override
	protected String getDefaultRuleName() {
		return "Expression";
	}
	
}
