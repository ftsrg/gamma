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

import java.io.IOException;
import java.util.Collections;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.resource.XtextResource;
import org.eclipse.xtext.resource.XtextResourceSet;

import com.google.inject.Inject;

public class GammaLanguageSerializer {

	private XtextResourceSet resourceSet;

	@Inject
	public GammaLanguageSerializer(XtextResourceSet resourceSet) {
		this.resourceSet = resourceSet;
		this.resourceSet.addLoadOption(XtextResource.OPTION_RESOLVE_ALL, Boolean.TRUE);
	}
	
//	private void resolveResources(EObject object, Set<Resource> resolvedResources) {
//		for (EObject crossObject : object.eCrossReferences()) {
//			Resource resource = crossObject.eResource();
//			if (resource != null && !resolvedResources.contains(resource)) {
//				resourceSet.getResource(resource.getURI(), true);
//				resolvedResources.add(resource);
//			}
//			resolveResources(crossObject, resolvedResources);
//		}
//		for (EObject containedObject : object.eContents()) {
//			resolveResources(containedObject, resolvedResources);
//		}
//	}

	public void save(EObject object, String fileUri) throws IOException {
		URI fileURI = URI.createFileURI(fileUri);
		save(object, fileURI);
	}
	
	public void save(EObject object, URI uri) throws IOException {
		// Theoretically, all referenced resources must be in the resource set
//		resolveResources(object, new HashSet<Resource>());
		// Tried using getResource instead of createResource. Unfortunately, it did not solve the import problem
		// (automatic update of import reference to the new serialized model and thus, the new contained object elements).
		Resource resource = resourceSet.createResource(uri);
		resource.getContents().add(object);
		resource.save(Collections.EMPTY_MAP);
	}
	
}