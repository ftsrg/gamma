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
package hu.bme.mit.gamma.genmodel.language.formatting;

import org.eclipse.xtext.Keyword;
import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter;
import org.eclipse.xtext.formatting.impl.FormattingConfig;

import hu.bme.mit.gamma.expression.language.formatting.ExpressionLanguageFormatterUtil;

/**
 * This class contains custom formatting declarations.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#formatting
 * on how and when to use it.
 * 
 * Also see {@link org.eclipse.xtext.xtext.XtextFormatter} as an example
 */
public class GenModelFormatter extends AbstractDeclarativeFormatter {
	
	private final ExpressionLanguageFormatterUtil expressionLanguageFormatterUtil = new ExpressionLanguageFormatterUtil();
	
	@Override
	protected void configureFormatting(FormattingConfig c) {
		hu.bme.mit.gamma.genmodel.language.services.GenModelGrammarAccess f = (hu.bme.mit.gamma.genmodel.language.services.GenModelGrammarAccess) getGrammarAccess();
		expressionLanguageFormatterUtil.format(c, f);
		// Setting the maximum size of lines
        c.setAutoLinewrap(130);
        // Line break after these rules
        c.setLinewrap(1, 1, 2).after(f.getGenModelAccess().getPackageImportsAssignment_0_1_0());
        c.setLinewrap(1, 1, 2).after(f.getGenModelAccess().getStatechartImportsAssignment_0_1_1_1());
        c.setLinewrap(1, 1, 2).after(f.getGenModelAccess().getTraceImportsAssignment_0_1_2_1());
        // Interface compilation
        c.setLinewrap(1).after(f.getEventMappingRule());
        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getStatechartAssignment_4());
        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getTargetFolderAssignment_5_0_2());
        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getFileNameAssignment_5_1_2());
        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getPackageNameAssignment_5_2_2());
        // Statechart compilation
        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getStatechartAssignment_4());
        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getTargetFolderAssignment_5_0_2());
        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getFileNameAssignment_5_1_2());
        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getPackageNameAssignment_5_2_2());
        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getStatechartNameAssignment_5_3_2());
        // Code generation
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getComponentAssignment_4());
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getTargetFolderAssignment_5_0_2());
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getPackageNameAssignment_5_1_2());
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getLanguageAssignment_5_2_2());
        // Analysis model transformation
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getComponentAssignment_4());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getGroup_5());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getTargetFolderAssignment_6_0_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getFileNameAssignment_6_1_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getLanguageAssignment_6_2_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getAlternatives_6_3_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getConstraintAssignment_6_5_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getCoveragesAssignment_6_6());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getSchedulerAssignment_6_4_2());
        // Constraints
        c.setLinewrap(1).after(f.getOrchestratingConstraintAccess().getMinimumPeriodAssignment_2());
        c.setLinewrap(1).after(f.getOrchestratingConstraintAccess().getMaximumPeriodAssignment_5());
        // Coverage
        c.setLinewrap(1).after(f.getStateCoverageAccess().getRule());
        c.setLinewrap(1).after(f.getStateCoverageAccess().getGroup_2_1());
        c.setLinewrap(1).after(f.getStateCoverageAccess().getGroup_2_2());
        c.setLinewrap(1).after(f.getTransitionCoverageAccess().getRule());
        c.setLinewrap(1).after(f.getTransitionCoverageAccess().getGroup_2_1());
        c.setLinewrap(1).after(f.getTransitionCoverageAccess().getGroup_2_2());
        c.setLinewrap(1).after(f.getOutEventCoverageAccess().getRule());
        c.setLinewrap(1).after(f.getOutEventCoverageAccess().getGroup_2_1());
        c.setLinewrap(1).after(f.getOutEventCoverageAccess().getGroup_2_2());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getRule());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_1());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_2());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_3());
        // Test generation
        c.setLinewrap(1).after(f.getTestGenerationAccess().getExecutionTraceAssignment_4());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getTargetFolderAssignment_5_0_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getFileNameAssignment_5_1_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getPackageNameAssignment_5_2_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getLanguageAssignment_5_3_2());
        // Adaptive test generation
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getStatechartContractAssignment_5());
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getTargetFolderAssignment_7_0_2());
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getFileNameAssignment_7_1_2());
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getPackageNameAssignment_7_2_2());
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getLanguageAssignment_7_3_2());
        // Mission phase generation
        c.setLinewrap(1).after(f.getPhaseStatechartGenerationAccess().getStatechartAssignment_5());
        c.setLinewrap(1).after(f.getPhaseStatechartGenerationAccess().getTargetFolderAssignment_7_0_2());
        c.setLinewrap(1).after(f.getPhaseStatechartGenerationAccess().getFileNameAssignment_7_1_2());
        // Interface mapping
        c.setLinewrap(1).after(f.getInterfaceMappingRule());
		for (Keyword comma: f.findKeywords(",")) {
			c.setNoLinewrap().before(comma);
			c.setNoSpace().before(comma);
		}
		c.setLinewrap(0, 1, 2).before(f.getSL_COMMENTRule());
		c.setLinewrap(0, 1, 2).before(f.getML_COMMENTRule());
		c.setLinewrap(0, 1, 1).after(f.getML_COMMENTRule());
	}
}
