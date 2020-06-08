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
package hu.bme.mit.gamma.plantuml.commandhandler;

import java.util.Map;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.IPath;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.IEditorInput;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.ide.ResourceUtil;

import hu.bme.mit.gamma.plantuml.transformation.StatechartToPlantUMLTransformer;
import hu.bme.mit.gamma.plantuml.transformation.TraceToPlantUMLTransformer;
import net.sourceforge.plantuml.eclipse.utils.DiagramTextProvider2;
import net.sourceforge.plantuml.text.AbstractDiagramTextProvider;

public class TextProvider extends AbstractDiagramTextProvider implements DiagramTextProvider2 {

	private String plantumlModel;

	@Override
	public boolean supportsSelection(ISelection sel) {
		if (sel instanceof IStructuredSelection) {
			IStructuredSelection selection = (IStructuredSelection) sel;
			if (selection.size() == 1) {
				if (selection.getFirstElement() instanceof IFile) {
					IFile firstElement = (IFile) selection.getFirstElement();
					final String fileExtension = firstElement.getFileExtension();
					if (fileExtension == null) {
						return false;
					}
					if (fileExtension.equals("gcd") || fileExtension.equals("get")) {
						return true;
					}
				}
			}
		}
		return false;
	}
	
	private Resource getResource(IPath path) {
		ResourceSet resourceSet = new ResourceSetImpl();
		URI traceModelUri = URI.createPlatformResourceURI(path.toString(), true);
		Resource resource = resourceSet.getResource(traceModelUri, true);
		return resource;
	}

	private void getStatechartPlantUMLCode(Resource resource) {
		StatechartToPlantUMLTransformer transformer = new StatechartToPlantUMLTransformer(resource);
		transformer.execute();
		if (transformer.getTransitions() != null) {
			plantumlModel = transformer.getTransitions();
		}
	}
	
	private void getTracePlantUMLCode(Resource resource) {
		TraceToPlantUMLTransformer transformer = new TraceToPlantUMLTransformer(resource);
		plantumlModel = transformer.execute();
	}

	@Override
	public String getDiagramText(IPath path) {
		if (path.getFileExtension().equals("gcd")) {
			getStatechartPlantUMLCode(getResource(path));
			return "@startuml\r\n" + plantumlModel + "@enduml";
		}
		if (path.getFileExtension().equals("get")) {
			getTracePlantUMLCode(getResource(path));
			return "@startuml\r\n" + plantumlModel + "@enduml";
		}
		return null; // "" would prevent other visualizations (Java class diagram)
	}

	@Override
	public String getDiagramText(IEditorPart editorPart, ISelection arg1, Map<String, Object> arg2) {
		IEditorInput input = editorPart.getEditorInput();
		IFile file = ResourceUtil.getFile(input);
		if (file != null) {
			IPath path = file.getFullPath();
			return getDiagramText(path);
		}
		return null; // "" would prevent other visualizations (Java class diagram)
	}

	@Override
	public boolean supportsPath(IPath arg0) {
		return "gcd".equals(arg0.getFileExtension()) || "get".equals(arg0.getFileExtension());
	}

}
