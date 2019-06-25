package hu.bme.mit.gamma.yakindu.transformation.commandhandler.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.IOException;
import java.util.Collections;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

import com.google.inject.Injector;

import hu.bme.mit.gamma.statechart.language.ui.internal.LanguageActivator;
import hu.bme.mit.gamma.statechart.language.ui.serializer.StatechartLanguageSerializer;
import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.yakindu.genmodel.CodeGeneration;
import hu.bme.mit.gamma.yakindu.genmodel.Task;
import hu.bme.mit.gamma.yakindu.genmodel.TestGeneration;

public abstract class TaskHandler {
	
	protected Logger logger = Logger.getLogger("GammaLogger");
	protected String targetFolderUri;

	public void setTargetFolder(Task task, IFile file, String parentFolderUri) {
		// E.g., C:/Users/...
		String projectLocation = file.getProject().getLocation().toString();
		checkArgument(task.getTargetFolder().size() <= 1);
		if (task.getTargetFolder().isEmpty()) {
			String targetFolder = null;
			if (task instanceof CodeGeneration) {
				targetFolder = "src-gen";
			}
			else if (task instanceof TestGeneration) {
				targetFolder = "test-gen";
			}
			else {
				targetFolder = parentFolderUri.substring(projectLocation.length() + 1);
			}
			task.getTargetFolder().add(targetFolder);
		}
		// Setting the attribute
		targetFolderUri = URI.decode(projectLocation + File.separator + task.getTargetFolder().get(0));
	}
	
	protected String getNameWithoutExtension(String fileName) {
		return fileName.substring(0, fileName.lastIndexOf("."));
	}
	
	protected String getContainingFileName(EObject object) {
		return object.eResource().getURI().lastSegment();
	}
	
	/**
	 * Responsible for saving the given element into a resource file.
	 */
	public void saveModel(EObject rootElem, String parentFolder, String fileName) throws IOException {
		if (rootElem instanceof Package) {
			// A Gamma statechart model
			try {
				// Trying to serialize the model
				serialize(rootElem, parentFolder, fileName);
			} catch (Exception e) {
				e.printStackTrace();
				logger.log(Level.WARNING, e.getMessage() + System.lineSeparator() +
						"Possibly you have two more model elements with the same name specified in the previous error message.");
				new File(parentFolder + File.separator + fileName).delete();
				// Saving like an EMF model
				String newFileName = fileName.substring(0, fileName.lastIndexOf(".")) + ".gsm";
				normalSave(rootElem, parentFolder, newFileName);
			}
		}
		else {
			// It is not a statechart model, regular saving
			normalSave(rootElem, parentFolder, fileName);
		}
	}

	protected void normalSave(EObject rootElem, String parentFolder, String fileName) throws IOException {
		ResourceSet resourceSet = new ResourceSetImpl();
		Resource saveResource = resourceSet.createResource(URI.createFileURI(URI.decode(parentFolder + File.separator + fileName)));
		saveResource.getContents().add(rootElem);
		saveResource.save(Collections.EMPTY_MAP);
	}
	
	private void serialize(EObject rootElem, String parentFolder, String fileName) throws IOException {
		// This is how an injected object can be retrieved
		Injector injector = LanguageActivator.getInstance()
				.getInjector(LanguageActivator.HU_BME_MIT_GAMMA_STATECHART_LANGUAGE_STATECHARTLANGUAGE);
		StatechartLanguageSerializer serializer = injector.getInstance(StatechartLanguageSerializer.class);
		serializer.save(rootElem, URI.decode(parentFolder + File.separator + fileName));
	}
	
}
