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
import java.util.Map.Entry;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.LowlevelToXSTSTransformer;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer.ActionPrimer;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer.ChoiceInliner;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer.VariableCommonizer;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability.L2STrace;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.xsts.codegeneration.java.CommonizedVariableActionSerializer;
import hu.bme.mit.gamma.xsts.codegeneration.java.InlinedChoiceActionSerializer;
import hu.bme.mit.gamma.xsts.codegeneration.java.StatechartToJavaCodeGenerator;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer;

public class CommandHandler extends AbstractHandler {

	protected Logger logger = Logger.getLogger("GammaLogger");
	protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	
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
						IProject project = firstElement.getProject();
						
						ResourceSet resourceSet = new ResourceSetImpl();
						URI packageURI = URI.createPlatformResourceURI(firstElement.getFullPath().toString(), true);
						Resource resource = resourceSet.getResource(packageURI, true);
						Package gammaPackage = (Package) resource.getContents().get(0);
						StatechartDefinition gammaStatechart = (StatechartDefinition) gammaPackage.getComponents().get(0);
						
						run(gammaStatechart, parentFolder, project.getLocation().toString() + File.separator +"src-gen",
							firstElement.getProject().getName().toLowerCase());
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

	public void run(StatechartDefinition gammaStatechart, String modelFolderUri, String targetFolderUri, String basePackageName) {
		String fileNameWithoutExtenstion = gammaStatechart.getName();
		Package gammaPackage = (Package) gammaStatechart.eContainer();
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		ecoreUtil.normalSave(lowlevelPackage, modelFolderUri, fileNameWithoutExtenstion + ".lgsm");
		logger.log(Level.INFO, "The Gamma - low level statechart transformation has been finished.");
		logger.log(Level.INFO, "Starting Gamma low level - xSTS transformation.");
		// Note: the package is not in a resource
		LowlevelToXSTSTransformer lowlevelTransformer = new LowlevelToXSTSTransformer(lowlevelPackage);
		Entry<XSTS, L2STrace> resultModels = lowlevelTransformer.execute();
		XSTS xSts = resultModels.getKey();
		lowlevelTransformer.dispose();
		// XSTS to Java serializer
		hu.bme.mit.gamma.xsts.codegeneration.java.ActionSerializer javaActionSerializer = null;
		// Set the following variable to specify the action priming setting
		ActionPrimingSetting setting = ActionPrimingSetting.CHOICE_INLINER;
		if (setting == ActionPrimingSetting.VARIABLE_COMMONIZER) {
			ActionPrimer actionPrimer = new VariableCommonizer(); // Not necessary to use it for code generation
			javaActionSerializer = new CommonizedVariableActionSerializer(); // Good for the original actions too
			// If we wanted to commonize the actions of the XSTS, we would have to do it here
			// ...
		}
		else {
			ActionPrimer actionPrimer = new ChoiceInliner(true);
			javaActionSerializer = new InlinedChoiceActionSerializer();
			xSts.setVariableInitializingAction(actionPrimer.transform(xSts.getVariableInitializingAction()));
			xSts.setConfigurationInitializingAction(actionPrimer.transform(xSts.getConfigurationInitializingAction()));
			xSts.setEntryEventAction(actionPrimer.transform(xSts.getEntryEventAction()));
			xSts.setMergedAction(actionPrimer.transform(xSts.getMergedAction()));
			xSts.setInEventAction(actionPrimer.transform(xSts.getInEventAction()));
			xSts.setOutEventAction(actionPrimer.transform(xSts.getOutEventAction()));
		}
		// Saving the xSTS model
		ecoreUtil.normalSave(xSts, modelFolderUri, fileNameWithoutExtenstion + ".gsts");
		ecoreUtil.normalSave(resultModels.getValue(), modelFolderUri, "." + fileNameWithoutExtenstion + ".l2s");
		logger.log(Level.INFO, "The Gamma low level - xSTS transformation has been finished.");
		logger.log(Level.INFO, "Starting xSTS serialization.");
		// Serializing the xSTS
		ActionSerializer actionSerializer = ActionSerializer.INSTANCE;
		CharSequence xStsString = actionSerializer.serializeXSTS(xSts);
		System.out.println(xStsString);
		logger.log(Level.INFO, "Starting xSTS Java code generation.");
		StatechartToJavaCodeGenerator codeGenerator = new StatechartToJavaCodeGenerator(
			targetFolderUri, basePackageName, gammaStatechart, xSts, javaActionSerializer);
		codeGenerator.execute();
		logger.log(Level.INFO, "The xSTS transformation has been finished.");
	}
	
	enum ActionPrimingSetting {
		VARIABLE_COMMONIZER, CHOICE_INLINER
	}
	
}
