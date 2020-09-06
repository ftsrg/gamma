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
package hu.bme.mit.gamma.util

import java.io.File
import java.util.Collections
import java.util.List
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.Path
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.ecore.util.EcoreUtil.Copier
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper
import org.eclipse.emf.ecore.util.EcoreUtil.UsageCrossReferencer

import static com.google.common.base.Preconditions.checkState

class GammaEcoreUtil {
	// Singleton
	public static final GammaEcoreUtil INSTANCE =  new GammaEcoreUtil
	protected new() {}
	//
	
	def void replace(EObject newObject, EObject oldObject) {
		EcoreUtil.replace(oldObject, newObject)
	}
	
	/**
	 * Note that this is used only to change cross-references and not containments.
	 */
	@SuppressWarnings("unchecked")
	def void change(EObject newObject, EObject oldObject, EObject container) {
		val oldReferences = UsageCrossReferencer.find(oldObject, container)
		for (oldReference : oldReferences) {
			val referenceHolder = oldReference.get(true)
			if (referenceHolder instanceof List) {
				val list =  referenceHolder as List<EObject>
				val index = list.indexOf(oldObject)
				if (list.contains(newObject)) {
					// To avoid 'no duplicates' constraint violation
					list.remove(index)
				}
				else {
					list.set(index, newObject)
				}
			}
			else {
				oldReference.set(newObject)
			}
		}
	}
	
	def void delete(EObject object) {
		EcoreUtil.delete(object)
	}
	
	def void remove(EObject object) {
		EcoreUtil.remove(object)
	}
	
	def void changeAndDelete(EObject newObject, EObject oldObject, EObject container) {
		change(newObject, oldObject, container)
		oldObject.delete // Remove does not delete other references
	}
	
	def void changeAll(EObject newObject, EObject oldObject, EObject container) {
		change(newObject, oldObject, container)
		val lhsContents = newObject.eAllContents
		val rhsContents = oldObject.eAllContents
		while (lhsContents.hasNext()) {
			val lhs = lhsContents.next
			val rhs = rhsContents.next
			change(lhs, rhs, container)
		}
		checkState(!rhsContents.hasNext)
	}
	
	def void changeAllAndDelete(EObject newObject, EObject oldObject, EObject container) {
		changeAll(newObject, oldObject, container)
		oldObject.delete
	}
	
	def void add(EObject container, EReference reference, EObject object) {
		val referenceObject = container.eGet(reference)
		if (referenceObject instanceof List) {
			referenceObject += object
		}
		else {
			container.eSet(reference, object)
		}
	}
	
	def void appendTo(EObject pivot, EObject object) {
		val container = pivot.eContainer
		val reference = pivot.eContainmentFeature
		// "Many" cardinality is mandatory
		val list = container.eGet(reference) as List<EObject>
		val index = pivot.index + 1
		list.add(index, object)
	}
	
	def <T extends EObject> T getSelfOrContainerOfType(EObject object, Class<T> type) {
		if (type.isInstance(object)) {
			return object as T
		}
		return object.getContainerOfType(type)
	}
	
	def EObject getRoot(EObject object) {
		return EcoreUtil.getRootContainer(object)
	}
	
	def <T extends EObject> T getContainerOfType(EObject object, Class<T> type) {
		val container = object.eContainer
		if (container === null) {
			return null
		}
		if (type.isInstance(container)) {
			return container as T
		}
		return container.getContainerOfType(type)
	}
	
	def <T extends EObject> List<T> getAllContentsOfType(EObject object, Class<T> type) {
		val contents = <T>newArrayList
		val iterator = object.eAllContents
		while (iterator.hasNext) {
			val content = iterator.next
			if (type.isInstance(content)) {
				contents += content as T
			}
		}
		return contents
	}

	def <T extends EObject> List<T> getSelfAndAllContentsOfType(EObject object, Class<T> type) {
		val contents = object.getAllContentsOfType(type)
		if (type.isInstance(object)) {
			contents += object as T
		}
		return contents
	}

	def EObject normalLoad(URI uri) {
		val resourceSet = new ResourceSetImpl
		val resource = resourceSet.getResource(uri, true)
		return resource.getContents().get(0)
	}

	def EObject normalLoad(String parentFolder, String fileName) {
		return normalLoad(URI.createFileURI(parentFolder + File.separator + fileName))
	}

	def Resource normalSave(ResourceSet resourceSet, EObject rootElem, URI uri) {
		val resource = resourceSet.createResource(uri)
		resource.getContents().add(rootElem)
		resource.save(Collections.EMPTY_MAP)
		return resource
	}

	def Resource normalSave(ResourceSet resourceSet, EObject rootElem, String parentFolder, String fileName) {
		val uri = URI.createFileURI(parentFolder + File.separator + fileName)
		return normalSave(resourceSet, rootElem, uri)
	}

	def Resource normalSave(EObject rootElem, URI uri) {
		return normalSave(new ResourceSetImpl(), rootElem, uri)
	}

	def Resource normalSave(EObject rootElem, String parentFolder, String fileName) {
		return normalSave(new ResourceSetImpl(), rootElem, parentFolder, fileName)
	}

	def void save(EObject rootElem) {
		val resource = rootElem.eResource
		checkState(resource !== null)
		resource.save(Collections.EMPTY_MAP)
	}

	def boolean helperEquals(EObject lhs, EObject rhs) {
		val helper = new EqualityHelper
		return helper.equals(lhs, rhs)
	}

	def <T extends EObject> T clone(T object) {
		return object.clone(true, true)
	}

	@SuppressWarnings("unchecked")
	def <T extends EObject> T clone(T object, boolean a, boolean b) {
		// A new copier should be user every time, otherwise anomalies happen
		// (references are changed without asking)
		val copier = new Copier(a, b)
		val clone = copier.copy(object)
		copier.copyReferences
		return clone as T
	}
	
	def getFile(Resource resource) {
		val uri = resource.URI
		val location =
		if (uri.isPlatform) {
			ResourcesPlugin.getWorkspace().getRoot().getFile(
				new Path(uri.toPlatformString(true))
			).location.toString
		}
		else {
			// Deleting file: from the beginning
			// Not deleting the trailing '/', as Linux needs it and Windows accepts it
			uri.toString.substring(("file:"/* + File.separator*/).length)
		}
		return new File(URI.decode(location))
	}
	
	def getPlatformUri(Resource resource) {
		val uri = resource.URI
		if (uri.isPlatform) {
			return uri
		}
		val resourceFile = resource.file
		val projectFile = resourceFile.parentFile.projectFile
		val location = resourceFile.toString.substring(projectFile.parent.length)
		return URI.createPlatformResourceURI(location, true)
	}
	
	def getAbsoluteUri(Resource resource) {
		val uri = resource.URI
		if (!uri.isPlatform) {
			return resource
		}
		val resourceFile = resource.file
		return URI.createFileURI(resourceFile.toString)
	}
	
	def File getProjectFile(File file) {
		val containedFileNames = file.listFiles.map[it.name]
		if (containedFileNames.contains(".project")) {
			return file
		}
		return file.parentFile.projectFile
	}
	
	def getIndex(EObject object) {
		val containingFeature = object.eContainingFeature
		val container = object.eContainer
		val list = container.eGet(containingFeature) as List<EObject>
		return list.indexOf(object)
	}
	
}