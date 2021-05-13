package hu.bme.mit.gamma.scenario.language.formatting

import com.google.inject.Inject
import hu.bme.mit.gamma.scenario.language.services.ScenarioLanguageGrammarAccess
import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter
import org.eclipse.xtext.formatting.impl.FormattingConfig

class ScenarioLanguageFormatter extends AbstractDeclarativeFormatter {

	@Inject extension ScenarioLanguageGrammarAccess grammar

	override protected configureFormatting(FormattingConfig config) {
		// based on source found here: https://github.com/mn-mikke/Model-driven-Pretty-Printer-for-Xtext-Framework/wiki/Standard-Way-of-Code-Formatting-in-Xtext-Framework
		// set a line wrap after each statechart and port assignment 
		config.setLinewrap.after(grammar.scenarioDeclarationAccess.packageAssignment_1)
		config.setLinewrap.after(grammar.scenarioDeclarationAccess.componentAssignment_3)

		// set an empty line between statechart, port assignment, scenario definition AND scenario definition
		config.setLinewrap(2).between(grammar.scenarioDeclarationAccess.packageAssignment_1, grammar.scenarioDeclarationAccess.scenariosAssignment_4)
		config.setLinewrap(2).between(grammar.scenarioDeclarationAccess.componentAssignment_3, grammar.scenarioDeclarationAccess.scenariosAssignment_4)
		config.setLinewrap(2).between(grammar.scenarioDeclarationAccess.scenariosAssignment_4, grammar.scenarioDeclarationAccess.scenariosAssignment_4)

		grammar.findKeywords(".").forEach[config.setNoSpace.around(it)]

//		config.setIndentationIncrement.before(grammar.prechartDefinitionRule)
//		config.setIndentationDecrement.after(grammar.prechartDefinitionRule)
//		for (keyword : grammar.findKeywords("then")) {
//			config.setIndentationDecrement.before(keyword)
//			config.setIndentationIncrement.after(keyword)
//		}
//		config.setIndentationIncrement.before(grammar.mainchartDefinitionRule)
//		config.setIndentationDecrement.after(grammar.mainchartDefinitionRule)
//		
		
		config.setNoLinewrap.after(grammar.modalityDefinitionAccess.rule)

		// set indentation inside all curly brackets 
		// set line wrap after each left curly bracket
		// set line wrap around each right curly bracket
		grammar.findKeywordPairs("{", "}").forEach [ pair |
			config.setIndentationIncrement.after(pair.first)
			config.setIndentationDecrement.before(pair.second)
			config.setLinewrap.after(pair.first)
			config.setLinewrap.around(pair.second)
		]

		grammar.findKeywordPairs("[", "]").forEach [ pair |
			config.setIndentationIncrement.after(pair.first)
			config.setIndentationDecrement.before(pair.second)
			config.setLinewrap.after(pair.first)
			config.setLinewrap.around(pair.second)
		]
		
		// No space around parentheses
		for (pair : grammar.findKeywordPairs("(", ")")) {
			config.setNoSpace.after(pair.first)
			config.setNoSpace.before(pair.second)
		}
		
		config.setNoSpace.before(grammar.signalDefinitionAccess.group_5)
		
		grammar.findKeywords(grammar.unorderedCombinedFragmentDefinitionAccess.andKeyword_4_0.value,
			grammar.alternativeCombinedFragmentDefinitionAccess.orKeyword_4_0.value
		).forEach[config.setNoLinewrap.before(it)]
		grammar.findAssignments(grammar.abstractInteractionDefinitionRule).forEach[config.setLinewrap.around(it)]
		grammar.findAssignments(grammar.signalDefinitionRule).forEach[config.setLinewrap.around(it)]
		
	}

}
