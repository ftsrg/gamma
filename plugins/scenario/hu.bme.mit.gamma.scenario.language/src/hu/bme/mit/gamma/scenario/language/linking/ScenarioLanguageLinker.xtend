package hu.bme.mit.gamma.scenario.language.linking

import com.google.inject.Inject
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioModelPackage
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.xtext.conversion.IValueConverterService
import org.eclipse.xtext.linking.impl.DefaultLinkingService
import org.eclipse.xtext.nodemodel.INode

class ScenarioLanguageLinker extends DefaultLinkingService {
		
    @Inject IValueConverterService valueConverterService;
    
    public static extension ScenarioModelPackage pack = ScenarioModelPackage.eINSTANCE
    
    override getLinkedObjects(EObject context, EReference ref, INode node) {
    	if (context instanceof ScenarioDeclaration) {
    		if (ref == scenarioDeclaration_Package) {
    			try {
		    		val root = context
		    		val path = valueConverterService.toValue(node.getText(),
		    				getLinkingHelper().getRuleNameFrom(node.getGrammarElement()), node).toString().replaceAll("\\s","")
		    		val rootResource = root.eResource()
		    		val resourceSet = rootResource.getResourceSet()
		    		// Adding the gcd extension, if needed
		    		var finalPath = addExtensionIfNeeded(path)
		    		if (!isCorrectPath(finalPath)) {
		    			// Path of the importer model
		    			val rootResourceUri = rootResource.getURI().toString()
		    			val pathBuilder = new StringBuilder(finalPath)
		    			// If the path starts with a '/', we delete it
		    			if (pathBuilder.charAt(0) == '/') {
		    				pathBuilder.deleteCharAt(0)
		    			}
		    			val splittedRootResourceUri = rootResourceUri.split("/")
		    			var originalCharacterIndex = 0
		    			for (var i = 0; i < splittedRootResourceUri.length && !isCorrectPath(pathBuilder.toString()); i++) {
		    				// Trying prepending the folders one by one
		    				val prepension = splittedRootResourceUri.get(i) + "/"
		    				pathBuilder.insert(originalCharacterIndex, prepension)
		    				originalCharacterIndex += prepension.length()
		    			}
		    			// Finished
		    			finalPath = pathBuilder.toString()
		    		}
		    		val uri = URI.createURI(finalPath)
		    		val importedResource = resourceSet.getResource(uri, true)
		    		val importedPackage = importedResource.getContents().get(0)
		    		return #[importedPackage]
		 		} catch (Exception e) {
    				// Trivial case most of the time (during typing) the uri is not correct, thus the loading cannot be done
    			}
    		}	
    	}
    	return super.getLinkedObjects(context, ref, node);
    }
    
    private def isCorrectPath(String path) {
    	if (!path.startsWith("platform:/resource/")) {
    		return false
    	}
    	val resourceSet = new ResourceSetImpl()
		val uri = URI.createURI(path)
		try {
	    	resourceSet.getResource(uri, true)
	    	resourceSet.getResources().get(0).unload()
	    	resourceSet.getResources().clear()
	    	return true
		} catch (Exception e) {
			// Resource cannot be loaded due to invalid path
			return false
		}
    }
    
    private def addExtensionIfNeeded(String path) {
    	val splittedPath = path.split("/")
    	val fileName = splittedPath.get(splittedPath.length - 1)
    	val splittedFileName = fileName.split("\\.")
    	if (splittedFileName.length == 1) {
    		return path + ".gcd"
    	}
    	return path
    }
    
}