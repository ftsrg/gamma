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
package hu.bme.mit.gamma.statechart.language.linking;

import java.util.Collection;
import java.util.Collections;
import java.util.Map;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;

import hu.bme.mit.gamma.language.util.linking.GammaLanguageLinker;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage;
import hu.bme.mit.gamma.statechart.interface_.Package;

public class StatechartLanguageLinker extends GammaLanguageLinker {

	@Override
	public Map<Class<? extends EObject>, Collection<EReference>> getContext() {
		return Collections.singletonMap(Package.class,
				Collections.singletonList(InterfaceModelPackage.eINSTANCE.getPackage_Imports()));
	}
	
}