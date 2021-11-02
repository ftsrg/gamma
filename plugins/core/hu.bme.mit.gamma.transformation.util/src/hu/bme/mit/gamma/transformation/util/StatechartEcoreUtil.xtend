/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.util.GammaEcoreUtil
import org.eclipse.emf.ecore.resource.Resource

import static com.google.common.base.Preconditions.checkState

class StatechartEcoreUtil {
	// Singleton
	public static final StatechartEcoreUtil INSTANCE =  new StatechartEcoreUtil
	protected new() {}
	//
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	def loadOriginalComponent(Component unfoldedComponent) {
		val unfoldedPackageFile = unfoldedComponent.eResource.file
		val unfoldedPackagePath = unfoldedPackageFile.absolutePath
		
		val originalComponentAbsoluteUri = unfoldedPackagePath.originalComponentUri
		
		val unfoldedResource = unfoldedComponent.eResource
		val resourceSet = unfoldedResource.resourceSet
		val gcdResources = resourceSet.resources
				.filter[it.URI.fileExtension == GammaFileNamer.PACKAGE_XTEXT_EXTENSION]
		
		// Does not work if the interfaces/types are loaded into different resources
		// Resource set and URI type (absolute/platform) must match
		checkState(gcdResources.checkUriTypes, "The gcd URIs are not all consistently platform or absolute")
		val matchResource = (gcdResources.nullOrEmpty) ? unfoldedResource : gcdResources.head
		
		val originalMatchedUri = originalComponentAbsoluteUri.matchUri(matchResource)
		
		val originalPackage = originalMatchedUri.normalLoad(resourceSet) as Package
		val originalComponent = originalPackage.components.findFirst[it.name == unfoldedComponent.name]
		
		return originalComponent
	}
	
	private def checkUriTypes(Iterable<? extends Resource> resources) {
		return resources.forall[it.hasPlatformUri] || // All platform, or
			resources.forall[!it.hasPlatformUri] // All absolute
	}
	
}