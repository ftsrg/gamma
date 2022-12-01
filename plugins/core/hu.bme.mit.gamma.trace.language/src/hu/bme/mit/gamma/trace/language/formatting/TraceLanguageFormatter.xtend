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
package hu.bme.mit.gamma.trace.language.formatting

import hu.bme.mit.gamma.expression.language.formatting.ExpressionLanguageFormatterUtil
import hu.bme.mit.gamma.trace.language.services.TraceLanguageGrammarAccess
import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter
import org.eclipse.xtext.formatting.impl.FormattingConfig

class TraceLanguageFormatter extends AbstractDeclarativeFormatter {
	
	final ExpressionLanguageFormatterUtil expressionLanguageFormatterUtil = new ExpressionLanguageFormatterUtil
	
	protected override void configureFormatting(FormattingConfig c) {
		val f = grammarAccess as TraceLanguageGrammarAccess
		// Using the basic expression language formatting
		expressionLanguageFormatterUtil.format(c, f)
		expressionLanguageFormatterUtil.formatExpressions(c, f.getExpressionLanguageGrammarAccess());
		// Setting the maximum size of lines
        c.setAutoLinewrap(110)
        // Line break between import and component keywords
        c.setLinewrap(0, 1, 2).between(f.executionTraceAccess.importAssignment_1,
        	f.executionTraceAccess.traceKeyword_3)
        //	
        c.setNoSpace.after(f.raiseEventActAccess.eventAssignment_3)
        // Line breaks after these rules
        c.setLinewrap(1).before(f.executionTraceAnnotationsRule)
        c.setLinewrap(1).after(f.executionTraceAnnotationsRule)
  		c.setLinewrap(1).after(f.executionTraceAccess.group_6)
        c.setLinewrap(1).after(f.actRule)
        c.setLinewrap(1).after(f.raiseEventActRule)
        c.setLinewrap(1).after(f.stepAccess.group_6)
        // Comments
		c.setLinewrap(0, 1, 2).before(f.getSL_COMMENTRule()) 
		c.setLinewrap(0, 1, 2).before(f.getML_COMMENTRule()) 
		c.setLinewrap(0, 1, 1).after(f.getML_COMMENTRule())
	}
	
}