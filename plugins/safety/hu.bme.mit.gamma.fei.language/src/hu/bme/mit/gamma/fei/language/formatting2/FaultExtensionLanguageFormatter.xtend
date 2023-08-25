/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.fei.language.formatting2

import hu.bme.mit.gamma.fei.model.FaultExtensionInstructions
import hu.bme.mit.gamma.fei.model.FaultSlice
import hu.bme.mit.gamma.statechart.language.formatting.StatechartLanguageFormatter
import org.eclipse.xtext.formatting2.IFormattableDocument

class FaultExtensionLanguageFormatter extends StatechartLanguageFormatter {

//	@Inject extension FaultExtensionLanguageGrammarAccess

	def dispatch void format(FaultExtensionInstructions faultExtensionInstructions,
		extension IFormattableDocument document) {
		for (faultSlice : faultExtensionInstructions.faultSlices) {
			faultSlice.format
		}
		faultExtensionInstructions.commonCauses.format
	}

	def dispatch void format(FaultSlice faultSlice, extension IFormattableDocument document) {
		for (componentInstanceElementReferenceExpression : faultSlice.affectedElements) {
			componentInstanceElementReferenceExpression.format
		}
		for (faultMode : faultSlice.faultModes) {
			faultMode.format
		}
	}

}
