/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.plantuml.commandhandler;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.IPath;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;

import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.plantuml.transformation.AdapterToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.CompositeToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.InterfaceToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.StatechartToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.TraceToPlantUmlTransformer;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import net.sourceforge.plantuml.eclipse.utils.WorkbenchPartDiagramIntentProviderContext;
import net.sourceforge.plantuml.text.AbstractDiagramIntentProvider;
import net.sourceforge.plantuml.util.DiagramIntent;

public class TextProvider extends AbstractDiagramIntentProvider {

	private List<String> supportedExtensions = Arrays.asList("gcd", "get");

	@Override
	public Boolean supportsSelection(ISelection sel) {
		if (sel instanceof IStructuredSelection) {
			IStructuredSelection selection = (IStructuredSelection) sel;
			if (selection.size() == 1) {
				if (selection.getFirstElement() instanceof IFile) {
					IFile firstElement = (IFile) selection.getFirstElement();
					String fileExtension = firstElement.getFileExtension();
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

	@Override
	public Boolean supportsPath(IPath arg) {
		return supportedExtensions.contains(arg.getFileExtension()); // Not called
	}

	@Override
	protected Collection<? extends DiagramIntent> getDiagramInfos(
			final WorkbenchPartDiagramIntentProviderContext context) {
		ISelection selection = context.getSelection();
		return getDiagramInfo(selection);
	}

	private Collection<? extends DiagramIntent> getDiagramInfo(ISelection selection) {
		if (selection instanceof IStructuredSelection) {
			IStructuredSelection structuredSelection = (IStructuredSelection) selection;
			if (structuredSelection.size() == 1) {
				if (structuredSelection.getFirstElement() instanceof IFile) {
					IFile file = (IFile) structuredSelection.getFirstElement();
					String fileExtension = file.getFileExtension();
					if (fileExtension.equals("gcd")) {
						IPath path = file.getFullPath();
						String plantUmlModel = getComponentPlantUmlCode(getResource(path));
						GammaPlantUmlDiagramIntent gammaIntent = new GammaPlantUmlDiagramIntent(plantUmlModel);
						return List.of(gammaIntent);
					}
					if (fileExtension.equals("get")) {
						IPath path = file.getFullPath();
						String plantUmlModel = getTracePlantUmlCode(getResource(path));
						GammaPlantUmlDiagramIntent gammaIntent = new GammaPlantUmlDiagramIntent(plantUmlModel);
						return List.of(gammaIntent);
					}
				}
			}
		}
		return null;
	}

	private Resource getResource(IPath path) {
		ResourceSet resourceSet = new ResourceSetImpl();
		URI traceModelUri = URI.createPlatformResourceURI(path.toString(), true);
		Resource resource = resourceSet.getResource(traceModelUri, true);
		return resource;
	}

	private String getComponentPlantUmlCode(Resource resource) {
		if (!resource.getContents().isEmpty()) {
			Package _package = (Package) resource.getContents().get(0);
			List<Component> components = _package.getComponents();
			if (!components.isEmpty()) {
				Component component = components.get(0);
				if (component instanceof StatechartDefinition) {
					StatechartDefinition statechartDefinition = (StatechartDefinition) component;
					StatechartToPlantUmlTransformer transformer = new StatechartToPlantUmlTransformer(
							statechartDefinition);
					return transformer.execute();
				} else if (component instanceof CompositeComponent) {
					CompositeComponent composite = (CompositeComponent) component;
					CompositeToPlantUmlTransformer transformer = new CompositeToPlantUmlTransformer(composite);
					return transformer.execute();
				} else if (component instanceof AsynchronousAdapter) {
					AsynchronousAdapter adapter = (AsynchronousAdapter) component;
					AdapterToPlantUmlTransformer transformer = new AdapterToPlantUmlTransformer(adapter);
					return transformer.execute();
				}
			} else if (!_package.getInterfaces().isEmpty()) {
				List<EnumerationTypeDefinition> enums = _package.getTypeDeclarations().stream()
						.filter(typeDecalration -> typeDecalration.getType() instanceof EnumerationTypeDefinition)
						.map(typeDecalration -> (EnumerationTypeDefinition) typeDecalration.getType())
						.collect(Collectors.toList());
				List<RecordTypeDefinition> structs = _package.getTypeDeclarations().stream()
						.filter(typeDecalration -> typeDecalration.getType() instanceof RecordTypeDefinition)
						.map(typeDecalration -> (RecordTypeDefinition) typeDecalration.getType())
						.collect(Collectors.toList());
				List<FunctionDeclaration> funcs = _package.getFunctionDeclarations();
				InterfaceToPlantUmlTransformer transformer = new InterfaceToPlantUmlTransformer(
						_package.getInterfaces(), enums, structs, funcs);
				return transformer.execute();
			}
		}
		return ""; // To counter nullptr exceptions
	}

	private String getTracePlantUmlCode(Resource resource) {
		if (!resource.getContents().isEmpty()) {
			ExecutionTrace trace = (ExecutionTrace) resource.getContents().get(0);
			TraceToPlantUmlTransformer transformer = new TraceToPlantUmlTransformer(trace);
			return transformer.execute();
		}
		return null;
	}

}