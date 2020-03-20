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

import org.eclipse.xtext.Keyword;
import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter;
import org.eclipse.xtext.formatting.impl.FormattingConfig;
import org.eclipse.xtext.util.Pair;

import hu.bme.mit.gamma.expression.language.formatting.ExpressionLanguageFormatterUtil;
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
	
	private final ExpressionLanguageFormatterUtil expressionLanguageFormatterUtil = new ExpressionLanguageFormatterUtil();

	@Override
	protected void configureFormatting(FormattingConfig c) {
		StatechartLanguageGrammarAccess f = (StatechartLanguageGrammarAccess) getGrammarAccess();
		expressionLanguageFormatterUtil.format(c, f);
		c.setWrappedLineIndentation(1);
		// Setting the maximum size of lines
        c.setAutoLinewrap(110);
        // Line break between import keywords
        c.setLinewrap(1, 1, 2).after(f.getPackageAccess().getNameAssignment_1());
		c.setLinewrap(1, 1, 2).after(f.getPackageAccess().getImportsAssignment_2_1());
        // Line break after declarations
        c.setLinewrap(1).after(f.getConstantDeclarationRule());
        c.setLinewrap(1).after(f.getFunctionDeclarationRule());
        c.setLinewrap(1).after(f.getTypeDeclarationRule());
        c.setLinewrap(1).after(f.getSchedulingOrderRule());
        // Line breaks after/before these rules
        c.setLinewrap(1).after(f.getVariableDeclarationRule());
        c.setLinewrap(1).after(f.getTimeoutDeclarationRule());
        c.setLinewrap(1).before(f.getComponentRule());
        c.setLinewrap(1).after(f.getStatechartDefinitionAccess().getTransitionPriorityAssignment_0_1_2());
        c.setLinewrap(1).before(f.getTransitionRule());
        c.setLinewrap(1).after(f.getTransitionRule());
        c.setLinewrap(1).before(f.getRegionRule());
        c.setLinewrap(1).after(f.getRegionRule());
        c.setLinewrap(1).after(f.getStateNodeRule());
        c.setLinewrap(1).after(f.getPseudoStateRule());
        c.setLinewrap(1).after(f.getInitialStateRule());
        c.setLinewrap(1).after(f.getChoiceStateRule());
        c.setLinewrap(1).after(f.getMergeStateRule());
        c.setLinewrap(1).after(f.getForkStateRule());
        c.setLinewrap(1).after(f.getJoinStateRule());
        c.setLinewrap(1).after(f.getStateAccess().getInvariantsExpressionParserRuleCall_3_1_0_0_1_0());
        c.setLinewrap(1).after(f.getStateAccess().getEntryActionsActionParserRuleCall_3_1_0_1_2_0());
        c.setLinewrap(1).after(f.getStateAccess().getExitActionsActionParserRuleCall_3_1_0_2_2_0());
        c.setLinewrap(1).after(f.getStateAccess().getExitActionsAssignment_3_1_0_2_2());
        // Composite system rules   
        c.setLinewrap(1, 1, 2).after(f.getClockDeclarationRule());
        c.setLinewrap(1, 1, 2).after(f.getControlSpecificaitonRule());
        c.setLinewrap(1, 1, 2).after(f.getMessageQueueRule());
        c.setLinewrap(1, 1, 2).after(f.getPortBindingRule());
        c.setLinewrap(1).after(f.getChannelRule());
        c.setLinewrap(1, 1, 2).after(f.getSynchronousComponentInstanceRule());
        c.setLinewrap(1, 1, 2).after(f.getAsynchronousComponentInstanceRule());
        c.setLinewrap(1, 1, 2).after(f.getCascadeCompositeComponentAccess().getExecutionListAssignment_5_3_2_1());
        // Set line wrap after bindings and components
        
        // Right indentation around ports
        c.setLinewrap(1).before(f.getPortRule());
        c.setIndentationIncrement().before(f.getPortRule());
        c.setIndentationDecrement().after(f.getPortRule());
		for (Keyword comma : f.findKeywords(",")) {
            c.setNoSpace().before(comma);
        }
        for (Pair<Keyword, Keyword> p : f.findKeywordPairs("]", "{")) {
            c.setLinewrap(1).before(p.getFirst());
        }
        // No space around guards 
        c.setNoSpace().around(f.getTransitionAccess().getGuardAssignment_7_1_1());
        // No space before parameters and arguments 
        c.setNoSpace().before(f.getStatechartDefinitionAccess().getGroup_3());
        c.setNoSpace().before(f.getSynchronousCompositeComponentAccess().getGroup_2());
        c.setNoSpace().before(f.getCascadeCompositeComponentAccess().getGroup_2());
        c.setNoSpace().before(f.getAsynchronousAdapterAccess().getGroup_2());
        c.setNoSpace().before(f.getAsynchronousCompositeComponentAccess().getGroup_2());
        c.setNoSpace().before(f.getAsynchronousComponentInstanceAccess().getGroup_4());
        c.setNoSpace().before(f.getSynchronousComponentInstanceAccess().getGroup_4());
        c.setNoSpace().before(f.getEventAccess().getGroup_4());
        c.setNoSpace().before(f.getRaiseEventActionAccess().getGroup_4());
        // Space before [
        for (Pair<Keyword, Keyword> p : f.findKeywordPairs("[", "]")) {
        	c.setSpace(" ").before(p.getFirst());
        }
        c.setNoSpace().around(f.getTransitionAccess().getGuardAssignment_7_1_1());
        // Interface events
        c.setLinewrap(1).after(f.getEventDeclarationRule());
        // Comments
		c.setLinewrap(0, 1, 2).before(f.getSL_COMMENTRule());
		c.setLinewrap(0, 1, 2).before(f.getML_COMMENTRule());
		c.setLinewrap(0, 1, 1).after(f.getML_COMMENTRule());
	}
}
