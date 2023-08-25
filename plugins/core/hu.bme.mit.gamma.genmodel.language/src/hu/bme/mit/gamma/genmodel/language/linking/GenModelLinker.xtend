/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.language.linking

import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation
import hu.bme.mit.gamma.genmodel.model.GenModel
import hu.bme.mit.gamma.genmodel.model.GenmodelModelPackage
import hu.bme.mit.gamma.genmodel.model.SafetyAssessment
import hu.bme.mit.gamma.genmodel.model.Slicing
import hu.bme.mit.gamma.genmodel.model.Verification
import hu.bme.mit.gamma.genmodel.model.XstsReference
import hu.bme.mit.gamma.language.util.linking.GammaLanguageLinker

class GenModelLinker extends GammaLanguageLinker {
		
    public static GenmodelModelPackage pack = GenmodelModelPackage.eINSTANCE
				
	override getContext() {
		return newLinkedHashMap(
			GenModel -> #[
				pack.genModel_StatechartImports,
				pack.genModel_PackageImports,
				pack.genModel_TraceImports,
				pack.genModel_GenmodelImports,
				pack.genModel_ScenarioImports
			],
			Verification -> #[pack.verification_PropertyPackages],
			XstsReference -> #[pack.xstsReference_XSts],
			AnalysisModelTransformation -> #[
				pack.analysisModelTransformation_PropertyPackage,
				pack.analysisModelTransformation_InitialState
			],
			Slicing -> #[pack.slicing_PropertyPackage],
			SafetyAssessment -> #[
				pack.safetyAssessment_PropertyPackages,
				pack.safetyAssessment_FaultExtensionInstructions
			]
		)
	}
	
}
	