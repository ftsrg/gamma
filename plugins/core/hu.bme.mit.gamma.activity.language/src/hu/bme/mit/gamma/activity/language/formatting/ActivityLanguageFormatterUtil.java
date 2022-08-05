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
package hu.bme.mit.gamma.activity.language.formatting;

import org.eclipse.xtext.formatting.impl.FormattingConfig;
import org.eclipse.xtext.service.AbstractElementFinder.AbstractGrammarElementFinder;

import hu.bme.mit.gamma.action.language.formatting.ActionLanguageFormatterUtil;
import hu.bme.mit.gamma.activity.language.services.ActivityLanguageGrammarAccess;

public class ActivityLanguageFormatterUtil {
	
	private final ActionLanguageFormatterUtil actionLanguageFormatterUtil =
			new ActionLanguageFormatterUtil();

	public void format(FormattingConfig c, AbstractGrammarElementFinder f) {
		actionLanguageFormatterUtil.format(c, f);
	}

	public void formatExpressions(FormattingConfig c, ActivityLanguageGrammarAccess f) {
		actionLanguageFormatterUtil.formatExpressions(c, f.getActionLanguageGrammarAccess());
	}

}
