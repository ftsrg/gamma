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
package hu.bme.mit.gamma.yakindu.genmodel.language.formatting;

import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter;
import org.eclipse.xtext.formatting.impl.FormattingConfig;
import org.eclipse.xtext.Keyword;
import org.eclipse.xtext.util.Pair;

/**
 * This class contains custom formatting declarations.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#formatting
 * on how and when to use it.
 * 
 * Also see {@link org.eclipse.xtext.xtext.XtextFormatter} as an example
 */
public class GenModelFormatter extends AbstractDeclarativeFormatter {
	
	@Override
	protected void configureFormatting(FormattingConfig c) {
		hu.bme.mit.gamma.yakindu.genmodel.language.services.GenModelGrammarAccess f = (hu.bme.mit.gamma.yakindu.genmodel.language.services.GenModelGrammarAccess) getGrammarAccess();
		// Setting the maximum size of lines
        c.setAutoLinewrap(130);
        // Line break after these rules
        c.setLinewrap(1).after(f.getGenModelAccess().getPackageImportsAssignment_0_1_0());
        c.setLinewrap(1).after(f.getGenModelAccess().getStatechartImportsAssignment_0_1_1_1());
        c.setLinewrap(1).after(f.getGenModelAccess().getTraceImportsAssignment_0_1_2_1());
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
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getCoveragesAssignment_6_4());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getSchedulerAssignment_6_3_2());
        // Test generation
        c.setLinewrap(1).after(f.getTestGenerationAccess().getExecutionTraceAssignment_4());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getTargetFolderAssignment_5_0_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getFileNameAssignment_5_1_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getPackageNameAssignment_5_2_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getLanguageAssignment_5_3_2());
        // Interface mapping
        c.setLinewrap(1).after(f.getInterfaceMappingRule());
		for (Pair<Keyword, Keyword> pair: f.findKeywordPairs("{", "}")) {
			c.setIndentation(pair.getFirst(), pair.getSecond());
			c.setLinewrap(1).after(pair.getFirst());
			c.setLinewrap(1).before(pair.getSecond());
			c.setLinewrap(1).after(pair.getSecond());
		}
		for (Keyword comma: f.findKeywords(",")) {
			c.setNoLinewrap().before(comma);
			c.setNoSpace().before(comma);
		}
        // No space around parentheses
        for (Pair<Keyword, Keyword> p : f.findKeywordPairs("(", ")")) {
            c.setNoSpace().around(p.getFirst());
            c.setNoSpace().before(p.getSecond());
        }
		c.setLinewrap(0, 1, 2).before(f.getSL_COMMENTRule());
		c.setLinewrap(0, 1, 2).before(f.getML_COMMENTRule());
		c.setLinewrap(0, 1, 1).after(f.getML_COMMENTRule());
	}
}
