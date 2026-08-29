/********************************************************************************
 * Copyright (c) 2018-2025 Contributors to the Gamma project
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

import org.eclipse.core.commands.Command;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.IPath;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.commands.ICommandService;
import org.eclipse.ui.handlers.RadioState;

import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.plantuml.transformation.AdapterToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.CompositeToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.CoordinationToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.InterfaceToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.StatechartToPlantUmlTransformer;
import hu.bme.mit.gamma.plantuml.transformation.TraceToPlantUmlTransformer;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.CoordinationStatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import net.sourceforge.plantuml.eclipse.utils.WorkbenchPartDiagramIntentProviderContext;
import net.sourceforge.plantuml.text.AbstractDiagramIntentProvider;
import net.sourceforge.plantuml.util.DiagramIntent;

public class TextProvider extends AbstractDiagramIntentProvider {

	private List<String> supportedExtensions = Arrays.asList("gcd", "gsm", "get");

	@Override
	public Boolean supportsSelection(ISelection sel) {
		if (sel instanceof IStructuredSelection selection) {
			if (selection.size() == 1) {
				Object firstElement = selection.getFirstElement();
				if (firstElement instanceof IFile file) {
					String fileExtension = file.getFileExtension();
					if (fileExtension == null) {
						return false;
					}
					return supportedExtensions.contains(fileExtension);
				}
			}
		}
		return false;
	}

	@Override
	public Boolean supportsPath(IPath arg) {
		String fileExtension = arg.getFileExtension();
		return supportedExtensions.contains(fileExtension); // Not called
	}

	@Override
	protected Collection<? extends DiagramIntent> getDiagramInfos(
			final WorkbenchPartDiagramIntentProviderContext context) {
		ISelection selection = context.getSelection();
		return getDiagramInfo(selection);
	}

	private Collection<? extends DiagramIntent> getDiagramInfo(ISelection selection) {
		if (selection instanceof IStructuredSelection structuredSelection) {
			if (structuredSelection.size() == 1) {
				Object firstElement = structuredSelection.getFirstElement();
				if (firstElement instanceof IFile file) {
					String fileExtension = file.getFileExtension();
					IPath path = file.getFullPath();
					
					String plantUmlModel = null;
					if (fileExtension.equals("gcd") || fileExtension.equals("gsm")) {
						plantUmlModel = getComponentPlantUmlCode(
								getResource(path));
					}
					if (fileExtension.equals("get")) {
						plantUmlModel = getTracePlantUmlCode(
								getResource(path));
					}
					
					if (plantUmlModel != null) {
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
		List<EObject> contents = resource.getContents();
		if (!contents.isEmpty()) {
			Package _package = (Package) contents.get(0);
			List<Component> components = _package.getComponents();
			List<Interface> interfaces = _package.getInterfaces();
			if (!components.isEmpty()) {
				Component component = components.get(0);
				if (component instanceof CoordinationStatechartDefinition statechartDefinition) {
					ICommandService commandService =
						    PlatformUI.getWorkbench().getService(ICommandService.class);
					Command command = commandService.getCommand("hu.bme.mit.gamma.plantuml.coordinationLayoutCommand");
					String state = (String)command.getState(RadioState.STATE_ID).getValue();
					CoordinationToPlantUmlTransformer transformer = new CoordinationToPlantUmlTransformer(
							statechartDefinition, state);
					return transformer.execute();
				} else if (component instanceof StatechartDefinition statechartDefinition) {
					StatechartToPlantUmlTransformer transformer = new StatechartToPlantUmlTransformer(
							statechartDefinition);
					return transformer.execute();
				}
				else if (component instanceof CompositeComponent composite) {
					CompositeToPlantUmlTransformer transformer = new CompositeToPlantUmlTransformer(composite);
					return transformer.execute();
				}
				else if (component instanceof AsynchronousAdapter adapter) {
					AdapterToPlantUmlTransformer transformer = new AdapterToPlantUmlTransformer(adapter);
					return transformer.execute();
				}
			}
			else if (!interfaces.isEmpty()) {
				List<EnumerationTypeDefinition> enums = _package.getTypeDeclarations().stream()
						.filter(typeDecalration -> typeDecalration.getType() instanceof EnumerationTypeDefinition)
						.map(typeDecalration -> (EnumerationTypeDefinition) typeDecalration.getType())
						.collect(Collectors.toList());
				List<RecordTypeDefinition> structs = _package.getTypeDeclarations().stream()
						.filter(typeDecalration -> typeDecalration.getType() instanceof RecordTypeDefinition)
						.map(typeDecalration -> (RecordTypeDefinition) typeDecalration.getType())
						.collect(Collectors.toList());
				List<FunctionDeclaration> functions = _package.getFunctionDeclarations();
				
				InterfaceToPlantUmlTransformer transformer = new InterfaceToPlantUmlTransformer(
						interfaces, enums, structs, functions);
				return transformer.execute();
			}
		}
		return ""; // To counter nullptr exceptions
	}

	private String getTracePlantUmlCode(Resource resource) {
		List<EObject> contents = resource.getContents();
		if (!contents.isEmpty()) {
			ExecutionTrace trace = (ExecutionTrace) contents.get(0);
			TraceToPlantUmlTransformer transformer = new TraceToPlantUmlTransformer(trace);
			return transformer.execute();
		}
		return null;
	}

}