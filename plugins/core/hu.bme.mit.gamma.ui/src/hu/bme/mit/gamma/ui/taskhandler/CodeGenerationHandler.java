/********************************************************************************
 * Copyright (c) 2019-2023 Contributors to the Gamma project
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
import java.util.logging.Level;

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
import hu.bme.mit.gamma.genmodel.model.ModelReference;
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
		//
		checkArgument(codeGeneration.getProgrammingLanguages().size() == 1, 
				"A single programming language must be specified: " + codeGeneration.getProgrammingLanguages());
		checkArgument(codeGeneration.getProgrammingLanguages().get(0) == ProgrammingLanguage.JAVA ||
				codeGeneration.getProgrammingLanguages().get(0) == ProgrammingLanguage.C,
				"Currently only Java and C supported.");
		setCodeGeneration(codeGeneration, packageName);
		
		switch(codeGeneration.getProgrammingLanguages().get(0)) {
		case JAVA:
			generateJavaCode(codeGeneration);
			break;
		case C:
			generateCCode(codeGeneration);
			break;
		default:
			generateJavaCode(codeGeneration);
		}
	}
	
	private void generateCCode(CodeGeneration codeGeneration) {
		final Component component = codeGeneration.getComponent();
		/* GAMMA to XSTS transformation */
		AnalysisModelTransformation transformation = GenmodelModelFactory.eINSTANCE.createAnalysisModelTransformation();
		transformation.getLanguages().clear();
		transformation.getLanguages().add(AnalysisLanguage.THETA);
		
		ComponentReference reference = GenmodelModelFactory.eINSTANCE.createComponentReference();
		reference.setComponent(component);
		transformation.setModel(reference);
		transformation.setOptimizeEnvironmentalMessageQueues(false);
		
		/* rename file to be hidden */
		String fileName = file.getName();
		transformation.getFileName().clear();
		transformation.getFileName().add("." + fileName);
		
		AnalysisModelTransformationHandler amth = new AnalysisModelTransformationHandler(file);
		try {
			amth.execute(transformation);
		}catch (Exception e) {
			logger.severe("GAMMA to XSTS transformation failed: " + e.getMessage());
		}
		
		/* retrieve XSTS model */
		String locationUriString = file.getLocationURI().toString().replace(fileName, "." + fileName).replace(file.getFileExtension(), "gsts");
		URI locationUri = URI.createURI(locationUriString);
		
		Resource res = new ResourceSetImpl().getResource(locationUri, true);
		XSTS xSts = (XSTS) res.getContents().get(0);
		
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
			
		}catch (Exception e) {
			logger.severe("XSTS to C transformation failed: " + e.getMessage());
		}
		
		logger.info("XSTS to C transformation completed.");
	}
	
	private void generateJavaCode(CodeGeneration codeGeneration) {
		final Component component = codeGeneration.getComponent();
		if (component instanceof StatechartDefinition) {
			StatechartDefinition statechart = (StatechartDefinition) component;
			logger.log(Level.INFO, "Starting single statechart code generation: " + component.getName());
			CommandHandler singleStatechartCommandHandler = new CommandHandler();
			singleStatechartCommandHandler.run(statechart, ecoreUtil.getFile(codeGeneration.eResource()).getParent(),
					targetFolderUri, codeGeneration.getPackageName().get(0));
		}
		else {
			logger.log(Level.INFO, "Starting composite component code generation: " + component.getName());
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
