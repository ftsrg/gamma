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

import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.CrossReference;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.serializer.diagnostic.ISerializationDiagnostic.Acceptor;
import org.eclipse.xtext.serializer.tokens.CrossReferenceSerializer;

public abstract class GammaLanguageCrossReferenceSerializer extends CrossReferenceSerializer {

	public String getCrossReferenceNameFromScope(EObject semanticObject, CrossReference crossref,
			EObject target, final IScope scope, Acceptor errors) {
		if (getContext().isInstance(semanticObject)) {
			if (getTarget().isInstance(target)) {
				Resource resource = target.eResource();
				URI uri = resource.getURI();
				String string = null;
				// We prefer relative URIs as they are platform independent
				if (uri.isRelative()) {
					string = uri.toPlatformString(true);
				}
				else {
					// Absolute URI - trimming the workspace from the beginning
					String workspaceLocation = "file:/" + 
							ResourcesPlugin.getWorkspace().getRoot().getLocation().toString();
					string = uri.toString().replaceFirst(workspaceLocation, "");
				}
				return "\"" + string + "\"";
			}
		}
		return super.getCrossReferenceNameFromScope(semanticObject, crossref, target, scope, errors);
	}
	
    public abstract Class<? extends EObject> getContext();
    public abstract Class<? extends EObject> getTarget();
	
}