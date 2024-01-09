/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.language.util.linking;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.xtext.conversion.IValueConverterService;
import org.eclipse.xtext.linking.impl.DefaultLinkingService;
import org.eclipse.xtext.linking.lazy.LazyLinkingResource.CyclicLinkingException;
import org.eclipse.xtext.nodemodel.INode;

import com.google.inject.Inject;

public abstract class GammaLanguageLinker extends DefaultLinkingService {

	@Inject IValueConverterService valueConverterService;
	
	public List<EObject> getLinkedObjects(EObject context, EReference ref, INode node) {
		Map<Class<? extends EObject>, Collection<EReference>> context2 = getContext();
		for (Entry<Class<? extends EObject>, Collection<EReference>> entry : context2.entrySet()) {
			Class<? extends EObject> clazz = entry.getKey();
			Collection<EReference> references = entry.getValue();
			if (clazz.isInstance(context) && references.contains(ref)) {
				try {
					String path = valueConverterService.toValue(node.getText(),
							getLinkingHelper().getRuleNameFrom(node.getGrammarElement()), node).toString().replaceAll("\\s","");
					Resource rootResource = context.eResource();
					ResourceSet resourceSet = rootResource.getResourceSet();
					// Adding the gcd extension, if needed
					String finalPath = addExtensionIfNeeded(path);
					if (!isCorrectPath(finalPath)) {
						// Path of the importer model
						String rootResourceUri = rootResource.getURI().toString();
						StringBuilder pathBuilder = new StringBuilder(finalPath);
						// If the path starts with a '/', we delete it
						if (pathBuilder.charAt(0) == '/') {
							pathBuilder.deleteCharAt(0);
						}
						String[] splittedRootResourceUri = rootResourceUri.split("/");
						int originalCharacterIndex = 0;
						for (int i = 0; i < splittedRootResourceUri.length && !isCorrectPath(pathBuilder.toString()); ++i) {
							// Trying prepending the folders one by one
							String prepension = splittedRootResourceUri[i] + "/";
							pathBuilder.insert(originalCharacterIndex, prepension);
							originalCharacterIndex += prepension.length();
						}
						// Finished
						finalPath = pathBuilder.toString();
					}
					URI uri = URI.createURI(finalPath);
					Resource importedResource = resourceSet.getResource(uri, true);
					// return importedResource.getContents(); would result in an Xtext exception
					// if there is more than one root element in the resource
					EObject importedPackage = importedResource.getContents().get(0);
					return List.of(importedPackage);
				} catch (Exception e) {
					// Trivial case: most of the time (during typing) the uri is not correct, thus the loading cannot be done
				}
			}
		}
		try {
			return super.getLinkedObjects(context, ref, node);
		} catch (CyclicLinkingException e) {
			return List.of(); // The import URI is incorrect, there is nothing we can do
		}
	}
	
	public abstract Map<Class<? extends EObject>, Collection<EReference>> getContext();
	
	private boolean isCorrectPath(String path) {
		ResourceSet resourceSet = new ResourceSetImpl();
		URI uri = URI.createURI(path);
		try {
			resourceSet.getResource(uri, true);
			List<Resource> resources = resourceSet.getResources();
			resources.stream().forEach(it -> it.unload());
			resources.clear();
			resourceSet = null;
			return true;
		} catch (Exception e) {
//			Throwable cause = e.getCause();
//			if (cause instanceof FileNotFoundException || 
//					cause instanceof MalformedURLException ||
//					cause instanceof ResourceException ||
//					cause instanceof IllegalArgumentException) { // Yakindu
				// Resource cannot be loaded due to invalid path
				return false;
//			}
//			throw e;
		}
	}
	
	// Could be abstract, too
	private String addExtensionIfNeeded(String path) {
		String[] splittedPath = path.split("/");
		String fileName = splittedPath[splittedPath.length - 1];
		String[] splittedFileName = fileName.split("\\.");
		if (splittedFileName.length == 1) {
			return path + ".gcd";
		}
		return path;
	}
	
}