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
package hu.bme.mit.gamma.trace.language.ui.serializer

import com.google.inject.Inject
import hu.bme.mit.gamma.trace.language.TraceLanguageStandaloneSetup
import java.io.IOException
import java.util.Collections
import java.util.HashSet
import java.util.Set
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.resource.XtextResourceSet

class TraceLanguageSerializer {
	
	XtextResourceSet resourceSet;

	protected static int staticInitializer = {
		// Should not be used, but serializeation does not work without it
		TraceLanguageStandaloneSetup.doSetup() 
		return 1
	}

	@Inject
	new(XtextResourceSet resourceSet) {
		this.resourceSet = resourceSet
		this.resourceSet.addLoadOption(XtextResource.OPTION_RESOLVE_ALL, Boolean.TRUE)
	}
	
	private def void resolveResources(EObject object, Set<Resource> resolvedResources) {
		for (EObject crossObject : object.eCrossReferences) {
			val resource = crossObject.eResource
			if (resource !== null && !resolvedResources.contains(resource)) {
				resourceSet.getResource(resource.getURI(), true)
				resolvedResources.add(resource)
			}
			resolveResources(crossObject, resolvedResources)
		}
		for (EObject containedObject : object.eContents) {
			resolveResources(containedObject, resolvedResources)
		}
	}

	def save(EObject object, String fileName) throws IOException {
		val traceUri = URI.createFileURI(fileName)
		// Theoretically, all referenced resources must be in the resource set
		object.resolveResources(new HashSet<Resource>) // Should be removed but does not work without this
		val traceResource = resourceSet.createResource(traceUri)
		traceResource.getContents().add(object)
		traceResource.save(Collections.EMPTY_MAP)
	}
}