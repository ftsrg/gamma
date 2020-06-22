package hu.bme.mit.gamma.util

import java.io.File
import java.util.Collections
import java.util.List
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.Path
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
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
	
	def void changeAndDelete(EObject newObject, EObject oldObject, EObject container) {
		change(newObject, oldObject, container)
		EcoreUtil.delete(oldObject) // Remove does not delete other references
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
		EcoreUtil.delete(oldObject)
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

	def boolean helperEquals(EObject lhs, EObject rhs) {
		val helper = new EqualityHelper
		return helper.equals(lhs, rhs)
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
			uri.toString
		}
		return new File(URI.decode(location))
	}
	
}