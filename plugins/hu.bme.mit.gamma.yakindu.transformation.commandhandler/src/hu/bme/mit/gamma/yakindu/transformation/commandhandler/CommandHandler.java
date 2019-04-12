/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.yakindu.transformation.commandhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import com.google.inject.Injector;

import hu.bme.mit.gamma.codegenerator.java.GlueCodeGenerator;
import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.statechart.language.ui.internal.LanguageActivator;
import hu.bme.mit.gamma.statechart.language.ui.serializer.StatechartLanguageSerializer;
import hu.bme.mit.gamma.statechart.model.Component;
import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.uppaal.backannotation.TestGenerator;
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer;
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer.Scheduler;
import hu.bme.mit.gamma.uppaal.composition.transformation.ModelUnfolder;
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;
import hu.bme.mit.gamma.yakindu.genmodel.AnalysisLanguage;
import hu.bme.mit.gamma.yakindu.genmodel.AnalysisModelTransformation;
import hu.bme.mit.gamma.yakindu.genmodel.CodeGeneration;
import hu.bme.mit.gamma.yakindu.genmodel.GenModel;
import hu.bme.mit.gamma.yakindu.genmodel.InterfaceCompilation;
import hu.bme.mit.gamma.yakindu.genmodel.ProgrammingLanguage;
import hu.bme.mit.gamma.yakindu.genmodel.StatechartCompilation;
import hu.bme.mit.gamma.yakindu.genmodel.Task;
import hu.bme.mit.gamma.yakindu.genmodel.TestGeneration;
import hu.bme.mit.gamma.yakindu.genmodel.YakinduCompilation;
import hu.bme.mit.gamma.yakindu.transformation.batch.InterfaceTransformer;
import hu.bme.mit.gamma.yakindu.transformation.batch.ModelValidator;
import hu.bme.mit.gamma.yakindu.transformation.batch.YakinduToGammaTransformer;
import hu.bme.mit.gamma.yakindu.transformation.traceability.Y2GTrace;
import uppaal.NTA;

/**
 * This class receives the transformation command, acquires the Yakindu model as a resource,
 *  then creates a transformer with the resource file and executes the transformation. 
 */
public class CommandHandler extends AbstractHandler {

