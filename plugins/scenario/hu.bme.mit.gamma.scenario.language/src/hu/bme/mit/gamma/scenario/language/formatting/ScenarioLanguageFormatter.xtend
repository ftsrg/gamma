/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.language.formatting

import com.google.inject.Inject
import hu.bme.mit.gamma.expression.language.formatting.ExpressionLanguageFormatterUtil
import hu.bme.mit.gamma.scenario.language.services.ScenarioLanguageGrammarAccess
import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter
import org.eclipse.xtext.formatting.impl.FormattingConfig

class ScenarioLanguageFormatter extends AbstractDeclarativeFormatter {

	@Inject extension ScenarioLanguageGrammarAccess grammar

	val expressionFormatter = new ExpressionLanguageFormatterUtil

	override protected configureFormatting(FormattingConfig config) {
		// set a line wrap after each statechart and port assignment
		expressionFormatter.format(config, grammar)
		
		config.setLinewrap(1, 1, 2).after(grammar.scenarioPackageAccess.nameAssignment_1)

		config.setLinewrap(1, 1, 2).after(grammar.scenarioPackageAccess.importsAssignment_2_1)
		config.setLinewrap(1, 1, 2).after(grammar.scenarioPackageAccess.componentAssignment_4)

		// set an empty line between statechart, port assignment, scenario definition AND scenario definition
		config.setLinewrap(2).between(grammar.scenarioPackageAccess.importsAssignment_2_1,
			grammar.scenarioPackageAccess.scenariosAssignment_6)
		config.setLinewrap(2).between(grammar.scenarioPackageAccess.scenariosAssignment_6,
			grammar.scenarioPackageAccess.scenariosAssignment_6)
		config.setLinewrap(2).between(grammar.scenarioPackageAccess.scenariosAssignment_6,
			grammar.scenarioPackageAccess.scenariosAssignment_6)

		config.setLinewrap(1, 1, 2).after(grammar.annotationsAccess.allowedWaitAnnotationParserRuleCall_0)
		config.setLinewrap(1, 1, 2).after(grammar.annotationsAccess.negatedWaitAnnotationParserRuleCall_3)
		config.setLinewrap(1, 1, 2).after(grammar.annotationsAccess.negPermissiveAnnotationParserRuleCall_5)
		config.setLinewrap(1, 1, 2).after(grammar.annotationsAccess.negStrictAnnotationParserRuleCall_4)
		config.setLinewrap(1, 1, 2).after(grammar.annotationsAccess.permissiveAnnotationParserRuleCall_1)
		config.setLinewrap(1, 1, 2).after(grammar.annotationsAccess.strictAnnotationParserRuleCall_2)

		config.setNoLinewrap.after(grammar.modalityDefinitionAccess.rule)
		
		config.setLinewrap(1).before(grammar.variableDeclarationRule)

		grammar.findKeywordPairs("[", "]").forEach [ pair |
			config.setIndentationIncrement.after(pair.first)
			config.setIndentationDecrement.before(pair.second)
			config.setLinewrap.after(pair.first)
			config.setLinewrap.around(pair.second)
		]

		config.setNoSpace.before(grammar.interactionAccess.group_5)

		grammar.findKeywords(
			grammar.unorderedCombinedFragmentDefinitionAccess.andKeyword_4_0.value,
			grammar.alternativeCombinedFragmentDefinitionAccess.orKeyword_4_0.value
		).forEach[config.setNoLinewrap.before(it)]
		grammar.findAssignments(grammar.scenarioAssignmentRule).forEach[config.setLinewrap.around(it)]
		grammar.findAssignments(grammar.interactionRule).forEach[config.setLinewrap.around(it)]

	}

}
