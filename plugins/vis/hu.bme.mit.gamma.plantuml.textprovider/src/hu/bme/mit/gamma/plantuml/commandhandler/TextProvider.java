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

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.IPath;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.text.ITextSelection;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.IEditorInput;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.ide.ResourceUtil;

import hu.bme.mit.gamma.plantuml.transformation.CompositeToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.StatechartToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.TraceToPlantUmlTransformer;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import net.sourceforge.plantuml.eclipse.utils.DiagramTextProvider2;
import net.sourceforge.plantuml.eclipse.utils.WorkbenchPartDiagramIntentProviderContext;
import net.sourceforge.plantuml.text.AbstractDiagramIntentProvider;
import net.sourceforge.plantuml.text.AbstractTextDiagramIntentProvider;
import net.sourceforge.plantuml.util.AbstractDiagramIntent;
import net.sourceforge.plantuml.util.DiagramIntent;
import net.sourceforge.plantuml.util.DiagramIntentProvider;

public class TextProvider extends AbstractDiagramIntentProvider{

	private String plantumlModel;
	private List<String> supportedExtensions = Arrays.asList("gcd", "get");

	@Override
	public Boolean supportsSelection(ISelection sel) {
		if (sel instanceof IStructuredSelection) {
			IStructuredSelection selection = (IStructuredSelection) sel;
			if (selection.size() == 1) {
				if (selection.getFirstElement() instanceof IFile) {
					IFile firstElement = (IFile) selection.getFirstElement();
					final String fileExtension = firstElement.getFileExtension();
					if (fileExtension == null) {
						return false;
					}
					if (supportedExtensions.contains(fileExtension)) {
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

	private void getComponentPlantUMLCode(Resource resource) {
		if (!resource.getContents().isEmpty()) {
			Package _package = (Package) resource.getContents().get(0);
			EList<Component> components = _package.getComponents();
			if (!components.isEmpty()) {
				Component component = components.get(0);
				if (component instanceof StatechartDefinition) {
					StatechartDefinition statechartDefinition = (StatechartDefinition) component;
					StatechartToPlantUmlTransformer transformer = new StatechartToPlantUmlTransformer(statechartDefinition);
					plantumlModel = transformer.execute();
				} else if (component instanceof CompositeComponent) {
					CompositeComponent composite = (CompositeComponent) component;
					CompositeToPlantUmlTransformer transformer = new CompositeToPlantUmlTransformer(composite);
					plantumlModel = transformer.execute();
				}
			}
		}
	}
	
	private void getTracePlantUMLCode(Resource resource) {
		if (!resource.getContents().isEmpty()) {
			ExecutionTrace trace = (ExecutionTrace) resource.getContents().get(0);
			TraceToPlantUmlTransformer transformer = new TraceToPlantUmlTransformer(trace);
			plantumlModel = transformer.execute();
		}
	}
	
	@Override
	protected Collection<? extends DiagramIntent> getDiagramInfos(final WorkbenchPartDiagramIntentProviderContext context) {
		if(context.getSelection() instanceof IStructuredSelection) {
			IStructuredSelection selection = (IStructuredSelection) context.getSelection();
			if(selection.size() == 1) {
				if(selection.getFirstElement() instanceof IFile) {
					IFile file = (IFile) selection.getFirstElement();
					String fileExtension = file.getFileExtension();
					if(fileExtension.equals("gcd")) {
						IPath path = file.getFullPath();
						getComponentPlantUMLCode(getResource(path));
						GammaPlantUMLDiagramIntent gammaIntent = new GammaPlantUMLDiagramIntent(plantumlModel);
						gammaIntent.setDiagramText(plantumlModel);
						Collection<AbstractDiagramIntent<?>> diagrams = new ArrayList<>();
						diagrams.add(gammaIntent);
						return diagrams;
					}
					if(fileExtension.equals("get")) {
						IPath path = file.getFullPath();
						getTracePlantUMLCode(getResource(path));
						GammaPlantUMLDiagramIntent gammaIntent = new GammaPlantUMLDiagramIntent(plantumlModel);
						gammaIntent.setDiagramText(plantumlModel);
						Collection<AbstractDiagramIntent<?>> diagrams = new ArrayList<>();
						diagrams.add(gammaIntent);
						return diagrams;
					}
				}
			}
		}
		
		return null;
	}

	public String getDiagramText(IPath path) {
		final String fileExtension = path.getFileExtension();
		if (fileExtension.equals("gcd")) {
			getComponentPlantUMLCode(getResource(path));
			return plantumlModel;
		}
		if (fileExtension.equals("get")) {
			getTracePlantUMLCode(getResource(path));
			return plantumlModel;
		}
		return null; // "" would prevent other visualizations (Java class diagram)
	}

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
	public Boolean supportsPath(IPath arg0) {
		return supportedExtensions.contains(arg0.getFileExtension());
	}

}
