package hu.bme.mit.gamma.expression.language.formatting;

import org.eclipse.xtext.Keyword;
import org.eclipse.xtext.formatting.impl.FormattingConfig;
import org.eclipse.xtext.service.AbstractElementFinder.AbstractGrammarElementFinder;
import org.eclipse.xtext.util.Pair;

public class ExpressionLanguageFormatterUtil {

	public void format(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Pair<Keyword, Keyword> pair: f.findKeywordPairs("{", "}")) {
			c.setIndentation(pair.getFirst(), pair.getSecond());
			c.setLinewrap(1).after(pair.getFirst());
			c.setLinewrap(1).before(pair.getSecond());
			c.setLinewrap(1).after(pair.getSecond());
		}
        // No space around parentheses
        for (Pair<Keyword, Keyword> p : f.findKeywordPairs("(", ")")) {
            c.setNoSpace().after(p.getFirst());
            c.setNoSpace().before(p.getSecond());
        }
		for (Keyword dot : f.findKeywords(".")) {
            c.setNoSpace().around(dot);
        }
		for (Keyword exclamationMark : f.findKeywords("!")) {
            c.setNoSpace().after(exclamationMark);
        }
		for (Keyword comma : f.findKeywords(";")) {
            c.setNoSpace().before(comma);
        }
        // No space after double colons
        for (Keyword dot : f.findKeywords("::")) {
            c.setNoSpace().after(dot);
        }
	}
	
}
