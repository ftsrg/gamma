/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
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
import java.io.File
import org.eclipse.emf.ecore.resource.Resource

import static com.google.common.base.Preconditions.checkNotNull

class StatechartEcoreUtil {
	// Singleton
	public static final StatechartEcoreUtil INSTANCE =  new StatechartEcoreUtil
	protected new() {}
	//
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	def loadAndReplaceToOriginalComponent(Component unfoldedComponent) {
		val unfoldedPackageFile = unfoldedComponent.eResource.file
		val unfoldedPackagePath = unfoldedPackageFile.absolutePath
		
		val originalGsmComponentAbsoluteUri = unfoldedPackagePath.originalGsmComponentUri
		val originalGcdComponentAbsoluteUri = unfoldedPackagePath.originalGcdComponentUri
		
		val isGcd = new File(originalGcdComponentAbsoluteUri).exists
		
		val originalComponentAbsoluteUri = isGcd ? originalGcdComponentAbsoluteUri :
				originalGsmComponentAbsoluteUri
		
		val unfoldedResource = unfoldedComponent.eResource
		val unfoldedResourceSet = unfoldedResource.resourceSet
		val resources = unfoldedResourceSet.resources
		resources -= unfoldedResource // Necessary?
		
		// Does not work if the interfaces/types are loaded into different resources
		// Resource set and URI type (absolute/platform) must match
//		checkState(resources.checkUriTypes, "The resource URIs are not all consistently platform or absolute")
		val matchResource = (resources.nullOrEmpty) ? unfoldedResource : resources.head
		
		val originalMatchedUri = originalComponentAbsoluteUri.matchUri(matchResource)
		// Is this 'URI matching' necessary? So far, it has not worked and the problem
		// (that is, the interfaces are reloaded twice into the resource set -
		// file-URI for unfolded and and platform-URI for the original package)
		// has been solved by back-annotating the events, too
		
		val originalPackage = originalMatchedUri.normalLoad(unfoldedResourceSet) as Package
		val originalComponent = originalPackage.components.findFirst[it.name == unfoldedComponent.name]
		checkNotNull(originalComponent)
		
		return originalComponent
	}
	
	private def checkUriTypes(Iterable<? extends Resource> resources) {
		return resources.forall[it.hasPlatformUri] || // All platform, or
				resources.forall[!it.hasPlatformUri] // All absolute
	}
	
}