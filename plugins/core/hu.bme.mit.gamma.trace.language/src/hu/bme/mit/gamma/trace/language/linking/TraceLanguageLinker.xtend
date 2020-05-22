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
package hu.bme.mit.gamma.trace.language.linking

import hu.bme.mit.gamma.language.util.linking.GammaLanguageLinker
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.TracePackage

class TraceLanguageLinker extends GammaLanguageLinker {
	
	override getContext() {
		return ExecutionTrace
	}
	
	override getRef() {
		return #[TracePackage.eINSTANCE.executionTrace_Import]
	}
		
    
}