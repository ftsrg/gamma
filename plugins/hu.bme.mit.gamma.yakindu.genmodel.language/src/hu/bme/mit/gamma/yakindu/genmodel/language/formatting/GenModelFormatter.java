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
        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getTargetFolderAssignment_3_0_2());
        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getFileNameAssignment_3_1_2());
        c.setLinewrap(1).after(f.getInterfaceCompilationAccess().getPackageNameAssignment_3_2_2());
        // Statechart compilation
        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getTargetFolderAssignment_3_0_2());
        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getFileNameAssignment_3_1_2());
        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getPackageNameAssignment_3_2_2());
        c.setLinewrap(1).after(f.getStatechartCompilationAccess().getStatechartNameAssignment_3_3_2());
        // Code generation
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getTargetFolderAssignment_3_0_2());
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getPackageNameAssignment_3_1_2());
        c.setLinewrap(1).after(f.getCodeGenerationAccess().getLanguageAssignment_3_2_2());
        // Analysis model transformation
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getTargetFolderAssignment_4_0_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getFileNameAssignment_4_1_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getLanguageAssignment_4_2_2());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getCoveragesAssignment_4_4());
        c.setLinewrap(1).after(f.getAnalysisModelTransformationAccess().getSchedulerAssignment_4_3_2());
        // Test generation
        c.setLinewrap(1).after(f.getTestGenerationAccess().getTargetFolderAssignment_3_0_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getFileNameAssignment_3_1_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getPackageNameAssignment_3_2_2());
        c.setLinewrap(1).after(f.getTestGenerationAccess().getLanguageAssignment_3_3_2());
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
			c.setLinewrap().after(comma);
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
