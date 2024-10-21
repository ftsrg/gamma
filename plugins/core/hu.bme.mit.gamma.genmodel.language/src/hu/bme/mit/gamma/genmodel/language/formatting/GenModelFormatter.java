/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.genmodel.language.services.GenModelGrammarAccess;

public class GenModelFormatter extends AbstractDeclarativeFormatter {
	
	private final ExpressionLanguageFormatterUtil expressionLanguageFormatterUtil = new ExpressionLanguageFormatterUtil();
	
	@Override
	protected void configureFormatting(FormattingConfig c) {
		hu.bme.mit.gamma.genmodel.language.services.GenModelGrammarAccess f = (GenModelGrammarAccess) getGrammarAccess();
		expressionLanguageFormatterUtil.format(c, f);
		expressionLanguageFormatterUtil.formatExpressions(c, f.getExpressionLanguageGrammarAccess());
		// Setting the maximum size of lines
        c.setAutoLinewrap(110);
        // Line break after these rules
        c.setLinewrap(1, 1, 2).after(f.getGenModelAccess().getPackageImportsAssignment_0_0_1_0());
        c.setLinewrap(1, 1, 2).after(f.getGenModelAccess().getScenarioImportsAssignment_0_0_1_1_1());
        c.setLinewrap(1, 1, 2).after(f.getGenModelAccess().getTraceImportsAssignment_0_0_1_2_1());
        c.setLinewrap(1, 1, 2).after(f.getGenModelAccess().getGenmodelImportsAssignment_0_1_1());
        c.setLinewrap(1, 1, 2).after(f.getGenModelAccess().getTasksAssignment_1());
//        c.setLinewrap(1, 1, 2).after(f.getGenModelAccess().getStatechartImportsAssignment_0_0_1_1_1());
//        // Interface compilation
//        c.setLinewrap(1).after(f.getEventMappingRule());
//        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getStatechartAssignment_4());
//        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getTargetFolderAssignment_5_0_2());
//        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getFileNameAssignment_5_1_2());
//        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getPackageNameAssignment_5_2_2());
//        // Statechart compilation
//        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getStatechartAssignment_4());
//        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getTargetFolderAssignment_5_0_2());
//        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getFileNameAssignment_5_1_2());
//        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getPackageNameAssignment_5_2_2());
//        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getStatechartNameAssignment_5_3_2());
        // Code generation
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getComponentAssignment_4());
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getTargetFolderAssignment_5_0_2());
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getPackageNameAssignment_5_2_2());
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getProjectNameAssignment_5_1_2());
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getProgrammingLanguagesAssignment_5_3_2());
        // Analysis model transformation
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getModelAssignment_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getGroup_3_5());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getTargetFolderAssignment_3_1_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getFileNameAssignment_3_2_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getLanguagesAssignment_3_3_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getPropertyPackageAssignment_3_4_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getInitialStateAssignment_3_5_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getInitialStateSettingAssignment_3_6_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getOptimizeAssignment_3_7_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getGroup_3_8());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getSchedulerAssignment_3_9_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getConstraintAssignment_3_10_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getCoveragesAssignment_3_11());
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
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_4());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_5());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_6());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_7());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_8());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_9());
        c.setLinewrap(1).after(f.getInteractionCoverageAccess().getGroup_2_10());
        c.setLinewrap(1).after(f.getDataflowCoverageAccess().getRule());
        c.setLinewrap(1).after(f.getDataflowCoverageAccess().getGroup_2_1());
        c.setLinewrap(1).after(f.getDataflowCoverageAccess().getGroup_2_2());
        c.setLinewrap(1).after(f.getDataflowCoverageAccess().getGroup_2_3());
        c.setLinewrap(1).after(f.getDataflowCoverageAccess().getGroup_2_4());
        c.setLinewrap(1).after(f.getDataflowCoverageAccess().getGroup_2_5());
        c.setLinewrap(1).after(f.getInteractionDataflowCoverageAccess().getRule());
        c.setLinewrap(1).after(f.getInteractionDataflowCoverageAccess().getGroup_2_1());
        c.setLinewrap(1).after(f.getInteractionDataflowCoverageAccess().getGroup_2_2());
        c.setLinewrap(1).after(f.getInteractionDataflowCoverageAccess().getGroup_2_3());
        c.setLinewrap(1).after(f.getInteractionDataflowCoverageAccess().getGroup_2_4());
        c.setLinewrap(1).after(f.getInteractionDataflowCoverageAccess().getGroup_2_5());
        // Test generation
        c.setLinewrap(1).after(f.getTestGenerationAccess().getExecutionTraceAssignment_4());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getTargetFolderAssignment_5_0_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getFileNameAssignment_5_2_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getProjectNameAssignment_5_1_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getPackageNameAssignment_5_3_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getProgrammingLanguagesAssignment_5_4_2());
        // Adaptive test generation
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getTargetFolderAssignment_4_0_2());
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getProjectNameAssignment_4_1_2());
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getFileNameAssignment_4_2_2());
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getPackageNameAssignment_4_3_2());
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getProgrammingLanguagesAssignment_4_4_2());
        c.setLinewrap(1).after(f.getAdaptiveContractTestGenerationAccess().getTestFolderAssignment_4_5_2());
        // Mission phase generation
        c.setLinewrap(1).after(f.getPhaseStatechartGenerationAccess().getStatechartAssignment_5());
        c.setLinewrap(1).after(f.getPhaseStatechartGenerationAccess().getTargetFolderAssignment_7_0_2());
        c.setLinewrap(1).after(f.getPhaseStatechartGenerationAccess().getFileNameAssignment_7_1_2());
        // Verification
        c.setLinewrap(1).after(f.getVerificationAccess().getTargetFolderAssignment_3_0_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getFileNameAssignment_3_1_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getProjectNameAssignment_3_2_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getAlternatives_3_3_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getSvgFileNameAssignment_3_4_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getAnalysisLanguagesAssignment_3_5_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getQueryFilesAssignment_3_6_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getVerificationArgumentsAssignment_3_7_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getPropertyPackagesAssignment_3_8_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getPackageNameAssignment_3_9_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getGroup_3_9());
        c.setLinewrap(1).after(f.getVerificationAccess().getProgrammingLanguagesAssignment_3_10_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getGroup_3_10());
        c.setLinewrap(1).after(f.getVerificationAccess().getTestFolderAssignment_3_13_2());
        c.setLinewrap(1).after(f.getVerificationAccess().getTimeoutAssignment_3_14_2());
        // Model mutation
        c.setLinewrap(1).after(f.getModelMutationAccess().getTargetFolderAssignment_3_0_2());
        c.setLinewrap(1).after(f.getModelMutationAccess().getModelAssignment_2());
        c.setLinewrap(1).after(f.getModelMutationAccess().getFileNameAssignment_3_1_2());
        c.setLinewrap(1).after(f.getModelMutationAccess().getIterationCountAssignment_3_2_2());
        c.setLinewrap(1).after(f.getModelMutationAccess().getPatternClassNamesAssignment_3_3_2());
        // Model-based mutation testing
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getProjectNameAssignment_3_0_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getTargetFolderAssignment_3_1_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getAnalysisModelTransformationAssignment_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getFileNameAssignment_3_2_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getIterationCountAssignment_3_3_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getPackageNameAssignment_3_4_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getProgrammingLanguagesAssignment_3_5_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getTestFolderAssignment_3_6_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getTraceFoldersAssignment_3_7_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getTestClassNamePatternAssignment_3_8_2());
        c.setLinewrap(1).after(f.getMutationBasedTestGenerationAccess().getPatternClassNamesAssignment_3_9_2());
        // Interface mapping
//        c.setLinewrap(1).after(f.getInterfaceMappingRule());
		for (Keyword comma: f.findKeywords(",")) {
			c.setNoLinewrap().before(comma);
			c.setNoSpace().before(comma);
		}
		c.setLinewrap(0, 1, 2).before(f.getSL_COMMENTRule());
		c.setLinewrap(0, 1, 2).before(f.getML_COMMENTRule());
		c.setLinewrap(0, 1, 1).after(f.getML_COMMENTRule());
	}
}
