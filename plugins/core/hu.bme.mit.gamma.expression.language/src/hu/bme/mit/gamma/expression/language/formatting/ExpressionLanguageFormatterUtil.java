/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.language.formatting;

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.AbstractElement;
import org.eclipse.xtext.Group;
import org.eclipse.xtext.Keyword;
import org.eclipse.xtext.RuleCall;
import org.eclipse.xtext.formatting.impl.FormattingConfig;
import org.eclipse.xtext.service.AbstractElementFinder.AbstractGrammarElementFinder;
import org.eclipse.xtext.util.Pair;

import hu.bme.mit.gamma.expression.language.services.ExpressionLanguageGrammarAccess;

public class ExpressionLanguageFormatterUtil {
	
	public void format(FormattingConfig c, AbstractGrammarElementFinder f) {
		setBrackets(c, f);
		formatBracketLess(c, f);
	}
	
	public void formatBracketLess(FormattingConfig c, AbstractGrammarElementFinder f) {
		setParantheses(c, f);
		setDots(c, f);
		setExclamationMarks(c, f);
		setCommas(c, f);
		setSemicolons(c, f);
		setDoubleColons(c, f);
	}

	protected void setDoubleColons(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword dot : f.findKeywords("::")) {
//			c.setNoSpace().around(dot);
			EObject container = dot.eContainer();
		    if (container instanceof Group group) {
		        List<AbstractElement> elements = group.getElements();
		        int size = elements.size();
		        int i = elements.indexOf(dot);
		        if (i > 0 
//		        		&& i < elements.size() - 1
//		                && elements.get(i - 1) instanceof RuleCall left
//		                && elements.get(i + 1) instanceof RuleCall right
//		                && left.getRule().getName().equals("ID")
//		                && right.getRule().getName().equals("ID")
		                ) {
					c.setNoSpace().before(dot);
		        }
		        if (i < size - 1) {
					c.setNoSpace().after(dot);
		        }
		    }
		}
	}

	protected void setCommas(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword comma : f.findKeywords(",")) {
			c.setNoSpace().before(comma);
		}
	}
	
	protected void setSemicolons(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword comma : f.findKeywords(";")) {
			c.setNoSpace().before(comma);
		}
	}

	protected void setExclamationMarks(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword exclamationMark : f.findKeywords("!")) {
			c.setNoSpace().after(exclamationMark);
		}
	}

	protected void setDots(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword dot : f.findKeywords(".")) {
			c.setNoSpace().around(dot);
		}
	}

	protected void setParantheses(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Pair<Keyword, Keyword> p : f.findKeywordPairs("(", ")")) {
			c.setNoSpace().after(p.getFirst());
			c.setNoSpace().before(p.getSecond());
		}
	}

	protected void setBrackets(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Pair<Keyword, Keyword> pair : f.findKeywordPairs("{", "}")) {
			c.setIndentation(pair.getFirst(), pair.getSecond());
			c.setLinewrap(1).after(pair.getFirst());
			c.setLinewrap(1).before(pair.getSecond());
			c.setLinewrap(1).after(pair.getSecond());
		}
	}
	
	public void formatExpressions(FormattingConfig c, ExpressionLanguageGrammarAccess f) {
		setFunctions(c, f);
		setRecordLiterals(c, f);
		setSquareBrackets(c, f);
	}
	
	protected void setFunctions(FormattingConfig c, ExpressionLanguageGrammarAccess f) {
		c.setNoSpace().around(f.getAccessExpressionAccess().getLeftParenthesisKeyword_1_1_1());
		c.setNoSpace().before(f.getAccessExpressionAccess().getRightParenthesisKeyword_1_1_3());
	}
	
	protected void setRecordLiterals(FormattingConfig c, ExpressionLanguageGrammarAccess f) {
		c.setLinewrap(1).before(f.getRecordTypeDefinitionAccess().getFieldDeclarationsAssignment_3_1());
		c.setNoSpace().before(f.getRecordLiteralExpressionAccess().getTypeDeclarationAssignment_1());
	}
	
	protected void setSquareBrackets(FormattingConfig c, ExpressionLanguageGrammarAccess f) {
		// Index
		c.setNoSpace().before(f.getAccessExpressionAccess().getLeftSquareBracketKeyword_1_0_1());
		c.setNoSpace().around(f.getAccessExpressionAccess().getIndexAssignment_1_0_2());
		// Type
		c.setNoSpace().after(f.getArrayTypeDefinitionAccess().getRightSquareBracketKeyword_2());
		c.setNoSpace().around(f.getArrayTypeDefinitionAccess().getSizeAssignment_1());
	}

}