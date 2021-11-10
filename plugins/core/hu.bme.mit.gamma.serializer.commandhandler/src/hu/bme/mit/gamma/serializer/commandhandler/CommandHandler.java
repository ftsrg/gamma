package hu.bme.mit.gamma.serializer.commandhandler;

import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.property.language.ui.serializer.PropertyLanguageSerializer;
import hu.bme.mit.gamma.statechart.language.ui.serializer.StatechartLanguageSerializer;
import hu.bme.mit.gamma.trace.language.ui.serializer.TraceLanguageSerializer;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;

public class CommandHandler extends AbstractHandler {
	
	protected final GammaFileNamer fileNamer = GammaFileNamer.INSTANCE;
	protected final Logger logger = Logger.getLogger("GammaLogger");

	@Override
	public Object execute(ExecutionEvent event) {
		try {
			ISelection sel = HandlerUtil.getActiveMenuSelection(event);
			if (sel instanceof IStructuredSelection) {
				IStructuredSelection selection = (IStructuredSelection) sel;
				if (selection.getFirstElement() != null) {
					if (selection.getFirstElement() instanceof IFile) {
						IFile file = (IFile) selection.getFirstElement();
						String path = file.getFullPath().toString();
						
						String parentFolder = file.getParent().getFullPath().toString();
						String name = file.getName();
						String fileExtension = file.getFileExtension();
						
						ResourceSet resourceSet = new ResourceSetImpl();
						URI fileUri = URI.createPlatformResourceURI(path, true);
						Resource resource = resourceSet.getResource(fileUri, true);
						EObject rootElem = resource.getContents().get(0);
						
						switch (fileExtension) {
							case GammaFileNamer.PACKAGE_EMF_EXTENSION: {
								String fileName = fileNamer.getPackageFileName(name);
								
								StatechartLanguageSerializer serializer = new StatechartLanguageSerializer();
								serializer.serialize(rootElem, parentFolder, fileName);
								logger.log(Level.INFO, "Package serialization has been finished");
								break;
							}
							case GammaFileNamer.EXECUTION_EMF_EXTENSION: {
								String fileName = fileNamer.getExecutionTraceFileName(name);
								
								TraceLanguageSerializer serializer = new TraceLanguageSerializer();
								serializer.serialize(rootElem, parentFolder, fileName);
								logger.log(Level.INFO, "Execution trace serialization has been finished");
								break;
							}
							case GammaFileNamer.PROPERTY_EMF_EXTENSION: {
								String fileName = fileNamer.getPropertyFileName(name);
								
								PropertyLanguageSerializer serializer = new PropertyLanguageSerializer();
								serializer.serialize(rootElem, parentFolder, fileName);
								logger.log(Level.INFO, "Property serialization has been finished");
								break;
							}
						}
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

}