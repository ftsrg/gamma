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
package hu.bme.mit.gamma.genmodel.language.linking

import hu.bme.mit.gamma.genmodel.model.GenModel
import hu.bme.mit.gamma.genmodel.model.GenmodelModelPackage
import hu.bme.mit.gamma.language.util.linking.GammaLanguageLinker

class GenModelLinker extends GammaLanguageLinker {
		
    public static extension GenmodelModelPackage pack = GenmodelModelPackage.eINSTANCE
				
	override getContext() {
		return GenModel
	}
	
	override getRef() {
		return #[genModel_StatechartImports, genModel_PackageImports, genModel_TraceImports, genModel_GenmodelImports]
	}
    
}
	