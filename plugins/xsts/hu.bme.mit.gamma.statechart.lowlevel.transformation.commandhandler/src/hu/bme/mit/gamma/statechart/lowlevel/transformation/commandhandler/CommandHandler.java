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
package hu.bme.mit.gamma.statechart.lowlevel.transformation.commandhandler;

import java.io.File;
import java.io.IOException;
import java.util.Collections;
import java.util.HashSet;
import java.util.Map.Entry;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.LowlevelToXSTSTransformer;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer.ActionPrimer;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer.VariableCommonizer;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.serializer.ActionSerializer;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability.L2STrace;
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer;
import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.statechart.model.StatechartDefinition;
import hu.bme.mit.gamma.statechart.model.composite.Component;
import hu.bme.mit.gamma.xsts.codegeneration.java.CommonizedVariableActionSerializer;
import hu.bme.mit.gamma.xsts.codegeneration.java.StatechartToJavaCodeGenerator;
import hu.bme.mit.gamma.xsts.model.model.XSTS;

public class CommandHandler extends AbstractHandler {

	protected Logger logger = Logger.getLogger("GammaLogger");
	
	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		ISelection sel = HandlerUtil.getActiveMenuSelection(event);
		try {
			if (sel instanceof IStructuredSelection) {
				IStructuredSelection selection = (IStructuredSelection) sel;
				if (selection.size() == 1) {
					if (selection.getFirstElement() instanceof IFile) {
						IFile firstElement = (IFile) selection.getFirstElement();
						String fileURISubstring = firstElement.getLocationURI().toString().substring(5);
						String parentFolder = fileURISubstring.substring(0, fileURISubstring.lastIndexOf("/"));
						String fileName = firstElement.getName();
						String fileNameWithoutExtenstion = fileName.substring(0, fileName.lastIndexOf("."));
						ResourceSet resSet = new ResourceSetImpl();
						URI compositeSystemURI = URI.createPlatformResourceURI(firstElement.getFullPath().toString(), true);
						Resource resource = resSet.getResource(compositeSystemURI, true);
						Package gammaPackage = (Package) resource.getContents().get(0);
						StatechartDefinition gammaStatechart = getStatechart(gammaPackage);
						// Loading all resources, needed as the events and interfaces are in another resource ("Interface.gcd")
						resolveResources(gammaPackage, resSet, new HashSet<Resource>());
						GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
						logger.log(Level.INFO, "The resource set before the Gamma - low level statechart transformation: " + resSet);
						hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
						normalSave(lowlevelPackage, parentFolder, fileNameWithoutExtenstion + ".lgsm");
						logger.log(Level.INFO, "The Gamma - low level statechart transformation has been finished.");
						logger.log(Level.INFO, "Starting Gamma low level - xSTS transformation.");
						// Note: the package is not in a resource
						LowlevelToXSTSTransformer lowlevelTransformer = new LowlevelToXSTSTransformer(lowlevelPackage);
						Entry<XSTS, L2STrace> resultModels = lowlevelTransformer.execute();
						XSTS xSts = resultModels.getKey();
						lowlevelTransformer.dispose();
						// Priming the variables on different branches
						ActionPrimer actionPrimer = new VariableCommonizer();
						hu.bme.mit.gamma.xsts.codegeneration.java.ActionSerializer javaActionSerializer = new CommonizedVariableActionSerializer(); // Good for the original actions too
						//
//						xSts.setInitializingAction(actionPrimer.transform(xSts.getInitializingAction()));
//						xSts.getMergedTransition().setAction(actionPrimer.transform(xSts.getMergedTransition().getAction()));
//						xSts.setEnvironmentalAction(actionPrimer.transform(xSts.getEnvironmentalAction()));
						// Saving the xSTS model
						normalSave(xSts, parentFolder, fileNameWithoutExtenstion + ".gsts");
						normalSave(resultModels.getValue(), parentFolder, "." + fileNameWithoutExtenstion + ".l2s");
						logger.log(Level.INFO, "The Gamma low level - xSTS transformation has been finished.");
						logger.log(Level.INFO, "Starting xSTS serialization.");
						// Serializing the xSTS
						ActionSerializer actionSerializer = new ActionSerializer();
						CharSequence xStsString = actionSerializer.serializeXSTS(xSts);
						System.out.println(xStsString);
						// Generating and serializing the expression from the actions
//						ActionToExpressionTransformer actionToExpressionTransformer = new ActionToExpressionTransformer();
//						Expression mergedTransitionExpression = actionToExpressionTransformer.transform(xSts.getMergedTransition().getAction());
//						ExpressionSerializer expressionSerializer = new ExpressionSerializer();
//						String mergedTransitionExpressionSerialization = expressionSerializer.serialize(mergedTransitionExpression);
//						System.out.println(mergedTransitionExpressionSerialization); // Too long string, not shown on the Console
						logger.log(Level.INFO, "Starting xSTS Java code generation.");
						IProject project = firstElement.getProject();
						String targetFolderUri = project.getLocation().toString() +	"/" + "src-gen";
						String basePackageName = project.getName().toLowerCase();
						StatechartToJavaCodeGenerator codeGenerator = new StatechartToJavaCodeGenerator(
							targetFolderUri, basePackageName, gammaStatechart, xSts, javaActionSerializer);
						codeGenerator.execute();
						logger.log(Level.INFO, "The xSTS transformation has been finished.");
					}
				}
			}
		} catch (Throwable exception) {
			exception.printStackTrace();
			logger.log(Level.SEVERE, exception.getMessage());
			DialogUtil.showErrorWithStackTrace(exception.getMessage(), exception);
		}
		return null;
	}
	
	private StatechartDefinition getStatechart(Package _package) {
		Component component = _package.getComponents().get(0);
		return (StatechartDefinition) component;
	}
	
	private void resolveResources(EObject object, ResourceSet resourceSet, Set<Resource> resolvedResources) {
		for (EObject crossObject : object.eCrossReferences()) {
			Resource resource = crossObject.eResource();
			if (resource != null && !resolvedResources.contains(resource)) {
				resourceSet.getResource(resource.getURI(), true);
				resolvedResources.add(resource);
			}
			resolveResources(crossObject, resourceSet, resolvedResources);
		}
		for (EObject containedObject : object.eContents()) {
			resolveResources(containedObject, resourceSet, resolvedResources);
		}
	}

	private void normalSave(EObject rootElem, String parentFolder, String fileName) throws IOException {
		ResourceSet resourceSet = new ResourceSetImpl();
		Resource saveResource = resourceSet.createResource(URI.createFileURI(URI.decode(parentFolder + File.separator + fileName)));
		saveResource.getContents().add(rootElem);
		saveResource.save(Collections.EMPTY_MAP);
	}
	
}
