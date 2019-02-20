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
package hu.bme.mit.gamma.trace.language.formatting

import hu.bme.mit.gamma.trace.language.services.TraceLanguageGrammarAccess
import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter
import org.eclipse.xtext.formatting.impl.FormattingConfig

class TraceLanguageFormatter extends AbstractDeclarativeFormatter {	
	
	protected override void configureFormatting(FormattingConfig c) {
		val f = grammarAccess as TraceLanguageGrammarAccess
		// Setting the maximum size of lines
        c.setAutoLinewrap(130)
        // Line break between import and component keywords
        c.setLinewrap(1).between(f.executionTraceAccess.importAssignment_1, f.executionTraceAccess.traceKeyword_2)
        // Line breaks after these rules
  		c.setLinewrap(1).after(f.executionTraceAccess.group_5)
        c.setLinewrap(1).after(f.actRule)
        c.setLinewrap(1).after(f.raiseEventActRule)
        c.setLinewrap(1).after(f.stepAccess.commaKeyword_7_3_0)
        // No space around parentheses
        for (p : f.findKeywordPairs("(", ")")) {
            c.setNoSpace().around(p.getFirst())
            c.setNoSpace().before(p.getSecond())
        }	    
        // No space before commas
        for (comma : f.findKeywords(",")) {
            c.setNoSpace().before(comma)
        }        
        // No space before and after dots
        for (dot : f.findKeywords(".")) {
            c.setNoSpace().before(dot)
            c.setNoSpace().after(dot)
        }		
        // Setting indentation inside all curly brackets 
        // Setting line wrap after each left curly bracket
        // Setting line wrap around each right curly bracket
        for(p : f.findKeywordPairs("{", "}")) {
            c.setIndentationIncrement().after(p.getFirst())
            c.setIndentationDecrement().before(p.getSecond())
            c.setLinewrap().after(p.getFirst())
            c.setLinewrap().around(p.getSecond())
        }
        // Comments
		c.setLinewrap(0, 1, 2).before(f.getSL_COMMENTRule()) 
		c.setLinewrap(0, 1, 2).before(f.getML_COMMENTRule()) 
		c.setLinewrap(0, 1, 1).after(f.getML_COMMENTRule()) 
	}
	
}