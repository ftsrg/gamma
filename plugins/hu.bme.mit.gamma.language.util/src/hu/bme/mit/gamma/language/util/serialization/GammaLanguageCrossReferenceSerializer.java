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
package hu.bme.mit.gamma.language.util.serialization;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.CrossReference;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.serializer.diagnostic.ISerializationDiagnostic.Acceptor;
import org.eclipse.xtext.serializer.tokens.CrossReferenceSerializer;

import hu.bme.mit.gamma.statechart.model.Package;

public class GammaLanguageCrossReferenceSerializer extends CrossReferenceSerializer {

	public String getCrossReferenceNameFromScope(EObject semanticObject, CrossReference crossref,
			EObject target, final IScope scope, Acceptor errors) {
		if (semanticObject instanceof Package) {
			if (target instanceof Package) {
				return "\"" + target.eResource().getURI().toPlatformString(true) + "\"";
			}
		}
		return super.getCrossReferenceNameFromScope(semanticObject, crossref, target, scope, errors);
	}
	
}