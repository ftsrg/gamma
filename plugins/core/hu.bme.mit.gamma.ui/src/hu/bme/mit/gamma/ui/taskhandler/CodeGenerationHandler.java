/********************************************************************************
 * Copyright (c) 2019 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.util.logging.Level;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

import hu.bme.mit.gamma.codegenerator.java.GlueCodeGenerator;
import hu.bme.mit.gamma.genmodel.model.CodeGeneration;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.lowlevel.transformation.commandhandler.CommandHandler;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;

public class CodeGenerationHandler extends TaskHandler {

	public CodeGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(CodeGeneration codeGeneration, String packageName) {
		// Setting target folder
		setTargetFolder(codeGeneration);
		//
		checkArgument(codeGeneration.getProgrammingLanguages().size() == 1, 
				"A single programming language must be specified: " + codeGeneration.getProgrammingLanguages());
		checkArgument(codeGeneration.getProgrammingLanguages().get(0) == ProgrammingLanguage.JAVA, 
				"Currently only Java is supported.");
		setCodeGeneration(codeGeneration, packageName);
		Component component = codeGeneration.getComponent();
		
		if (component instanceof StatechartDefinition) {
			StatechartDefinition statechart = (StatechartDefinition) component;
			logger.log(Level.INFO, "Starting single statechart code generation...");
			CommandHandler singleStatechartCommandHandler = new CommandHandler();
			singleStatechartCommandHandler.run(statechart, ecoreUtil.getFile(codeGeneration.eResource()).getParent(),
					targetFolderUri, codeGeneration.getPackageName().get(0));
		}
		else {
			logger.log(Level.INFO, "Starting composite component code generation...");
			ResourceSet codeGenerationResourceSet = new ResourceSetImpl();
			codeGenerationResourceSet.getResource(component.eResource().getURI(), true);
			loadStatechartTraces(codeGenerationResourceSet, component);
			// The presence of the top level component and statechart traces are sufficient in the resource set
			// Contained composite components are automatically resolved by VIATRA
			GlueCodeGenerator generator = new GlueCodeGenerator(codeGenerationResourceSet,
					codeGeneration.getPackageName().get(0), targetFolderUri);
			generator.execute();
			generator.dispose();
		}
	}
	
	private void setCodeGeneration(CodeGeneration codeGeneration, String packageName) {
		checkArgument(codeGeneration.getPackageName().size() <= 1);
		if (codeGeneration.getPackageName().isEmpty()) {
			codeGeneration.getPackageName().add(packageName);
		}
		// TargetFolder set in setTargetFolder
	}
	
	private void loadStatechartTraces(ResourceSet resourceSet, Component component) {
		if (component instanceof CompositeComponent) {
			CompositeComponent compositeComponent = (CompositeComponent) component;
			for (ComponentInstance containedComponent : StatechartModelDerivedFeatures.getDerivedComponents(compositeComponent)) {
				loadStatechartTraces(resourceSet, StatechartModelDerivedFeatures.getDerivedType(containedComponent));
			}
		}
		else {
			Resource resource = component.eResource();
			URI platformUri = ecoreUtil.getPlatformUri(resource);
			String statechartUri = platformUri.trimFileExtension().toPlatformString(true);
			// E.g., /hu.bme.mit.gamma.tutorial.extra/model/TrafficLight/TrafficLightCtrl
			String statechartFileName = statechartUri.substring(statechartUri.lastIndexOf("/") + 1);
			String traceUri = statechartUri.substring(0, statechartUri.lastIndexOf("/") + 1) + "." + statechartFileName + ".y2g";
			if (resourceSet.getResources().stream().noneMatch(it -> it.getURI().toString().equals(traceUri))) {
				try {
					resourceSet.getResource(URI.createPlatformResourceURI(traceUri, true), true);
				} catch (Exception e) {
					logger.log(Level.INFO, statechartFileName + " trace is not found. " +
						"Wrapper is not generated for Gamma statecharts without trace.");
				}
			}
		}
	}

}
