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
package hu.bme.mit.gamma.statechart.language.serializing;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.language.util.serialization.GammaLanguageCrossReferenceSerializer;
import hu.bme.mit.gamma.statechart.interface_.Package;


public class StatechartLanguageCrossReferenceSerializer extends GammaLanguageCrossReferenceSerializer {

	@Override
	public Class<? extends EObject> getContext() {
		return Package.class;
	}

	@Override
	public Class<? extends EObject> getTarget() {
		return Package.class;
	}

}