	protected Logger logger = Logger.getLogger("GammaLogger");
	
	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		ISelection sel = HandlerUtil.getActiveMenuSelection(event);
		try {
			if (sel instanceof IStructuredSelection) {
				IStructuredSelection selection = (IStructuredSelection) sel;
				if (selection.getFirstElement() != null) {
					if (selection.getFirstElement() instanceof IFile) {
						IFile file = (IFile) selection.getFirstElement();
						IProject project = file.getProject();
						ResourceSet resSet = new ResourceSetImpl();
						logger.log(Level.INFO, "Resource set for Yakindu to Gamma statechart generation: " + resSet);
						URI fileURI = URI.createPlatformResourceURI(file.getFullPath().toString(), true);
						Resource resource;
						try {
							resource = resSet.getResource(fileURI, true);
						} catch (RuntimeException e) {
							return null;
						}
						if (resource.getContents() != null) {
							if (resource.getContents().get(0) instanceof GenModel) {
								String fileUriSubstring = URI.decode(file.getLocation().toString());
								// Decoding so spaces do not stir trouble
								String parentFolderUri = fileUriSubstring.substring(0, fileUriSubstring.lastIndexOf("/"));	
								// WARNING: workspace location and imported project locations are not to be confused
								String projectLocation = project.getLocation().toString();
								GenModel genmodel = (GenModel) resource.getContents().get(0);
								// Sorting: InterfaceCompilation < StatechartCompilarion < else
								List<Task> sortedTaskList = new ArrayList<Task>(genmodel.getTasks());
								sortedTaskList.sort( (a, b) -> {
									if (a instanceof InterfaceCompilation) return -1;
									if (b instanceof InterfaceCompilation) return 1;
									if (a instanceof StatechartCompilation) return -1;
									if (b instanceof StatechartCompilation) return 1;
									if (a instanceof AnalysisModelTransformation) return -1;
									if (b instanceof AnalysisModelTransformation) return 1;
									if (a instanceof CodeGeneration) return -1;
									if (b instanceof CodeGeneration) return 1;
									if (a instanceof TestGeneration) return -1;
									if (b instanceof TestGeneration) return 1;
									return 0;
								});
								for (Task task : sortedTaskList) {
									setTargetFolder(task, file, parentFolderUri);
									String targetFolderUri = URI.decode(projectLocation + File.separator + task.getTargetFolder().get(0));
									if (task instanceof YakinduCompilation) {
										YakinduCompilation yakinduCompilation = (YakinduCompilation) task;
										setYakinduCompilation(yakinduCompilation);
										if (task instanceof InterfaceCompilation) {
											logger.log(Level.INFO, "Resource set content for Yakindu to Gamma interface generation: " + resSet);
											InterfaceCompilation interfaceCompilation = (InterfaceCompilation) task;
											InterfaceTransformer transformer = new InterfaceTransformer(
													interfaceCompilation.getStatechart(), interfaceCompilation.getPackageName().get(0));
											SimpleEntry<Package, Y2GTrace> resultModels = transformer.execute();
											saveModel(resultModels.getKey(), targetFolderUri, interfaceCompilation.getFileName().get(0) + ".gcd");
											saveModel(resultModels.getValue(), targetFolderUri, "." + interfaceCompilation.getFileName().get(0)  + ".y2g");
											logger.log(Level.INFO, "The Yakindu-Gamma interface transformation has been finished.");
										}
										else if (task instanceof StatechartCompilation) {
											logger.log(Level.INFO, "Resource set content Yakindu to Gamma statechart generation: " + resSet);
											StatechartCompilation statechartCompilation = (StatechartCompilation) task;
											setStatechartCompilation(statechartCompilation, yakinduCompilation.getPackageName().get(0) + "Statechart");
											ModelValidator validator = new ModelValidator(statechartCompilation.getStatechart());
											validator.checkModel();
											YakinduToGammaTransformer transformer = new YakinduToGammaTransformer(statechartCompilation);
											SimpleEntry<Package, Y2GTrace> resultModels = transformer.execute();
											// Saving Xtext and EMF models
											saveModel(resultModels.getKey(), targetFolderUri, yakinduCompilation.getFileName().get(0) + ".gcd");
											saveModel(resultModels.getValue(), targetFolderUri, "." + yakinduCompilation.getFileName().get(0) + ".y2g");
											transformer.dispose();
											logger.log(Level.INFO, "The Yakindu-Gamma transformation has been finished.");
										}
									}
									else if (task instanceof CodeGeneration) {
										CodeGeneration codeGeneration = (CodeGeneration) task;
										checkArgument(codeGeneration.getLanguage().size() == 1, 
												"A single programming language must be specified: " + codeGeneration.getLanguage());
										checkArgument(codeGeneration.getLanguage().get(0) == ProgrammingLanguage.JAVA, 
												"Currently only Java is supported.");
										setCodeGeneration(codeGeneration, project.getName());
										logger.log(Level.INFO, "Resource set content for Java code generation: " + resSet);
										Component component = codeGeneration.getComponent();
										ResourceSet codeGenerationResourceSet = new ResourceSetImpl();
										codeGenerationResourceSet.getResource(component.eResource().getURI(), true);
										loadStatechartTraces(codeGenerationResourceSet, component);
										// The presence of the top level component and statechart traces are sufficient in the resource set
										// Contained composite components are automatically resolved by VIATRA
										GlueCodeGenerator generator = new GlueCodeGenerator(codeGenerationResourceSet,
												codeGeneration.getPackageName().get(0), targetFolderUri);
										generator.execute();
										generator.dispose();
										logger.log(Level.INFO, "The Java code generation has been finished.");
									}
									else if (task instanceof AnalysisModelTransformation) {
										AnalysisModelTransformation analysisModelTransformation = (AnalysisModelTransformation) task;
										checkArgument(analysisModelTransformation.getLanguage().size() == 1, 
												"A single formal modeling language must be specified: " + analysisModelTransformation.getLanguage());
										checkArgument(analysisModelTransformation.getLanguage().get(0) == AnalysisLanguage.UPPAAL, 
												"Currently only UPPAAL is supported.");
										setAnalysisModelTransformation(analysisModelTransformation);
										// Unfolding the given system
										Component component = analysisModelTransformation.getComponent();
										Package gammaPackage = (Package) component.eContainer();
										SimpleEntry<Package, Component> packageWithTopComponent = new ModelUnfolder().unfold(gammaPackage);
										Component topComponent = packageWithTopComponent.getValue();
										// Saving the Package of the unfolded model
										String flattenedModelFileName = "." + analysisModelTransformation.getFileName().get(0) + ".gsm";
										normalSave(packageWithTopComponent.getKey(), targetFolderUri, flattenedModelFileName);
										// Reading the model from disk as this is the only way it works
										ResourceSet resourceSet = new ResourceSetImpl();
										logger.log(Level.INFO, "Resource set for flattened Gamma to UPPAAL transformation created: " + resourceSet);
										Resource flattenedResource = resourceSet.getResource(
												URI.createFileURI(targetFolderUri + File.separator + flattenedModelFileName), true);
										// Needed because reading from disk means it is another model now
										Component newTopComponent = getEquivalentComposite(flattenedResource, topComponent);
										// Checking the model whether it contains forbidden elements
										hu.bme.mit.gamma.uppaal.transformation.ModelValidator validator = 
												new hu.bme.mit.gamma.uppaal.transformation.ModelValidator(resourceSet, newTopComponent, false);
										validator.checkModel();
										logger.log(Level.INFO, "Resource set content for flattened Gamma to UPPAAL transformation: " + resourceSet);
										CompositeToUppaalTransformer transformer = new CompositeToUppaalTransformer(resourceSet,
											newTopComponent, analysisModelTransformation.getArguments(),
											getGammaScheduler(analysisModelTransformation.getScheduler().get(0)),
											analysisModelTransformation.isTransitionCoverage()); // newTopComponent
										SimpleEntry<NTA, G2UTrace> resultModels = transformer.execute();
										NTA nta = resultModels.getKey();
										// Saving the generated models
										normalSave(nta, targetFolderUri, "." + analysisModelTransformation.getFileName().get(0) + ".uppaal");
										normalSave(resultModels.getValue(), targetFolderUri, "." + analysisModelTransformation.getFileName().get(0) + ".g2u");
										// Serializing the NTA model to XML
										UppaalModelSerializer.saveToXML(nta, targetFolderUri, analysisModelTransformation.getFileName().get(0) + ".xml");
										// Creating a new query file
										new File(targetFolderUri + File.separator +	analysisModelTransformation.getFileName().get(0) + ".q").delete();
										if (analysisModelTransformation.isStateCoverage()) {
											UppaalModelSerializer.createStateReachabilityQueries(transformer.getTemplateLocationsMap(),
												transformer.getIsStableVarName(), targetFolderUri, analysisModelTransformation.getFileName().get(0) + ".q");
										}
										if (analysisModelTransformation.isTransitionCoverage()) {
											UppaalModelSerializer.createTransitionFireabilityQueries(transformer.getTransitionIdVariableName(), transformer.getTransitionIdVariableValue(),
												"", targetFolderUri, analysisModelTransformation.getFileName().get(0) + ".q");
										}
										transformer.dispose();
										logger.log(Level.INFO, "The composite system transformation has been finished.");
									}
									else if (task instanceof TestGeneration) {
										TestGeneration testGeneration = (TestGeneration) task;
										checkArgument(testGeneration.getLanguage().size() == 1, 
												"A single programming language must be specified: " + testGeneration.getLanguage());
										checkArgument(testGeneration.getLanguage().get(0) == ProgrammingLanguage.JAVA, 
												"Currently only Java is supported.");
										setTestGeneration(testGeneration, project.getName());
										ExecutionTrace executionTrace = testGeneration.getExecutionTrace();
										ResourceSet testGenerationResourceSet = new ResourceSetImpl();
										testGenerationResourceSet.getResource(testGeneration.eResource().getURI(), true);
										logger.log(Level.INFO, "Resource set content for test generation: " + testGenerationResourceSet);
										TestGenerator testGenerator = new TestGenerator(testGenerationResourceSet, executionTrace,
												testGeneration.getPackageName().get(0), testGeneration.getFileName().get(0));
										String testClass = testGenerator.execute();
										saveCode(targetFolderUri + File.separator + testGenerator.getPackageName().replaceAll("\\.", "/"),
												testGeneration.getFileName().get(0) + ".java", testClass);
										logger.log(Level.INFO, "The test generation has been finished.");
									}
								}
							}
							logger.log(Level.INFO, "Cleaning project.");
							// This is due to the bad imports and error markers generated by Xtext
							// as it serializes references to other models as names instead of URLs
							project.build(IncrementalProjectBuilder.CLEAN_BUILD, null);
							logger.log(Level.INFO, "Cleaning project finished.");
						}
						return null;
					}
				}
			}
		} catch (Exception exception) {
			exception.printStackTrace();
			logger.log(Level.SEVERE, exception.getMessage());
			DialogUtil.showErrorWithStackTrace(exception.getMessage(), exception);
		}
		return null;
	}
	
	private void setTargetFolder(Task task, IFile file, String parentFolderUri) {
		// E.g., C:/Users/...
		String projectLocation = file.getProject().getLocation().toString();
		checkArgument(task.getTargetFolder().size() <= 1);
		if (task.getTargetFolder().isEmpty()) {
			String targetFolder = null;
			if (task instanceof CodeGeneration) {
				targetFolder = "src-gen";
			}
			else if (task instanceof TestGeneration) {
				targetFolder = "test-gen";
			}
			else {
				targetFolder = parentFolderUri.substring(projectLocation.length() + 1);
			}
			task.getTargetFolder().add(targetFolder);
		}
	}

	private void setYakinduCompilation(YakinduCompilation yakinduCompilation) {
		String fileName = getNameWithoutExtension(getContainingFileName(yakinduCompilation.getStatechart()));
		checkArgument(yakinduCompilation.getFileName().size() <= 1);
		checkArgument(yakinduCompilation.getPackageName().size() <= 1);
		if (yakinduCompilation.getFileName().isEmpty()) {
			yakinduCompilation.getFileName().add(fileName);
		}
		if (yakinduCompilation.getPackageName().isEmpty()) {
			yakinduCompilation.getPackageName().add(fileName);
		}
	}
	
	private void setStatechartCompilation(StatechartCompilation statechartCompilation, String statechartName) {
		checkArgument(statechartCompilation.getStatechartName().size() <= 1);
		if (statechartCompilation.getStatechartName().isEmpty()) {
			statechartCompilation.getStatechartName().add(statechartName);
		}
	}
	
	private void setCodeGeneration(CodeGeneration codeGeneration, String packageName) {
		checkArgument(codeGeneration.getPackageName().size() <= 1);
		if (codeGeneration.getPackageName().isEmpty()) {
			codeGeneration.getPackageName().add(packageName);
		}
		// TargetFolder set in setTargetFolder
	}
	
	private void setAnalysisModelTransformation(AnalysisModelTransformation analysisModelTransformation) {
		checkArgument(analysisModelTransformation.getFileName().size() <= 1);
		if (analysisModelTransformation.getFileName().isEmpty()) {
			String fileName = getNameWithoutExtension(getContainingFileName(analysisModelTransformation.getComponent()));
			analysisModelTransformation.getFileName().add(fileName);
		}
		checkArgument(analysisModelTransformation.getScheduler().size() <= 1);
		if (analysisModelTransformation.getScheduler().isEmpty()) {
			analysisModelTransformation.getScheduler().add(hu.bme.mit.gamma.yakindu.genmodel.Scheduler.RANDOM);
		}
	}
	
	private void setTestGeneration(TestGeneration testGeneration, String packageName) {
		checkArgument(testGeneration.getFileName().size() <= 1);
		checkArgument(testGeneration.getPackageName().size() <= 1);
		if (testGeneration.getPackageName().isEmpty()) {
			testGeneration.getPackageName().add(packageName);
		}
		if (testGeneration.getFileName().isEmpty()) {
			testGeneration.getFileName().add("ExecutionTraceSimulation");
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
			// E.g., /hu.bme.mit.gamma.tutorial.extra/model/TrafficLight/TrafficLightCtrl
			String statechartUri = component.eResource().getURI().trimFileExtension().toPlatformString(true);
			String statechartFileName = statechartUri.substring(statechartUri.lastIndexOf("/") + 1);
			String traceUri = statechartUri.substring(0, statechartUri.lastIndexOf("/") + 1) + "." + statechartFileName + ".y2g";
			if (resourceSet.getResources().stream().noneMatch(it -> it.getURI().toString().equals(traceUri))) {
				resourceSet.getResource(URI.createPlatformResourceURI(traceUri, true), true);
			}
		}
	}
	
	private String getContainingFileName(EObject object) {
		return object.eResource().getURI().lastSegment();
	}
	
	private String getNameWithoutExtension(String fileName) {
		return fileName.substring(0, fileName.lastIndexOf("."));
	}
	
	private Scheduler getGammaScheduler(hu.bme.mit.gamma.yakindu.genmodel.Scheduler scheduler) {
		switch (scheduler) {
		case FAIR:
			return Scheduler.FAIR;
		default:
			return Scheduler.RANDOM;
		}
	}
	
	/**
	 * Returns the CompositeDefinition from the resource that equals to the given composite.
	 */
	private Component getEquivalentComposite(Resource resource, Component component) {
		Package gammaPackage = (Package) resource.getContents().get(0);
		Component foundComponent = (Component) gammaPackage.getComponents().get(0);
		if (helperEquals(component, foundComponent)) {
			return foundComponent;
		}
		throw new IllegalArgumentException("No equivalent component!");
	}
	
	/**
	 * Returns whether the given objects are equal with respect to ecore copies.
	 */
	private boolean helperEquals(EObject lhs, EObject rhs) {
		EqualityHelper helper = new EqualityHelper();
		return helper.equals(lhs, rhs);
	}
	
	/**
	 * Responsible for saving the given element into a resource file.
	 */
	private void saveModel(EObject rootElem, String parentFolder, String fileName) throws IOException {
		if (rootElem instanceof Package) {
			try {
				// Trying to serialize the model
				serialize(rootElem, parentFolder, fileName);
			} catch (Exception e) {
				e.printStackTrace();
				logger.log(Level.WARNING, e.getMessage() + System.lineSeparator() +
						"Possibly you have two more model elements with the same name specified in the previous error message.");
				new File(parentFolder + File.separator + fileName).delete();
				// Saving like an EMF model
				String newFileName = fileName.substring(0, fileName.lastIndexOf(".")) + ".gsm";
				normalSave(rootElem, parentFolder, newFileName);
			}
		}
		else {
			// It is not a statechart model, regular saving
			normalSave(rootElem, parentFolder, fileName);
		}
	}

	private void normalSave(EObject rootElem, String parentFolder, String fileName) throws IOException {
		ResourceSet resourceSet = new ResourceSetImpl();
		Resource saveResource = resourceSet.createResource(URI.createFileURI(URI.decode(parentFolder + File.separator + fileName)));
		saveResource.getContents().add(rootElem);
		saveResource.save(Collections.EMPTY_MAP);
	}
	
	private void serialize(EObject rootElem, String parentFolder, String fileName) throws IOException {
		// This is how an injected object can be retrieved
		Injector injector = LanguageActivator.getInstance()
				.getInjector(LanguageActivator.HU_BME_MIT_GAMMA_STATECHART_LANGUAGE_STATECHARTLANGUAGE);
		StatechartLanguageSerializer serializer = injector.getInstance(StatechartLanguageSerializer.class);
		serializer.save(rootElem, URI.decode(parentFolder + File.separator + fileName));
	}
	
	/**
	 * Creates a Java class from the the given code at the location specified by the given URI.
	 */
	private void saveCode(String parentFolder, String fileName, String code) throws IOException {
		String path = parentFolder + File.separator + fileName;
		new File(path).getParentFile().mkdirs();
		try (FileWriter fileWriter = new FileWriter(path)) {
			fileWriter.write(code);
		}
	}
	
}