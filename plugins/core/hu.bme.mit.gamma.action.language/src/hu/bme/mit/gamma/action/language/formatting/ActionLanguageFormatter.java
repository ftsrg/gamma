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
package hu.bme.mit.gamma.action.language.formatting;

import org.eclipse.xtext.Keyword;
import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter;
import org.eclipse.xtext.formatting.impl.FormattingConfig;

import hu.bme.mit.gamma.action.language.services.ActionLanguageGrammarAccess;
import hu.bme.mit.gamma.expression.language.formatting.ExpressionLanguageFormatterUtil;

public class ActionLanguageFormatter extends AbstractDeclarativeFormatter {
	
	private final ExpressionLanguageFormatterUtil expressionLanguageFormatterUtil = new ExpressionLanguageFormatterUtil();
	
	@Override
	protected void configureFormatting(FormattingConfig c) {
		ActionLanguageGrammarAccess f = (ActionLanguageGrammarAccess) getGrammarAccess();
		expressionLanguageFormatterUtil.format(c, f);
		expressionLanguageFormatterUtil.formatExpressions(c, f.getExpressionLanguageGrammarAccess());
		for (Keyword comma: f.findKeywords(",")) {
			c.setNoLinewrap().before(comma);
			c.setNoSpace().before(comma);
			c.setLinewrap().after(comma);
		}
		c.setLinewrap(0, 1, 2).before(f.getSL_COMMENTRule());
		c.setLinewrap(0, 1, 2).before(f.getML_COMMENTRule());
		c.setLinewrap(0, 1, 1).after(f.getML_COMMENTRule());
	}
}
