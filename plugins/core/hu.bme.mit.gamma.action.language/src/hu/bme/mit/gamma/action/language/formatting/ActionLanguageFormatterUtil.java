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
package hu.bme.mit.gamma.action.language.formatting;

import org.eclipse.xtext.formatting.impl.FormattingConfig;
import org.eclipse.xtext.service.AbstractElementFinder.AbstractGrammarElementFinder;

import hu.bme.mit.gamma.action.language.services.ActionLanguageGrammarAccess;
import hu.bme.mit.gamma.expression.language.formatting.ExpressionLanguageFormatterUtil;

public class ActionLanguageFormatterUtil {
	
	private final ExpressionLanguageFormatterUtil expressionLanguageFormatterUtil =
			new ExpressionLanguageFormatterUtil();
	
	public void format(FormattingConfig c, AbstractGrammarElementFinder f) {
		expressionLanguageFormatterUtil.format(c, f);
	}

	public void formatExpressions(FormattingConfig c, ActionLanguageGrammarAccess f) {
		expressionLanguageFormatterUtil.formatExpressions(c, f.getExpressionLanguageGrammarAccess());
		setSquareBrackets(c, f);
		setFunctionDefinitions(c, f);
		setStatements(c, f);
	}
	
	protected void setSquareBrackets(FormattingConfig c, ActionLanguageGrammarAccess f) {
		c.setNoSpace().before(f.getAssignableAccessExpressionAccess().getLeftSquareBracketKeyword_1_0_1());
		c.setNoSpace().around(f.getAssignableAccessExpressionAccess().getIndexAssignment_1_0_2());
	}
	
	protected void setFunctionDefinitions(FormattingConfig c, ActionLanguageGrammarAccess f) {
		c.setNoSpace().around(f.getProcedureDeclarationAccess().getLeftParenthesisKeyword_2_0());
		c.setNoSpace().before(f.getProcedureDeclarationAccess().getRightParenthesisKeyword_2_2());
		c.setNoSpace().around(f.getLambdaDeclarationAccess().getLeftParenthesisKeyword_2_0());
		c.setNoSpace().before(f.getLambdaDeclarationAccess().getRightParenthesisKeyword_2_2());
	}

	protected void setStatements(FormattingConfig c, ActionLanguageGrammarAccess f) {
		c.setLinewrap(1).before(f
				.getBlockAccess()
				.getActionsAssignment_2());
	}

}