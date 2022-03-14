/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.property.language.linking

import hu.bme.mit.gamma.language.util.linking.GammaLanguageLinker
import hu.bme.mit.gamma.property.model.PropertyModelPackage
import hu.bme.mit.gamma.property.model.PropertyPackage

class PropertyLanguageLinker extends GammaLanguageLinker {
	
	override getContext() {
		return newHashMap(PropertyPackage -> #[PropertyModelPackage.eINSTANCE.propertyPackage_Imports])
	}
    
}