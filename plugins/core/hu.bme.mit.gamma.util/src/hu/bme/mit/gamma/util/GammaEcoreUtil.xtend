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
package hu.bme.mit.gamma.util

import java.io.File
import java.util.Collection
import java.util.Collections
import java.util.Comparator
import java.util.Iterator
import java.util.List
import java.util.logging.Level
import java.util.logging.Logger
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
	public static final GammaEcoreUtil INSTANCE = new GammaEcoreUtil
	protected new() {}
	//
	protected final FileUtil fileUtil = FileUtil.INSTANCE
	protected final Logger logger = Logger.getLogger("GammaLogger")
	//
	
	def void replace(EObject newObject, EObject oldObject) {
		EcoreUtil.replace(oldObject, newObject)
	}
	
	def isReferenced(EObject target, EObject container) {
		val settings = UsageCrossReferencer.find(target, container)
		return !settings.empty
	}
	
	def inlineReferences(EObject target, EObject newObject, EObject container) {
		val settings = UsageCrossReferencer.find(target, container).toSet
		for (setting : settings) {
			val referenceHolder = setting.EObject // The EObject from which the reference is made
			val clonedNewObject = newObject.clone
			clonedNewObject.replace(referenceHolder)
		}
	}
	
	def void replaceEachOther(EObject left, EObject right) {
		val dummy = EcoreUtil.create(left.eClass) // Empty object
		dummy.replace(left)
		left.replace(right)
		right.replace(dummy)
	}
	
	def void changeAndReplaceEachOther(EObject left, EObject right,
			EObject leftRoot, EObject rightRoot) {
		val dummy = EcoreUtil.create(left.eClass) // Empty object
		dummy.changeAndReplace(left, leftRoot)
		left.changeAndReplace(right, rightRoot)
		right.changeAndReplace(dummy, leftRoot)
	}
	
	def void changeAndReplaceEachOther(EObject left, EObject right, EObject root) {
		left.changeAndReplaceEachOther(right, root)
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
				try {
					if (list.contains(newObject)) {
						// To avoid 'no duplicates' constraint violation
						list.remove(index)
					}
					else {
						list.set(index, newObject)
					}
				} catch (UnsupportedOperationException e) {
					// Derived feature, cannot be changed
					logger.log(Level.WARNING, "Reference from " + oldObject
						+ " to " + newObject + " in " + container + " cannot be changed")
				}
			}
			else {
				oldReference.set(newObject)
			}
		}
	}
	
	def void change(EObject newObject, EObject oldObject, Iterable<? extends EObject> containers) {
		for (container : containers) {
			newObject.change(oldObject, container)
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
	
	def void removeAll(Collection<? extends EObject> list) {
		EcoreUtil.removeAll(list)
	}
	
	def void removeAllButFirst(List<? extends EObject> list) {
		for (var i = 1; i < list.size; /* No op */) {
			val object = list.get(i)
			object.remove
		}
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
				if (!container.eContents.empty) {
					logger.log(Level.WARNING, "The content is not empty")
				}
				queue += container as T
			}
		}
	}
	
	def <T extends EObject> void moveUpContainmentChainUntilType(EObject object, Class<? extends T> clazz) {
		val container = object.eContainer
		if (clazz.isInstance(container)) {
			return
		}
		object.replace(container)
		object.removeContainmentChainUntilType(clazz)
	}
	
	def <T extends EObject> void removeContainmentChainUntilType(EObject object, Class<? extends T> clazz) {
		val container = object.eContainer
		if (clazz.isInstance(container)) {
			object.remove
			return
		}
		container.removeContainmentChainUntilType(clazz)
	}
	
	def void changeAndReplace(EObject newObject, EObject oldObject, EObject container) {
		change(newObject, oldObject, container)
		newObject.replace(oldObject)
	}
	
	def void changeAndDelete(EObject newObject, EObject oldObject, EObject container) {
		change(newObject, oldObject, container)
		oldObject.delete // 'Remove' does not delete other references
	}
	
	def void changeSelfAndContents(EObject newObject, EObject oldObject, Iterable<? extends EObject> containers) {
		for (container : containers) {
			newObject.changeSelfAndContents(oldObject, container)
		}
	}
	
	def void changeSelfAndContents(EObject newObject, EObject oldObject, EObject container) {
		change(newObject, oldObject, container)
		val lhsContents = newObject.eContents // Single level
		val rhsContents = oldObject.eContents // Single level
		lhsContents.change(rhsContents, container)
	}
	
	def void changeAll(EObject newObject, EObject oldObject, Iterable<? extends EObject> containers) {
		for (container : containers) {
			newObject.changeAll(oldObject, container)
		}
	}
	
	def void changeAll(EObject newObject, EObject oldObject, EObject container) {
		change(newObject, oldObject, container)
		val lhsContents = newObject.eAllContents // All
		val rhsContents = oldObject.eAllContents // All
		lhsContents.change(rhsContents, container)
	}
	
	def change(Iterable<? extends EObject> newObjects,
			Iterable<? extends EObject> oldObjects, Iterable<? extends EObject> containers) {
		for (container : containers) {
			newObjects.iterator.change(oldObjects.iterator, container)
		}
	}
	
	def change(Iterable<? extends EObject> newObjects,
			Iterable<? extends EObject> oldObjects, EObject container) {
		newObjects.iterator.change(oldObjects.iterator, container)
	}
	
	def change(Iterator<? extends EObject> newObjects,
			Iterator<? extends EObject> oldObjects, Iterable<? extends EObject> containers) {
		for (container : containers) {
			newObjects.change(oldObjects, container)
		}
	}
	
	def change(Iterator<? extends EObject> newObjects,
			Iterator<? extends EObject> oldObjects, EObject container) {
		while (newObjects.hasNext) {
			val lhs = newObjects.next
			val rhs = oldObjects.next
			change(lhs, rhs, container)
		}
		checkState(!oldObjects.hasNext)
	}
	
	def void changeAllAndDelete(EObject newObject, EObject oldObject, EObject container) {
		changeAll(newObject, oldObject, container)
		oldObject.delete
	}
	
	def void changeAllAndRemove(EObject newObject, EObject oldObject, EObject container) {
		changeAll(newObject, oldObject, container)
		oldObject.remove
	}
	
	//
	
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
	
	def copyContent(EObject source, EObject target) {
		source.clone.transferContent(target)
	}
	
	def transferContent(EObject source, EObject target) {
		val contents = newArrayList
		contents += source.eContents
		for (object : contents) {
			val containingFeature = object.eContainmentFeature
			val targetElement = target.eGet(containingFeature)
			if (targetElement instanceof List) {
				// "Many" cardinality
				targetElement += object
			}
			else {
				// "Single" cardinality
				checkState(targetElement === null)
				target.eSet(containingFeature, object)
			}
		}
	}
	
	//
	
	def <T extends EObject> List<T> getAllContainersOfType(EObject object, Class<T> type) {
		return object.allContainers.filter(type)
				.toList
	}
	
	def <T extends EObject> List<T> getSelfAndAllContainersOfType(T object, Class<T> type) {
		val elements = newArrayList
		elements += object.getAllContainersOfType(type)
		elements += object
		return elements
	}
	
	def <T extends EObject> boolean isDirectlyContainedBy(EObject object, Class<T> type) {
		val container = object.eContainer
		return type.isInstance(container)
	}
	
	def <T extends EObject> boolean isContainedBy(EObject object, Class<T> type) {
		val container = object.eContainer
		if (container === null) {
			return false
		}
		if (type.isInstance(container)) {
			return true
		}
		return container.isContainedBy(type)
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
	
	def <T extends EObject> boolean hasContainerOfType(EObject object, Class<T> type) {
		return object.getContainerOfType(type) !== null
	}
	
	def <T extends EObject> T getSelfOrLastContainerOfType(T object, Class<T> type) {
		val container = object.eContainer
		if (!type.isInstance(container)) {
			return object
		}
		val validTypeContainer = container as T
		return validTypeContainer.getSelfOrLastContainerOfType(type)
	}
	
	def <T extends EObject> EObject getChildOfContainerOfType(EObject object, Class<T> type) {
		val container = object.eContainer
		
		if (container === null) {
			return null
		}
		
		if (type.isInstance(container)) {
			return object
		}
		return container.getChildOfContainerOfType(type)
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
	
	def <T extends EObject> List<T> getSelfAndAllContentsOfType(
			Collection<? extends EObject> objects, Class<T> type) {
		val contents = newArrayList
		
		for (object : objects) {
			contents += object.getSelfAndAllContentsOfType(type)
		}
		
		return contents
	}
	
	def <T extends EObject, E extends EObject> List<E> getAllContentsOfTypeBetweenTypes(EObject object,
			Class<T> typeRootAndLeaf, Class<E> typeElement) {
		val root = object.getSelfOrContainerOfType(typeRootAndLeaf)
		
		val contents = newArrayList
		contents += root.getAllContentsOfType(typeElement)
		
		// We consider levels of elements between the root and the leaf type
		for (var iterator = contents.iterator; iterator.hasNext; ) {
			val elem = iterator.next
			if (elem.getSelfOrContainerOfType(typeRootAndLeaf) !== root) {
				iterator.remove
			}
		}
		
		return contents
	}
	
	def <T extends EObject> T getFirstOfAllContentsOfType(EObject object, Class<T> type) {
		val contents = newLinkedList
		contents += object.eContents
		while (!contents.empty) {
			val content = contents.poll
			if (type.isInstance(content)) {
				return content as T
			}
			else {
				contents += content.eContents
			}
		}
		return null
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
	
	def <T extends EObject> boolean isOrContainsTypesTransitively(EObject container, Iterable<? extends Class<T>> types) {
		return container.isTypes(types) || container.containsTypesTransitively(types)
	}
	
	def <T extends EObject> boolean isOrContainsTypesTransitively(EObject container, Class<T> type) {
		return type.isInstance(container) || container.containsTypeTransitively(type)
	}
	
	def <T extends EObject> boolean containsTypesTransitively(EObject container,
			Iterable<? extends Class<T>> types) {
		for (content : container.eAllContents.toIterable) {
			if (content.isTypes(types)) {
				return true
			}
		}
		return false
	}
	
	def <T extends EObject> boolean containsTypeTransitively(EObject container, Class<T> type) {
		return container.containsTypesTransitively(#[type])
	}
	
	def <T extends EObject> boolean containsTypes(EObject container, Iterable<? extends Class<T>> types) {
		for (content : container.eContents) {
			if (content.isOrContainsTypes(types)) {
				return true
			}
		}
		return false
	}
	
	def <T extends EObject> boolean isOrContainsTypes(EObject container,
			Iterable<? extends Class<T>> types) {
		return container.isTypes(types) || container.containsTypes(types)
	}
	
	def <T extends EObject> boolean isTypes(EObject object, Iterable<? extends Class<T>> types) {
		return types.exists[it.isInstance(object)]
	}
	
	def <T extends EObject> boolean containsType(EObject container, Class<T> type) {
		return container.containsTypes(#[type])
	}
	
	def <T extends EObject> boolean isOrContainsType(EObject container, Class<T> type) {
		return container.isOrContainsTypes(#[type])
	}
	
	//
	
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
		return URI.createFileURI(parentFolder + File.separator + fileName)
				.normalLoad
	}
	
	def EObject normalLoad(String parentFolder, String fileName, ResourceSet resourceSet) {
		return URI.createFileURI(parentFolder + File.separator + fileName)
				.normalLoad(resourceSet)
	}
	
	def void resolveAll(ResourceSet resourceSet) {
		EcoreUtil.resolveAll(resourceSet)
	}

	def Resource normalSave(ResourceSet resourceSet, EObject rootElem, URI uri) {
		val resource = resourceSet.createResource(uri)
		resource.getContents().add(rootElem)
		resource.save(Collections.EMPTY_MAP)
		return resource
	}

	def Resource normalSave(ResourceSet resourceSet, EObject rootElem,
			String parentFolder, String fileName) {
		// Save is always absolute
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
	
	//
	
	def boolean helperDisjoint(List<? extends EObject> lhs, List<? extends EObject> rhs) {
		for (var i = 0; i < lhs.size; i++) {
			for (var j = 0; j < rhs.size; j++) {
				val lhsElement = lhs.get(i)
				val rhsElement = rhs.get(j)
				if (lhsElement.helperEquals(rhsElement)) {
					return false
				}
			}
		}
		return true
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
	
	def boolean allHelperEquals(List<? extends EObject> objects) {
		for (var i = 0; i < objects.size - 1; i++) {
			val lhs = objects.get(i)
			val rhs = objects.get(i + 1)
			if (!lhs.helperEquals(rhs)) {
				return false;
			}
		}
		return true;
	}
	
	def <T extends EObject> List<T> clone(Iterable<T> objects) {
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
			ResourcesPlugin.workspace.root.getFile(
				new Path(uri.toPlatformString(true)))
			.location.toString
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
				ResourcesPlugin.workspace.root.getFile(
					new Path(uriString)).location.toString
			}
		}
		return new File(
			URI.decode(location))
	}
	
	def getWorkspace() {
		ResourcesPlugin.workspace.root.location
	}
	
	def getFile(EObject object) {
		val resource = object.eResource
		return resource.file
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
		if (projectFile === null) {
			throw new IllegalStateException("Containing project not found for " + file.absolutePath +
				". Add the artifacts into a valid Eclipse project containing a .project file.")
		}
		
		val projectName = file.projectName
		val location = projectName +
			file.toString.substring(projectFile.toString.length)
		
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
			return uri
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
	
	def File getProjectFile(Resource resource) {
		val file = resource.file
		return file.projectFile
	}
	
	def File getProjectFile(EObject object) {
		val resource = object.eResource
		return resource.projectFile
	}
	
	def File getProjectFile(URI uri) {
		val fileString = uri.toFileString
		val file = new File (fileString)
		
		return file.projectFile
	}
	
	def File getProjectFile(File file) {
		if (file === null) {
			return null
		}
		
		val containedFileNames = newHashSet
		val listedFiles = file.listFiles
		if (!listedFiles.nullOrEmpty) {
			containedFileNames += listedFiles.map[it.name]
		}
		if (containedFileNames.contains(".project")) {
			return file
		}
		return file.parentFile.projectFile
	}
	
	def String getProjectName(File file) {
		val projectFile = file.projectFile
		if (projectFile === null) {
			return null
		}
		
		val _projectFile = projectFile.listFiles
				.filter[it.name == ".project"].head
		
		val xml = fileUtil.loadXml(_projectFile)
		
		val nameNode = xml.getElementsByTagName("name").item(0)
		val name = nameNode.textContent
		
		return name
	}
	
	def int getContainmentLevel(EObject object) {
		val container = object.eContainer
		if (container === null) {
			return 0
		}
		return container.containmentLevel + 1
	}
	
	def getIndex(EObject object) {
		val containingFeature = object.eContainingFeature
		val container = object.eContainer
		val list = container.eGet(containingFeature) as List<EObject>
		return list.indexOf(object)
	}
	
	def getIndexOrZero(EObject object) {
		try {
			return object.index
		} catch (Exception e) {
			return 0
		}
	}
	
	def isContainedByList(EObject object) {
		val containingFeature = object.eContainingFeature
		val container = object.eContainer
		val get = container.eGet(containingFeature)
		return get instanceof List
	}
	
	def isFirst(EObject object) {
		val containingFeature = object.eContainingFeature
		val container = object.eContainer
		val get = container.eGet(containingFeature)
		if (get instanceof List) {
			return get.get(0) == object
		}
		return true
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
	
	def getPrevious(EObject object) {
		val containingFeature = object.eContainingFeature
		val container = object.eContainer
		val get = container.eGet(containingFeature)
		if (get instanceof List) {
			return get.get(object.index - 1)
		}
		throw new IllegalArgumentException("Not a list: " + get)
	}
	
	def getNext(EObject object) {
		val containingFeature = object.eContainingFeature
		val container = object.eContainer
		val get = container.eGet(containingFeature)
		if (get instanceof List) {
			return get.get(object.index + 1)
		}
		throw new IllegalArgumentException("Not a list: " + get)
	}
	
	def <T extends EObject> List<T> sortAccordingToReferences(List<T> list) {
		val array = newArrayList
		array += list
		array.sort(
			new Comparator<T>() {
				override compare(T lhs, T rhs) {
					val lhsReferences = lhs.eCrossReferences
					val rhsReferences = rhs.eCrossReferences
					// We do not handle circular references
					if (lhsReferences.contains(rhs)) {
						return 1
					}
					if (rhsReferences.contains(lhs)) {
						return -1
					}
					return 0
				}
			}
		)
		return array
	}
	
	def <T extends EObject> void removeEqualElements(List<T> list) {
		for (var i = 0; i < list.size - 1; i++) {
			for (var j = i + 1; j < list.size; j++) {
				val lhs = list.get(i)
				val rhs = list.get(j)
				
				if (lhs.helperEquals(rhs)) {
					list.remove(j) // Remove rhs
					j--
				}
			}
		}
	}
	
}