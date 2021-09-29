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
import java.util.Collection
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
	
	def void deleteAll(Collection<? extends EObject> objects) {
		EcoreUtil.deleteAll(objects, true)
	}
	
	def void remove(EObject object) {
		EcoreUtil.remove(object)
	}
	
	def <T extends EObject> removeContainmentChains(
			Collection<? extends T> removableElements, Class<? extends T> clazz) {
		val queue = newLinkedList
		queue += removableElements
		while (!queue.empty) {
			val removableElement = queue.poll
			val container = removableElement.eContainer
			removableElement.remove
			if (clazz.isInstance(container)) {
				if (container.eContents.empty) {
					queue += container as T
				}
			}
		}
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
	
	def void prependTo(EObject object, EObject pivot) {
		val container = pivot.eContainer
		val reference = pivot.eContainmentFeature
		// "Many" cardinality is mandatory
		val list = container.eGet(reference) as List<EObject>
		val index = pivot.index
		list.add(index, object)
	}
	
	def void prependTo(List<? extends EObject> objects, EObject pivot) {
		for (object : objects) {
			object.prependTo(pivot)
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
	
	def void appendTo(EObject pivot, List<? extends EObject> objects) {
		for (object : objects.reverseView) {
			pivot.appendTo(object)
		}
	}
	
	def List<EObject> getAllContainers(EObject object) {
		val container = object.eContainer
		if (container === null) {
			return newArrayList
		}
		val allContainers = container.allContainers
		allContainers += container
		return allContainers
	}
	
	def <T extends EObject> List<T> getAllContainersOfType(EObject object, Class<T> type) {
		return object.allContainers.filter(type).toList
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
	
	def <T extends EObject> T getSelfOrLastContainerOfType(T object, Class<T> type) {
		val container = object.eContainer
		if (!type.isInstance(container)) {
			return object
		}
		val validTypeContainer = container as T
		return validTypeContainer.getSelfOrLastContainerOfType(type)
	}
	
	def <T extends EObject> List<T> getContentsOfType(EObject object, Class<T> type) {
		return object.eContents.filter(type).toList
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
	
	def boolean containsTransitively(EObject potentialContainer, EObject object) {
		if (potentialContainer === null || object === null) {
			return false
		}
		val container = object.eContainer
		if (potentialContainer === container) {
			return true
		}
		return potentialContainer.containsTransitively(container)
	}
	
	def selfOrContainsTransitively(EObject potentialContainer, EObject object) {
		return potentialContainer === object || potentialContainer.containsTransitively(object)
	}
	
	def containsOneOtherTransitively(EObject lhs, EObject rhs) {
		return lhs.containsTransitively(rhs) || rhs.containsTransitively(lhs)
	}
	
	def EObject normalLoad(URI uri) {
		return uri.normalLoad(new ResourceSetImpl)
	}

	def EObject normalLoad(URI uri, ResourceSet resourceSet) {
		val resource = resourceSet.getResource(uri, true)
		return resource.getContents().get(0)
	}

	def EObject normalLoad(File file) {
		return normalLoad(file.parent, file.name)
	}
	
	def EObject normalLoad(File file, ResourceSet resourceSet) {
		return normalLoad(file.parent, file.name, resourceSet)
	}

	def EObject normalLoad(String parentFolder, String fileName) {
		return URI.createFileURI(parentFolder + File.separator + fileName).normalLoad
	}
	
	def EObject normalLoad(String parentFolder, String fileName, ResourceSet resourceSet) {
		return URI.createFileURI(parentFolder + File.separator + fileName).normalLoad(resourceSet)
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
		resource.save
	}
	
	def void save(Resource resource) {
		checkState(resource !== null)
		resource.save(Collections.EMPTY_MAP)
	}
	
	def void delete(Resource resource) {
		resource.delete(Collections.EMPTY_MAP)
	}
	
	def void deleteResource(EObject object) {
		object.eResource.delete(Collections.EMPTY_MAP)
	}
	
	def boolean helperEquals(List<? extends EObject> lhs, List<? extends EObject> rhs) {
		if (lhs === null && rhs === null) {
			return true
		}
		if (lhs === null && rhs !== null ||
				lhs !== null && rhs === null ||
				lhs.size != rhs.size) {
			return false
		}
		for (var i = 0; i < lhs.size; i++) {
			val lhsElement = lhs.get(i)
			val rhsElement = rhs.get(i)
			if (!lhsElement.helperEquals(rhsElement)) {
				return false
			}
		}
		return true
	}
	
	def boolean helperEquals(EObject lhs, EObject rhs) {
		val helper = new EqualityHelper
		return helper.equals(lhs, rhs)
	}
	
	def <T extends EObject> List<T> clone(List<T> objects) {
		if (objects === null) {
			return null
		}
		val list = newArrayList
		for (object : objects) {
			list += object.clone
		}
		return list
	}
	
	def <T extends EObject> T clone(T object) {
		return object.clone(true, true /* This parameter sets reference copying */)
	}
	
	def <T extends EObject> cloneAndChange(T oldObject, EObject container) {
		val newObject = oldObject.clone
		newObject.change(oldObject, container)
		return newObject
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
			val FILE_STRING = "file:"
			// Deleting file: from the beginning
			// Not deleting the trailing '/', as Linux needs it and Windows accepts it
			val uriString = uri.toString
			if (uriString.startsWith(FILE_STRING)) {
				uriString.substring((FILE_STRING/* + File.separator*/).length)
			}
			else {
				// It is not platform URI, and still does not start with file: - how?
				ResourcesPlugin.getWorkspace().getRoot().getFile(
					new Path(uriString)).location.toString
			}
		}
		return new File(URI.decode(location))
	}
	
	def hasPlatformUri(Resource resource) {
		return resource.URI.isPlatform
	}
	
	def getPlatformUri(String path) {
		val file = new File(path)
		return file.platformUri
	}
	
	def getPlatformUri(File file) {
		val projectFile = file.parentFile.projectFile
		val location = file.toString.substring(projectFile.parent.length)
		return URI.createPlatformResourceURI(location, true)
	}
	
	def getPlatformUri(Resource resource) {
		val uri = resource.URI
		if (uri.isPlatform) {
			return uri
		}
		val resourceFile = resource.file
		return resourceFile.platformUri
	}
	
	def getAbsoluteUri(Resource resource) {
		val uri = resource.URI
		if (!uri.isPlatform) {
			return resource
		}
		val resourceFile = resource.file
		return URI.createFileURI(resourceFile.toString)
	}
	
	def matchUri(String changableAbsoluteUri, Resource resource) {
		return changableAbsoluteUri.matchUri(resource.URI)
	}
	
	def matchUri(String changableAbsoluteUri, URI pivot) {
		if (pivot.isPlatform) {
			return changableAbsoluteUri.platformUri
		}
		return URI.createFileURI(changableAbsoluteUri)
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
	
	def isLast(EObject object) {
		val containingFeature = object.eContainingFeature
		val container = object.eContainer
		val get = container.eGet(containingFeature)
		if (get instanceof List) {
			return get.last == object
		}
		return true
	}
	
}