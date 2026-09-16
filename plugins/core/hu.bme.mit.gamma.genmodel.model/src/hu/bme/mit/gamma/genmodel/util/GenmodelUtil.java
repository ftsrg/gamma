/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.genmodel.model.GenModel;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class GenmodelUtil extends StatechartUtil {
	// Singleton
	public static final GenmodelUtil INSTANCE = new GenmodelUtil();
	protected GenmodelUtil() {}
	//
	
	// Extending super methods
	
	@Override
	public Collection<TypeDeclaration> getTypeDeclarations(EObject context) {
		GenModel genmodel = ecoreUtil.getSelfOrContainerOfType(context, GenModel.class);
		List<TypeDeclaration> types = new ArrayList<TypeDeclaration>();
		for (Package _import :genmodel.getPackageImports()) {
			types.addAll(
					_import.getTypeDeclarations());
		}
		return types;
	}
	
}