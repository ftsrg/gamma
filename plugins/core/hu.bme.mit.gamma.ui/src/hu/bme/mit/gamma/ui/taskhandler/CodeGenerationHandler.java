/********************************************************************************
 * Copyright (c) 2019-2024 Contributors to the Gamma project
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

import java.io.File;
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

import hu.bme.mit.gamma.codegeneration.java.GlueCodeGenerator;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.CodeGeneration;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.GenmodelModelFactory;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.lowlevel.transformation.commandhandler.CommandHandler;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.xsts.codegeneration.c.CodeBuilder;
import hu.bme.mit.gamma.xsts.codegeneration.c.HavocBuilder;
import hu.bme.mit.gamma.xsts.codegeneration.c.IStatechartCode;
import hu.bme.mit.gamma.xsts.codegeneration.c.WrapperBuilder;
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms;
import hu.bme.mit.gamma.xsts.model.XSTS;

public class CodeGenerationHandler extends TaskHandler {

	public CodeGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(CodeGeneration codeGeneration, String packageName) {
		// Setting target folder
		setProjectLocation(codeGeneration); // Before the target folder
		setTargetFolder(codeGeneration);
		setCodeGeneration(codeGeneration, packageName);
		//
		checkArgument(codeGeneration.getProgrammingLanguages().size() == 1, 
				"A single programming language must be specified: " + codeGeneration.getProgrammingLanguages());
		
		ProgrammingLanguage programmingLanguage = codeGeneration.getProgrammingLanguages().get(0);
		checkArgument(programmingLanguage == ProgrammingLanguage.JAVA || programmingLanguage == ProgrammingLanguage.C,
				"Currently only Java and C supported.");
		
		switch (programmingLanguage) {
			case JAVA:
				generateJavaCode(codeGeneration);
				break;
			case C:
				generateCCode(codeGeneration);
				break;
			default:
				throw new IllegalArgumentException("Not known programming language: " + programmingLanguage);
		}
	}
	
	protected void generateCCode(CodeGeneration codeGeneration) {
		final Component component = codeGeneration.getComponent();
		/* Gamma to XSTS transformation */
		AnalysisModelTransformation transformation = GenmodelModelFactory.eINSTANCE.createAnalysisModelTransformation();
		transformation.getLanguages().add(AnalysisLanguage.THETA);
		
		ComponentReference reference = GenmodelModelFactory.eINSTANCE.createComponentReference();
		reference.setComponent(component);
		transformation.setModel(reference);
		transformation.setOptimizeEnvironmentalMessageQueues(false);
		
		/* rename file to be hidden */
		String fileName = file.getName();
		transformation.getFileName().add("." + fileName);
		
		AnalysisModelTransformationHandler transformationHandler = new AnalysisModelTransformationHandler(file);
		try {
			transformationHandler.execute(transformation);
		} catch (Exception e) {
			logger.severe("Gamma to XSTS transformation failed: " + e.getMessage());
		}
		
		/* retrieve XSTS model */
		String locationUriString = file.getLocationURI().toString().replace(fileName, "." + fileName)
					.replace(file.getFileExtension(), "gsts");
		URI locationUri = URI.createURI(locationUriString);
		
		Resource resource = new ResourceSetImpl().getResource(locationUri, true);
		XSTS xSts = (XSTS) resource.getContents().get(0);
		
		logger.info("XSTS model " + xSts.getName() + " successfully loaded.");
		
		/* determine the path of the project's root */
		File projectFile = ecoreUtil.getProjectFile(locationUri);
		URI root = URI.createFileURI(projectFile.toString());
		
		/* define the platform and function pointers */
		final boolean pointers = true;
		final SupportedPlatforms platform = SupportedPlatforms.UNIX;
		
		try {
			/* define what to generate */
			List<IStatechartCode> generate = List.of(
				new CodeBuilder(component, xSts),
				new WrapperBuilder(component, xSts, pointers),
				new HavocBuilder(component, xSts)
			);
			
			/* build c code */
			for (IStatechartCode builder : generate) {
				builder.setPlatform(platform);
				builder.constructHeader();
				builder.constructCode();
				builder.save(root);
			}
			
		} catch (Exception e) {
			logger.severe("XSTS to C transformation failed: " + e.getMessage());
		}
		
		logger.info("XSTS to C transformation completed.");
	}
	
	protected void generateJavaCode(CodeGeneration codeGeneration) {
		Resource codeGenerationResource = codeGeneration.eResource();
		
		Component component = codeGeneration.getComponent();
		String componentName = component.getName();
		if (component instanceof StatechartDefinition statechart) {
			logger.info("Starting single statechart code generation: " + componentName);
			CommandHandler singleStatechartCommandHandler = new CommandHandler();
			File resourceFile = (codeGenerationResource == null) ? null :
					ecoreUtil.getFile(codeGenerationResource);
			if (resourceFile == null) {
				resourceFile = fileUtil.getFile(file);
			}
			String parent = resourceFile.getParent();
			singleStatechartCommandHandler.run(statechart, parent,
					targetFolderUri, codeGeneration.getPackageName().get(0));
		}
		else {
			logger.info("Starting composite component code generation: " + componentName);
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
		List<String> packageNames = codeGeneration.getPackageName();
		checkArgument(packageNames.size() <= 1);
		if (packageNames.isEmpty()) {
			packageNames.add(packageName);
		}
		// TargetFolder set in setTargetFolder
	}
	
	private void loadStatechartTraces(ResourceSet resourceSet, Component component) {
		if (component instanceof CompositeComponent compositeComponent) {
			for (ComponentInstance containedComponent :
					StatechartModelDerivedFeatures.getDerivedComponents(compositeComponent)) {
				loadStatechartTraces(resourceSet,
						StatechartModelDerivedFeatures.getDerivedType(containedComponent));
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
					logger.info(statechartFileName + " trace is not found. " +
						"Wrapper is not generated for Gamma statecharts without trace.");
				}
			}
		}
	}

}
