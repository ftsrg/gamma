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
package hu.bme.mit.gamma.statechart.language.formatting;

import org.eclipse.xtext.Keyword;
import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter;
import org.eclipse.xtext.formatting.impl.FormattingConfig;
import org.eclipse.xtext.util.Pair;

import hu.bme.mit.gamma.action.language.formatting.ActionLanguageFormatterUtil;
import hu.bme.mit.gamma.statechart.language.services.StatechartLanguageGrammarAccess;

public class StatechartLanguageFormatter extends AbstractDeclarativeFormatter {
	
	private final ActionLanguageFormatterUtil actionLanguageFormatterUtil =
			new ActionLanguageFormatterUtil();

	@Override
	protected void configureFormatting(FormattingConfig c) {
		StatechartLanguageGrammarAccess f = (StatechartLanguageGrammarAccess) getGrammarAccess();
		actionLanguageFormatterUtil.format(c, f);
		actionLanguageFormatterUtil.formatExpressions(c, f.getActionLanguageGrammarAccess());
		c.setWrappedLineIndentation(1);
		// Setting the maximum size of lines
        c.setAutoLinewrap(100);
        // Line break between import keywords
        c.setLinewrap(1, 1, 2).after(f.getPackageAccess().getNameAssignment_1());
		c.setLinewrap(1, 1, 2).after(f.getPackageAccess().getImportsAssignment_2_1());
        // Line break after declarations
        c.setLinewrap(1).after(f.getConstantDeclarationRule());
        c.setLinewrap(1).after(f.getFunctionDeclarationRule());
        c.setLinewrap(1).after(f.getTypeDeclarationRule());
        c.setLinewrap(1).after(f.getSchedulingOrderRule());

        // Line breaks after/before these rules
        c.setLinewrap(1).after(f.getStatechartContractAnnotationRule());
        c.setLinewrap(1).after(f.getGuardEvaluationRule());
        c.setLinewrap(1).after(f.getComponentAnnotationRule());
        c.setLinewrap(1).after(f.getStateAnnotationRule());
        c.setLinewrap(1, 1, 2).after(f.getVariableDeclarationRule());
        c.setLinewrap(1, 1, 2).after(f.getTimeoutDeclarationRule());
        c.setLinewrap(1).before(f.getComponentRule());
        c.setLinewrap(1).after(f.getSynchronousStatechartDefinitionAccess().getSchedulingOrderAssignment_0_0_2());
        c.setLinewrap(1).after(f.getSynchronousStatechartDefinitionAccess().getOrthogonalRegionSchedulingOrderAssignment_0_1_2());
        c.setLinewrap(1).after(f.getSynchronousStatechartDefinitionAccess().getTransitionPriorityAssignment_0_2_2());
        c.setLinewrap(1).after(f.getAsynchronousStatechartDefinitionAccess().getAsynchronousKeyword_0());
        c.setLinewrap(1).after(f.getAsynchronousStatechartDefinitionAccess().getSchedulingOrderAssignment_1_0_2());
        c.setLinewrap(1).after(f.getAsynchronousStatechartDefinitionAccess().getOrthogonalRegionSchedulingOrderAssignment_1_1_2());
        c.setLinewrap(1).after(f.getAsynchronousStatechartDefinitionAccess().getTransitionPriorityAssignment_1_2_2());
        c.setLinewrap(1).before(f.getTransitionRule());
        c.setLinewrap(1).after(f.getTransitionAnnotationRule());
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
//        c.setLinewrap(1).after(f.getStateAccess().getEntryActionsActionParserRuleCall_3_1_0_1_2_0());
//        c.setLinewrap(1).after(f.getStateAccess().getExitActionsActionParserRuleCall_3_1_0_2_2_0());
//        c.setLinewrap(1).after(f.getStateAccess().getExitActionsAssignment_3_1_0_2_2());
        // Composite system rules   
        c.setLinewrap(1, 1, 2).after(f.getClockDeclarationRule());
        c.setLinewrap(1, 1, 2).after(f.getControlSpecificaitonRule());
        c.setLinewrap(1, 1, 2).after(f.getMessageQueueRule());
        c.setLinewrap(1, 1, 2).after(f.getPortBindingRule());
        c.setLinewrap(1, 1, 2).after(f.getChannelRule());
        c.setLinewrap(1, 1, 2).after(f.getSynchronousComponentInstanceRule());
        c.setLinewrap(1, 1, 2).after(f.getAsynchronousComponentInstanceRule());
        c.setLinewrap(1, 1, 2).after(f.getCascadeCompositeComponentAccess().getGroup_7());
        c.setLinewrap(1, 1, 2).after(f.getCascadeCompositeComponentAccess().getGroup_8());
        c.setLinewrap(1, 1, 2).after(f.getScheduledAsynchronousCompositeComponentAccess().getGroup_7());
        c.setLinewrap(1, 1, 2).after(f.getScheduledAsynchronousCompositeComponentAccess().getGroup_8());
        // Set line wrap after variable bindings
        c.setLinewrap(1, 1, 2).before(f.getMissionPhaseStateAnnotationAccess().getGroup_4());
        c.setIndentationIncrement().before(f.getMissionPhaseStateAnnotationAccess().getGroup_4());
        c.setIndentationDecrement().after(f.getMissionPhaseStateAnnotationAccess().getGroup_4());
        c.setSpace(" ").before(f.getMissionPhaseStateAnnotationAccess().getLeftCurlyBracketKeyword_4_2());
        c.setLinewrap(1, 1, 2).after(f.getVariableBindingRule());
        
        // Right indentation around ports
        c.setLinewrap(1, 1, 2).before(f.getPortRule());
        c.setIndentationIncrement().before(f.getPortRule());
        c.setIndentationDecrement().after(f.getPortRule());
        for (Pair<Keyword, Keyword> p : f.findKeywordPairs("]", "{")) {
            c.setLinewrap(1).before(p.getFirst());
        }
        // No space after @
		for (Keyword at : f.findKeywords("@")) {
            c.setNoSpace().after(at);
        }
        // No space around guards 
        c.setNoSpace().around(f.getTransitionAccess().getGuardAssignment_7_1_1());
        // No space before parameters and arguments 
        c.setNoSpace().before(f.getSynchronousStatechartDefinitionAccess().getGroup_3());
        c.setNoSpace().before(f.getAsynchronousStatechartDefinitionAccess().getGroup_5());
        c.setNoSpace().before(f.getSynchronousCompositeComponentAccess().getGroup_3());
        c.setNoSpace().before(f.getCascadeCompositeComponentAccess().getGroup_3());
        c.setNoSpace().before(f.getAsynchronousAdapterAccess().getGroup_3());
        c.setNoSpace().before(f.getAsynchronousCompositeComponentAccess().getGroup_3());
        c.setNoSpace().before(f.getAsynchronousComponentInstanceAccess().getGroup_4());
        c.setNoSpace().before(f.getSynchronousComponentInstanceAccess().getGroup_4());
        c.setNoSpace().before(f.getEventAccess().getGroup_4());
        c.setNoSpace().before(f.getRaiseEventActionAccess().getGroup_4());
        c.setNoSpace().before(f.getNotTriggerAccess().getOperandParenthesesTriggerParserRuleCall_1_0());
        // Space before [
//        for (Pair<Keyword, Keyword> p : f.findKeywordPairs("[", "]")) {
//        	c.setSpace(" ").before(p.getFirst());
//        }
        // Interface events
        c.setLinewrap(1).after(f.getEventDeclarationRule());
        // Comments
		c.setLinewrap(0, 1, 2).before(f.getSL_COMMENTRule());
		c.setLinewrap(0, 1, 2).before(f.getML_COMMENTRule());
		c.setLinewrap(0, 1, 1).after(f.getML_COMMENTRule());
	}
}
