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
package hu.bme.mit.gamma.fei.language.linking

import hu.bme.mit.gamma.fei.model.FaultExtensionInstructions
import hu.bme.mit.gamma.fei.model.FeiModelPackage
import hu.bme.mit.gamma.language.util.linking.GammaLanguageLinker

class FaultExtensionLanguageLinker extends GammaLanguageLinker {
		
    public static FeiModelPackage pack = FeiModelPackage.eINSTANCE
				
	override getContext() {
		return newLinkedHashMap(
			FaultExtensionInstructions -> #[
				pack.faultExtensionInstructions_Imports
			]
		)
	}
	
}