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
package hu.bme.mit.gamma.statechart.language.formatting;

import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter;
import org.eclipse.xtext.formatting.impl.FormattingConfig;
import org.eclipse.xtext.Keyword;
import org.eclipse.xtext.util.Pair;

import hu.bme.mit.gamma.statechart.language.services.StatechartLanguageGrammarAccess;

/**
 * This class contains custom formatting declarations.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#formatting
 * on how and when to use it.
 * 
 * Also see {@link org.eclipse.xtext.xtext.XtextFormattingTokenSerializer} as an example
 */
public class StatechartLanguageFormatter extends AbstractDeclarativeFormatter {
	
	@Override
	protected void configureFormatting(FormattingConfig c) {
		StatechartLanguageGrammarAccess f = (StatechartLanguageGrammarAccess) getGrammarAccess(); 
		// Setting the maximum size of lines
        c.setAutoLinewrap(110);
        // Line break between import keywords
        c.setLinewrap(1).after(f.getPackageAccess().getNameAssignment_1());
        c.setLinewrap(1).after(f.getPackageAccess().getImportsAssignment_2_1());
        // Line break after declarations
        c.setLinewrap(1).after(f.getConstantDeclarationRule());
        c.setLinewrap(1).after(f.getFunctionDeclarationRule());
        c.setLinewrap(1).after(f.getTypeDeclarationRule());
        c.setLinewrap(1).after(f.getSchedulingOrderRule());
        // Line breaks after/before these rules
        c.setLinewrap(1).after(f.getVariableDeclarationRule());
        c.setLinewrap(1).after(f.getTimeoutDeclarationRule());
        c.setLinewrap(1).before(f.getComponentRule());
        c.setLinewrap(1).after(f.getTransitionRule()); 
        c.setLinewrap(1).after(f.getRegionRule());
        c.setLinewrap(1).after(f.getStateNodeRule());
        c.setLinewrap(1).after(f.getStateAccess().getInvariantsExpressionParserRuleCall_3_1_0_0_1_0());
        c.setLinewrap(1).after(f.getStateAccess().getEntryActionsActionParserRuleCall_3_1_0_1_2_0());
        c.setLinewrap(1).after(f.getStateAccess().getEntryActionsActionParserRuleCall_3_1_0_1_3_1_0());
        // Composite system rules   
        c.setLinewrap(1).after(f.getClockDeclarationRule());
        c.setLinewrap(1).after(f.getControlSpecificaitonRule());
        c.setLinewrap(1).after(f.getMessageQueueRule());
        c.setLinewrap(1).after(f.getPortBindingRule());
        c.setLinewrap(1).after(f.getChannelRule());
        c.setLinewrap(1).after(f.getSynchronousComponentInstanceRule());
        c.setLinewrap(1).after(f.getAsynchronousComponentInstanceRule());
        c.setLinewrap(1).after(f.getCascadeCompositeComponentAccess().getExecutionListAssignment_5_3_2_1());
        // Right indentation around ports
        c.setLinewrap(1).before(f.getPortRule());
        c.setIndentationIncrement().before(f.getPortRule());
        c.setIndentationDecrement().after(f.getPortRule());
        for (Pair<Keyword, Keyword> p : f.findKeywordPairs("]", "{")) {
            c.setLinewrap(1).before(p.getFirst());
        }
        // No space around guards
        c.setNoSpace().around(f.getTransitionAccess().getGuardAssignment_7_1_1());
        // No space around parentheses
        for (Pair<Keyword, Keyword> p : f.findKeywordPairs("(", ")")) {
            c.setNoSpace().around(p.getFirst());
            c.setNoSpace().before(p.getSecond());
        }	    
        // No space before commas
        for (Keyword comma : f.findKeywords(",")) {
            c.setNoSpace().before(comma);
        }
        for (Keyword comma : f.findKeywords(";")) {
            c.setNoSpace().before(comma);
        }
        // Space before [
        for(Pair<Keyword, Keyword> p : f.findKeywordPairs("[", "]")) {
        	c.setSpace(" ").before(p.getFirst());
        }
        // No space before and after dots
        for (Keyword dot : f.findKeywords(".")) {
            c.setNoSpace().before(dot);
            c.setNoSpace().after(dot);
        }
        // No space before and after double colons
        for (Keyword dot : f.findKeywords("::")) {
            c.setNoSpace().before(dot);
            c.setNoSpace().after(dot);
        }	
        // Setting indentation inside all curly brackets 
        // Setting line wrap after each left curly bracket
        // Setting line wrap around each right curly bracket
        for(Pair<Keyword, Keyword> p : f.findKeywordPairs("{", "}")) {
            c.setIndentationIncrement().after(p.getFirst());
            c.setIndentationDecrement().before(p.getSecond());
            c.setLinewrap().after(p.getFirst());
            c.setLinewrap().around(p.getSecond());
        }
        // Interface events
        c.setLinewrap(1).after(f.getEventDeclarationRule());
        // Comments
		c.setLinewrap(0, 1, 2).before(f.getSL_COMMENTRule());
		c.setLinewrap(0, 1, 2).before(f.getML_COMMENTRule());
		c.setLinewrap(0, 1, 1).after(f.getML_COMMENTRule());
	}
}
