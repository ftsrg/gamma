/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.util;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.yakindu.base.types.Direction;
import org.yakindu.base.types.Event;
import org.yakindu.sct.model.sgraph.Scope;
import org.yakindu.sct.model.sgraph.Statechart;
import org.yakindu.sct.model.stext.stext.InterfaceScope;

import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.ExpressionPackage;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;
import hu.bme.mit.gamma.fei.model.FaultExtensionInstructions;
import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AbstractComplementaryTestGeneration;
import hu.bme.mit.gamma.genmodel.model.AdaptiveBehaviorConformanceChecking;
import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint;
import hu.bme.mit.gamma.genmodel.model.CodeGeneration;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.Constraint;
import hu.bme.mit.gamma.genmodel.model.ContractAutomatonType;
import hu.bme.mit.gamma.genmodel.model.Coverage;
import hu.bme.mit.gamma.genmodel.model.EventMapping;
import hu.bme.mit.gamma.genmodel.model.EventPriorityTransformation;
import hu.bme.mit.gamma.genmodel.model.FmeaTableGeneration;
import hu.bme.mit.gamma.genmodel.model.GenModel;
import hu.bme.mit.gamma.genmodel.model.GenmodelModelPackage;
import hu.bme.mit.gamma.genmodel.model.InterfaceCompilation;
import hu.bme.mit.gamma.genmodel.model.InterfaceMapping;
import hu.bme.mit.gamma.genmodel.model.ModelMutation;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.MutationBasedTestGeneration;
import hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint;
import hu.bme.mit.gamma.genmodel.model.PhaseStatechartGeneration;
import hu.bme.mit.gamma.genmodel.model.SafetyAssessment;
import hu.bme.mit.gamma.genmodel.model.SchedulingConstraint;
import hu.bme.mit.gamma.genmodel.model.StateCoverage;
import hu.bme.mit.gamma.genmodel.model.StatechartCompilation;
import hu.bme.mit.gamma.genmodel.model.StatechartContractGeneration;
import hu.bme.mit.gamma.genmodel.model.StatechartContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.Task;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.genmodel.model.TraceReplayModelGeneration;
import hu.bme.mit.gamma.genmodel.model.TransitionCoverage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.genmodel.model.XstsReference;
import hu.bme.mit.gamma.genmodel.model.YakinduCompilation;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.scenario.model.NegatedDeterministicOccurrence;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.util.FileUtil;

public class GenmodelValidator extends ExpressionModelValidator {
	// Singleton
	public static final GenmodelValidator INSTANCE = new GenmodelValidator();
	protected GenmodelValidator() {}
	//
	
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected final FileUtil fileUtil = FileUtil.INSTANCE;
	
	// Checking tasks, only one parameter is acceptable
	
	public Collection<ValidationResultMessage> checkTasks(Task task) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		List<String> fileNames = task.getFileName();
		if (fileNames.size() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"At most one file name can be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.TASK__FILE_NAME)));
		}
//		for (String fileName : fileNames) {
//			File file = new File(fileName);
//			if (file.getName() != fileName) {
//				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
//					"A file name cannot contain file separators",
//						new ReferenceInfo(GenmodelModelPackage.Literals.TASK__FILE_NAME)));
//			}
//		}
		
		if (task.getTargetFolder().size() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"At most one target folder can be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.TASK__TARGET_FOLDER)));
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTasks(YakinduCompilation yakinduCompilation) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (yakinduCompilation.getPackageName().size() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"At most one package name can be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.YAKINDU_COMPILATION__PACKAGE_NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTasks(StatechartCompilation statechartCompilation) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (statechartCompilation.getStatechartName().size() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"At most one statechart name can be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.STATECHART_COMPILATION__STATECHART_NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTasks(AnalysisModelTransformation analysisModelTransformation) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (analysisModelTransformation.getScheduler().size() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"At most one scheduler type can be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__SCHEDULER)));
		}
		List<AnalysisLanguage> languages = analysisModelTransformation.getLanguages();
		if (languages.size() != languages.stream().collect(Collectors.toSet()).size()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A single formal language can be specified only once",
					new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__LANGUAGES)));
		}
		ModelReference modelReference = analysisModelTransformation.getModel();
		if (modelReference instanceof XstsReference) {
			if (languages.stream().anyMatch(it -> it != AnalysisLanguage.UPPAAL)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"XSTS models can be transformed only to UPPAAL",
						new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__LANGUAGES)));
			}
		}
		if (analysisModelTransformation.getCoverages().stream().filter(it -> it instanceof TransitionCoverage).count() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A single transition coverage task can be defined",
					new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__COVERAGES)));
		}
		if (analysisModelTransformation.getCoverages().stream().filter(it -> it instanceof StateCoverage).count() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A single state coverage task can be defined",
					new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__COVERAGES)));
		}
		Constraint constraint = analysisModelTransformation.getConstraint();
		if (constraint != null) {
			if (modelReference instanceof ComponentReference) {
				ComponentReference componentReference = (ComponentReference)modelReference;
				Component component = componentReference.getComponent();
				if (component instanceof AsynchronousComponent && constraint instanceof OrchestratingConstraint) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Asynchronous component constraints must contain either "
							+ "a 'top' keyword or references to the contained instances",
							new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__CONSTRAINT)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTasks(Verification verification) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<AnalysisLanguage> languages = verification.getAnalysisLanguages();
		if (languages.size() != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"A single formal language must be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.VERIFICATION__ANALYSIS_LANGUAGES)));
		}
		File resourceFile = ecoreUtil.getFile(verification.eResource());
		List<String> modelFiles = verification.getFileName();
		if (modelFiles.size() != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"A single model file must be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.TASK__FILE_NAME)));
		}
		for (String modelFile : modelFiles) {
			if (!fileUtil.isValidRelativeFile(resourceFile, modelFile)) {
				int index = modelFiles.indexOf(modelFile);
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This is not a valid relative path to a model file: " + modelFile,
						new ReferenceInfo(GenmodelModelPackage.Literals.TASK__FILE_NAME, index)));
			}
		}
		List<String> queryFiles = verification.getQueryFiles();
		List<PropertyPackage> propertyPackages = verification.getPropertyPackages();
		if (queryFiles.size() + propertyPackages.size() < 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"At least one query file must be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.VERIFICATION__QUERY_FILES)));
		}
		for (String queryFile : queryFiles) {
			if (!fileUtil.isValidRelativeFile(resourceFile, queryFile)) {
				int index = queryFiles.indexOf(queryFile);
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This is not a valid relative path to a query file: " + queryFile,
						new ReferenceInfo(GenmodelModelPackage.Literals.VERIFICATION__QUERY_FILES, index)));
			}
		}
		if (verification.isBackAnnotateToOriginal()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
				"This setting can be used only if the default name is not changed during the " +
					"derivation of the analysis model ('file' setting is not used in the analysis task)",
						new ReferenceInfo(GenmodelModelPackage.Literals.VERIFICATION__BACK_ANNOTATE_TO_ORIGINAL)));
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTasks(AbstractComplementaryTestGeneration testGeneration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<String> testFolders = testGeneration.getTestFolder();
		if (testFolders.size() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"At most one test folder can be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.ABSTRACT_COMPLEMENTARY_TEST_GENERATION__TEST_FOLDER)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTasks(TraceReplayModelGeneration modelGeneration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<String> systemFileNames = modelGeneration.getFileName();
		if (systemFileNames.size() != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"A single system file name must be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.TASK__FILE_NAME)));
		}
		List<String> targetFolders = modelGeneration.getTargetFolder();
		if (targetFolders.size() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"At most one test folder can be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.TASK__TARGET_FOLDER)));
		}
		List<String> traceFolders = modelGeneration.getExecutionTraceFolder();
		ExecutionTrace executionTrace = modelGeneration.getExecutionTrace();
		if (traceFolders.isEmpty() && executionTrace == null) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"At least one execution trace or a containing folder has to be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.TRACE_REPLAY_MODEL_GENERATION__EXECUTION_TRACE)));
		}
		File resourceFile = ecoreUtil.getFile(modelGeneration.eResource());
		for (String traceFolder : traceFolders) {
			if (!fileUtil.isValidRelativeFile(resourceFile, traceFolder)) {
				int index = traceFolders.indexOf(traceFolder);
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This is not a valid relative path to a trace folder: " + traceFolder,
						new ReferenceInfo(GenmodelModelPackage.Literals.TRACE_REPLAY_MODEL_GENERATION__EXECUTION_TRACE_FOLDER, index)));
			}
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTimeSpecification(TimeSpecification timeSpecification) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!typeDeterminator.isInteger(timeSpecification.getValue())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Time values must be of type integer",
					new ReferenceInfo(InterfaceModelPackage.Literals.TIME_SPECIFICATION__VALUE)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkConstraint(AsynchronousInstanceConstraint constraint) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		AnalysisModelTransformation analysisModelTransformation = ecoreUtil.getContainerOfType(
				constraint, AnalysisModelTransformation.class);
		ModelReference modelReference = analysisModelTransformation.getModel();
		if (modelReference instanceof ComponentReference) {
			ComponentReference componentReference = (ComponentReference)modelReference;
			Component component = componentReference.getComponent();
			if (!hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.isAsynchronous(component)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Asynchronous component constraints must refer to an asynchronous component",
						new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__ORCHESTRATING_CONSTRAINT)));
				return validationResultMessages;
			}
			SchedulingConstraint scheduling = ecoreUtil.getContainerOfType(constraint, SchedulingConstraint.class);
			ComponentInstanceReferenceExpression instance = constraint.getInstance();
			if (instance != null) {
				ComponentInstance lastInstance = StatechartModelDerivedFeatures.getLastInstance(instance);
				if (!hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.isAsynchronous(lastInstance)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Asynchronous component constraints must contain a reference to a contained asynchronous instance",
							new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE)));
				}
			}
			if (component instanceof AsynchronousCompositeComponent) {
				if (instance == null) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Asynchronous component constraints must contain a reference to a contained instance",
							new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE)));
				}
				if (scheduling.getInstanceConstraint().stream()
						.filter(it -> ecoreUtil.helperEquals(it.getInstance(), instance)).count() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"The scheduling constraints for a certain asynchronous component can be defined at most once",
							new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE)));
				}
			}
			if (component instanceof AsynchronousAdapter) {
				if (scheduling.getInstanceConstraint().size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Asynchronous adapters can contain at most one constraint",
							new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__ORCHESTRATING_CONSTRAINT)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkMinimumMaximumOrchestrationPeriodValues(
				OrchestratingConstraint orchestratingConstraint) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			TimeSpecification minimum = orchestratingConstraint.getMinimumPeriod();
			TimeSpecification maximum = orchestratingConstraint.getMaximumPeriod();
			if (minimum != null) {
				if (maximum != null) {
					int minimumIntegerValue = statechartUtil.evaluateMilliseconds(minimum);
					int maximumIntegerValue = statechartUtil.evaluateMilliseconds(maximum);
					if (minimumIntegerValue < 0) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
								"Time value must be positive",
								new ReferenceInfo(GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MINIMUM_PERIOD)));
					}
					if (maximumIntegerValue < 0) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
								"Time value must be positive",
								new ReferenceInfo(GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MAXIMUM_PERIOD)));
					}
					if (maximumIntegerValue < minimumIntegerValue) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"The minimum orchestrating period value must be greater than the maximum orchestrating period value",
								new ReferenceInfo(GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MINIMUM_PERIOD)));
					}
				}
			}
		} catch (IllegalArgumentException e) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Both the minimum and maximum values must be of type integer",
					new ReferenceInfo(GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MINIMUM_PERIOD)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTasks(CodeGeneration codeGeneration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (codeGeneration.getPackageName().size() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"At most one package name can be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME)));
		}
		if (codeGeneration.getProgrammingLanguages().size() != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A single programming language must be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTasks(TestGeneration testGeneration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (testGeneration.getPackageName().size() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"At most one package name can be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME)));
		}
		if (testGeneration.getProgrammingLanguages().size() != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A single programming language must be specified",
					new ReferenceInfo(GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkReferredComponentTasks(AdaptiveContractTestGeneration testGeneration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ValidationResultMessage validationResultMessage = new ValidationResultMessage(ValidationResult.ERROR, 
				"In the case of adaptive contract test generation, the referred component must be a statechart "
				+ "with an @AdaptiveContractAnnotation", 
				new ReferenceInfo(GenmodelModelPackage.Literals
						.ADAPTIVE_CONTRACT_TEST_GENERATION__MODEL_TRANSFORMATION));
		
		AnalysisModelTransformation analysisModelTransformationTask = testGeneration.getModelTransformation();
		ModelReference modelReference = analysisModelTransformationTask.getModel();
		if (modelReference instanceof ComponentReference) {
			ComponentReference componentReference = (ComponentReference) modelReference;
			Component component = componentReference.getComponent();
			if (component instanceof StatechartDefinition) {
				StatechartDefinition statechartDefinition = (StatechartDefinition) component;
				if (StatechartModelDerivedFeatures.isAdaptiveContract(statechartDefinition)) {
					return validationResultMessages; // Everything is correct, returning with empty list
				}
			}
		}
		// Something is wrong, returning with an error message
		validationResultMessages.add(validationResultMessage);
		return validationResultMessages;
	}
	
	// Additional validation rules
	
	public Collection<ValidationResultMessage> checkGammaImports(GenModel genmodel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		Set<Package> packageImports = genmodel.getPackageImports().stream().collect(Collectors.toSet());
		List<Task> tasks = genmodel.getTasks();
		for (CodeGeneration task : javaUtil.filterIntoList(tasks,CodeGeneration.class)) {
			Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(task.getComponent());
			packageImports.remove(parentPackage);
		}
		for (AnalysisModelTransformation task :
				javaUtil.filterIntoList(tasks, AnalysisModelTransformation.class)) {
			packageImports.removeAll(
					getUsedPackages(task));
		}
		for (SafetyAssessment task : javaUtil.filterIntoList(tasks, SafetyAssessment.class)) {
			packageImports.removeAll(
					getUsedPackages(task.getAnalysisModelTransformation()));
		}
		for (StatechartCompilation task :
				javaUtil.filterIntoList(tasks, StatechartCompilation.class)) {
			for (InterfaceMapping interfaceMapping : task.getInterfaceMappings()) {
				Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(
						interfaceMapping.getGammaInterface());
				packageImports.remove(parentPackage);
			}
		}
		for (EventPriorityTransformation task :
					javaUtil.filterIntoList(tasks, EventPriorityTransformation.class)) {
			Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(
					task.getStatechart());
			packageImports.remove(parentPackage);
		}
		for (AdaptiveContractTestGeneration task :
					javaUtil.filterIntoList(tasks, AdaptiveContractTestGeneration.class)) {
			packageImports.removeAll(
					getUsedPackages(task.getModelTransformation()));
		}
		for (AdaptiveBehaviorConformanceChecking task :
					javaUtil.filterIntoList(tasks, AdaptiveBehaviorConformanceChecking.class)) {
			packageImports.removeAll(
					getUsedPackages(task.getModelTransformation()));
		}
		for (StatechartContractTestGeneration task :
				javaUtil.filterIntoList(tasks, StatechartContractTestGeneration.class)) {
			ComponentReference componentReference = task.getComponentReference();
			packageImports.remove(StatechartModelDerivedFeatures.getContainingPackage(
					componentReference.getComponent()));
		}
		for (StatechartContractGeneration task :
				javaUtil.filterIntoList(tasks, StatechartContractGeneration.class)) {
			packageImports.remove(StatechartModelDerivedFeatures.getContainingPackage(
					task.getScenario()));
		}
		for (PhaseStatechartGeneration task : 
				javaUtil.filterIntoList(tasks, PhaseStatechartGeneration.class)) {
			Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(
					task.getStatechart());
			packageImports.remove(parentPackage);
		}
		for (ModelMutation task : javaUtil.filterIntoList(tasks, ModelMutation.class)) {
			ModelReference modelReference = task.getModel();
			EObject model = GenmodelDerivedFeatures.getModel(modelReference);
			packageImports.remove(
					StatechartModelDerivedFeatures.getContainingPackage(model));
		}
		for (MutationBasedTestGeneration task :
				javaUtil.filterIntoList(tasks, MutationBasedTestGeneration.class)) {
			packageImports.removeAll(
					getUsedPackages(task.getAnalysisModelTransformation()));
		}
		for (ReferenceExpression reference : ecoreUtil.getAllContentsOfType(genmodel, ReferenceExpression.class)) {
			if (reference instanceof ComponentInstanceReferenceExpression) {
				ComponentInstanceReferenceExpression instanceReference = (ComponentInstanceReferenceExpression) reference;
				List<ComponentInstance> componentInstanceChain =
						StatechartModelDerivedFeatures.getComponentInstanceChain(instanceReference);
				List<Package> packages = componentInstanceChain.stream()
						.map(it -> StatechartModelDerivedFeatures.getContainingPackage(it))
						.collect(Collectors.toList());
				packageImports.removeAll(packages);
			}
			else {
				Declaration declaration = statechartUtil.getAccessedDeclaration(reference);
				ExpressionPackage expressionPackage = ecoreUtil.getContainerOfType(declaration, ExpressionPackage.class);
				packageImports.remove(expressionPackage);
			}
		}
		for (Package packageImport : packageImports) {
			int index = genmodel.getPackageImports().indexOf(packageImport);
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"This package import is not used",
					new ReferenceInfo(GenmodelModelPackage.Literals.GEN_MODEL__PACKAGE_IMPORTS, index)));
		}
		return validationResultMessages;
	}

	private Set<Package> getUsedPackages(AnalysisModelTransformation analysisModelTransformationTask) {
		Set<Package> packageImports = new HashSet<Package>();
		ModelReference modelReference = analysisModelTransformationTask.getModel();
		if (modelReference instanceof ComponentReference) {
			ComponentReference componentReference = (ComponentReference)modelReference;
			Component component = componentReference.getComponent();
			Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(component);
			packageImports.add(parentPackage);
		}
		for (Coverage coverage : analysisModelTransformationTask.getCoverages()) {
			List<ComponentInstanceReferenceExpression> allCoverages = new ArrayList<ComponentInstanceReferenceExpression>();
			allCoverages.addAll(coverage.getInclude());
			allCoverages.addAll(coverage.getExclude());
			for (ComponentInstanceReferenceExpression instance : allCoverages) {
				Package instanceParentPackage = StatechartModelDerivedFeatures.getContainingPackage(instance);
				packageImports.add(instanceParentPackage);
			}
		}
		return packageImports;
	}
	
	public Collection<ValidationResultMessage> checkYakinduImports(GenModel genmodel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Set<Statechart> statechartImports = genmodel.getStatechartImports().stream().collect(Collectors.toSet());
		for (YakinduCompilation statechartCompilationTask : javaUtil.filterIntoList(
					genmodel.getTasks(), YakinduCompilation.class)) {
			statechartImports.remove(statechartCompilationTask.getStatechart());
		}
		for (Statechart statechartImport : statechartImports) {
			int index = genmodel.getStatechartImports().indexOf(statechartImport);
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"This Yakindu import is not used",
					new ReferenceInfo(GenmodelModelPackage.Literals.GEN_MODEL__STATECHART_IMPORTS, index)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTraceImports(GenModel genmodel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Set<ExecutionTrace> traceImports = genmodel.getTraceImports().stream().collect(Collectors.toSet());
		for (TestGeneration testGenerationTask : javaUtil.filterIntoList(genmodel.getTasks(), TestGeneration.class)) {
			traceImports.remove(testGenerationTask.getExecutionTrace());
		}
		for (TraceReplayModelGeneration testReplayModelGeneration : javaUtil.filterIntoList(
					genmodel.getTasks(), TraceReplayModelGeneration.class)) {
			traceImports.remove(testReplayModelGeneration.getExecutionTrace());
		}
		for (ExecutionTrace traceImport : traceImports) {
			int index = genmodel.getTraceImports().indexOf(traceImport);
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"This execution trace import is not used",
					new ReferenceInfo(GenmodelModelPackage.Literals.GEN_MODEL__TRACE_IMPORTS, index)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkArgumentTypes(ArgumentedElement argumentedElement) {
		List<ParameterDeclaration> parameterDeclarations =
				GenmodelDerivedFeatures.getParameterDeclarations(argumentedElement);
		return checkArgumentTypes(argumentedElement, parameterDeclarations);
	}
	
	public Collection<ValidationResultMessage> checkComponentInstanceArguments(
			AnalysisModelTransformation analysisModelTransformation) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			ModelReference modelReference = analysisModelTransformation.getModel();
			if (modelReference instanceof ComponentReference componentReference) {
				Component type = componentReference.getComponent();
				List<ParameterDeclaration> parameters = type.getParameterDeclarations();
				for (var i = 0; i < parameters.size(); i++) {
					ParameterDeclaration parameter = parameters.get(i);
					Expression argument = modelReference.getArguments().get(i);
					Type declarationType = parameter.getType();
					if (!typeDeterminator.equalsType(declarationType, argument)) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"The types of the declaration and the right hand side expression are not the same: " +
								typeDeterminator.print(declarationType) + " and " + typeDeterminator.print(argument),
								new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, i)));
					} 
				}
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkIfAllInterfacesMapped(StatechartCompilation statechartCompilation) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Set<InterfaceScope> interfaces = new HashSet<InterfaceScope>();
		EList<Scope> scopes = statechartCompilation.getStatechart().getScopes();
		interfaces = javaUtil.filterIntoList(scopes, InterfaceScope.class).stream().collect(Collectors.toSet());

		Set<InterfaceScope> mappedInterfaces = new HashSet<InterfaceScope>();
		for (InterfaceMapping interfaceMapping: statechartCompilation.getInterfaceMappings()) {
			mappedInterfaces.add(interfaceMapping.getYakinduInterface());
		}
		interfaces.removeAll(mappedInterfaces);
		if (!interfaces.isEmpty()) {
			Set<InterfaceScope> interfacesWithEvents = interfaces.stream()
					.filter(it -> !it.getEvents().isEmpty()).collect(Collectors.toSet());
			Set<InterfaceScope> interfacesWithoutEvents = interfaces.stream()
					.filter(it -> it.getEvents().isEmpty()).collect(Collectors.toSet());
			if (!interfacesWithEvents.isEmpty()) {
				for (InterfaceScope interfacesWithEventsMap : interfacesWithEvents) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"The following interfaces with events are not mapped: " + interfacesWithEventsMap.getName(),
							new ReferenceInfo(GenmodelModelPackage.Literals.YAKINDU_COMPILATION__STATECHART)));
				}
			}
			if (!interfacesWithoutEvents.isEmpty()) {
				for (InterfaceScope interfacesWithoutEventsMap : interfacesWithoutEvents) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO, 
							"The following interfaces without events are not mapped: " + interfacesWithoutEventsMap.getName(),
							new ReferenceInfo(GenmodelModelPackage.Literals.YAKINDU_COMPILATION__STATECHART)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInterfaceConformance(InterfaceMapping mapping) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!(checkConformance(mapping))) {
			RealizationMode realizationMode = mapping.getRealizationMode();
			switch (realizationMode) {
				case PROVIDED:
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"In case of provided realization mode number of in/out events must equal to "
							+ "the number of in/out events in the Gamma interface and vice versa",
							new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)));
					break;
				case REQUIRED:
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"In case of required realization mode number of in/out events must equal to "
							+ "the number of out/in events in the Gamma interface and vice versa",
							new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)));
					break;
				default:
					throw new IllegalArgumentException("Such interface realization mode is not supported: " + realizationMode);
			}
		}
		return validationResultMessages;
	}
	
	/** It checks the events of the parent interfaces as well. */
	public boolean checkConformance(InterfaceMapping mapping) {
		long yOut = mapping.getYakinduInterface().getEvents().stream()
				.filter(it -> it.getDirection() == Direction.OUT).count();
		long yIn = mapping.getYakinduInterface().getEvents().stream()
				.filter(it -> it.getDirection() == Direction.IN).count();
		long gOut = StatechartModelDerivedFeatures.getAllEventDeclarations(mapping.getGammaInterface())
				.stream().filter(it -> it.getDirection() != EventDirection.IN).count(); // Regarding in-out events
		long gIn = StatechartModelDerivedFeatures.getAllEventDeclarations(mapping.getGammaInterface())
				.stream().filter(it -> it.getDirection() != EventDirection.OUT).count(); // Regarding in-out events
		RealizationMode realMode = mapping.getRealizationMode();
		return (realMode == RealizationMode.PROVIDED && yOut == gOut && yIn == gIn) ||
			(realMode == RealizationMode.REQUIRED && yOut == gIn && yIn == gOut);
	}
	
	public Collection<ValidationResultMessage> checkInterfaceMappingWithoutEventMapping(InterfaceMapping mapping) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// 0 event mapping is acceptable if the two interfaces are equal
		RealizationMode realizationMode = mapping.getRealizationMode();
		if (mapping.getEventMappings().size() == 0) {
			// If the interface has in-out events, 0 event mapping is surely not acceptable
			if (!(mapping.getGammaInterface().getEvents().stream()
					.filter(it -> it.getDirection() == EventDirection.INOUT).count() == 0)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"The Gamma interface has in-out events, thus an automatic mapping is not possible",
						new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)));
				return validationResultMessages;
			}
			for (Event yakinduEvent : mapping.getYakinduInterface().getEvents()) {
				List<hu.bme.mit.gamma.statechart.interface_.Event> gammaEvents = mapping.getGammaInterface().getEvents()
						.stream().map(it -> it.getEvent())
						.filter(it -> it.getName().equals(yakinduEvent.getName()))
						.collect(Collectors.toList());
				if (!(gammaEvents.size() == 1 && checkParameters(yakinduEvent, gammaEvents.get(0))
						&& areWellDirected(realizationMode, yakinduEvent, (EventDeclaration) gammaEvents.get(0).eContainer()))) {
					String typeName = "";
					if (yakinduEvent.getType() != null) {
						typeName = " : " + yakinduEvent.getType().getName();
					} else {
						typeName = "";
					}
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"Interface mapping without event mapping is only possible if the "
							+ "names and types of the events of the interfaces are equal; " 
							+ yakinduEvent.getName() + typeName + " has no equivalent event in the Gamma interface",
							new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)));
					}
				}			
			}
		return validationResultMessages;
	}
	
	/**
	 * Checks whether the event directions conform to the realization mode.
	 */
	public boolean areWellDirected(RealizationMode interfaceType, org.yakindu.base.types.Event yEvent, EventDeclaration gEvent) {
		if (interfaceType == RealizationMode.PROVIDED) {
			return (yEvent.getDirection() == Direction.OUT && gEvent.getDirection() != EventDirection.IN) ||
			(yEvent.getDirection() == Direction.IN && gEvent.getDirection() != EventDirection.OUT);
		}
		else if (interfaceType == RealizationMode.REQUIRED) {
			return (yEvent.getDirection() == Direction.OUT && gEvent.getDirection() != EventDirection.OUT) ||
			(yEvent.getDirection() == Direction.IN && gEvent.getDirection() != EventDirection.IN);
		}
		else {
			throw new IllegalArgumentException("No such direction: " + interfaceType);
		}
	}
	
	public Collection<ValidationResultMessage> checkMappingCount(InterfaceMapping mapping) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// Check only if the interface mapping is not trivial (size != 0)
		if (mapping.getEventMappings().size() != 0 &&
				mapping.getYakinduInterface().getEvents().size() != mapping.getEventMappings().size()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Each Yakindu event has to be mapped exactly once",
					new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkYakinduInterfaceUniqueness(InterfaceMapping mapping) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Set<InterfaceScope> interfaces = new HashSet<InterfaceScope>();
		StatechartCompilation statechartCompilation = (StatechartCompilation)mapping.eContainer();
		for (InterfaceScope interface_ : statechartCompilation.getInterfaceMappings().stream()
				.map(it -> it.getYakinduInterface()).collect(Collectors.toList())) {
			if (interfaces.contains(interface_)){
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Each Yakindu event has to be mapped exactly once",
						new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)));
			}
			else {
				interfaces.add(interface_);
			}			
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkEventMappingCount(InterfaceMapping mapping) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Set<Event> mappedYakinduEvents = new HashSet<Event>();
		Map<hu.bme.mit.gamma.statechart.interface_.Event, Set<Event>> mappedGammaEvents = new HashMap<>();
		for (EventMapping eventMapping : mapping.getEventMappings()) {
			org.yakindu.base.types.Event yakinduEvent = eventMapping.getYakinduEvent();
			hu.bme.mit.gamma.statechart.interface_.Event gammaEvent = eventMapping.getGammaEvent();
			// Yakindu validation
			if (mappedYakinduEvents.contains(yakinduEvent)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This event is mapped multiple times: " + yakinduEvent.getName(),
						new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)));
			}
			else {
				mappedYakinduEvents.add(yakinduEvent);			
			}
			// Gamma validation
			if (mappedGammaEvents.containsKey(gammaEvent)) {
				EventDeclaration gammaEventDeclaration = (EventDeclaration)gammaEvent.eContainer();
				if (gammaEventDeclaration.getDirection() == EventDirection.INOUT) {
					Set<Event> yakinduEventSet = mappedGammaEvents.get(gammaEvent);
					yakinduEventSet.add(yakinduEvent);
					// A single in and a single out event has to be now in yakinduEventSet
					if (!(yakinduEventSet.stream().filter(it -> it.getDirection() == Direction.IN).count() == 1 &&
							yakinduEventSet.stream().filter(it -> it.getDirection() == Direction.OUT).count() == 1)) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"A single in and a single out event has to be mapped onto this Gamma event: " + gammaEvent.getName(),
								new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)));
					}
				}
				else {
					// Not an in-out event
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"Multiple Yakindu events are mapped to this Gamma event: " + gammaEvent.getName(),
							new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)));
				}
			}
			else {
				// First entry
				Set<Event> set = new HashSet<Event>();
				set.add(yakinduEvent);
				mappedGammaEvents.put(gammaEvent, set);
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkEventConformance(EventMapping mapping) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		InterfaceMapping ifReal = (InterfaceMapping)mapping.eContainer();
		if (!(checkConformance(mapping))) {
			switch (ifReal.getRealizationMode()) {
				case PROVIDED:
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"In case of provided realization mode Yakindu events must have "
							+ "the same direction and parameter as Gamma events",
							new ReferenceInfo(GenmodelModelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT)));
					break;
				case REQUIRED:	
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"In case of required realization mode Yakindu events must have "
							+ "the opposite direction and same parameter of Gamma events",
							new ReferenceInfo(GenmodelModelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT)));
					break;
				default:
				throw new IllegalArgumentException("Such interface realization mode is not supported: " + ifReal.getRealizationMode());				
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTraces(TestGeneration testGeneration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		GenModel genmodel = (GenModel)testGeneration.eContainer(); 
		Set<String> usedInterfaces = testGeneration.getExecutionTrace().getComponent().getPorts().stream()
				.map(it -> it.getInterfaceRealization().getInterface().getName())
				.collect(Collectors.toSet()); 
		List<List<Scope>> interfaceCompilation = javaUtil.filterIntoList(genmodel.getTasks(), InterfaceCompilation.class).stream()
				.map(it -> it.getStatechart().getScopes())
				.collect(Collectors.toList());
		Iterable<Scope> flattenList = javaUtil.flattenIntoList(interfaceCompilation);
		Set<String> transformedInterfaces = javaUtil.filterIntoList(flattenList, InterfaceScope.class).stream()
				.map(it -> it.getName())
				.collect(Collectors.toSet());

		usedInterfaces.retainAll(transformedInterfaces);
		if (!usedInterfaces.isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"This trace depends on interfaces " + usedInterfaces + ", which are about to be recompiled; " + 
						"the recompilation of interfaces just before the generation of "
						+ "tests might cause a break in the generated test suite",
					new ReferenceInfo(GenmodelModelPackage.Literals.TEST_GENERATION__EXECUTION_TRACE)));
		}
		return validationResultMessages;
	}
	
	public boolean checkConformance(EventMapping mapping) {
		org.yakindu.base.types.Event yEvent = mapping.getYakinduEvent();
		EventDeclaration gEvent = (EventDeclaration)mapping.getGammaEvent().eContainer();
		InterfaceMapping ifReal = (InterfaceMapping)mapping.eContainer();
		RealizationMode realMode = ifReal.getRealizationMode();
		return checkEventConformance(yEvent, gEvent, realMode);
	}
	
	public boolean checkEventConformance(org.yakindu.base.types.Event yEvent, EventDeclaration gEvent, RealizationMode realMode) {
		switch (realMode) {
			 // Regarding in-out events
			case PROVIDED:
				return yEvent.getDirection() == Direction.IN && gEvent.getDirection() != EventDirection.OUT &&
					checkParameters(yEvent, gEvent.getEvent()) ||
							yEvent.getDirection() == Direction.OUT && gEvent.getDirection() != EventDirection.IN &&
								checkParameters(yEvent, gEvent.getEvent());
			case REQUIRED:
				return yEvent.getDirection() == Direction.IN && gEvent.getDirection() != EventDirection.IN &&
					checkParameters(yEvent, gEvent.getEvent()) ||
						yEvent.getDirection() == Direction.OUT && gEvent.getDirection() != EventDirection.OUT &&
							checkParameters(yEvent, gEvent.getEvent());
			default:
				throw new IllegalArgumentException("Such interface realization mode is not supported: " + realMode);				
		}
	}
	
	public boolean checkParameters(Event yakinduEvent, hu.bme.mit.gamma.statechart.interface_.Event gEvent) {
		// event.type is null not void if no explicit type is declared
		org.yakindu.base.types.Type yakinduType = yakinduEvent.getType();
		List<ParameterDeclaration> gammaParameters = gEvent.getParameterDeclarations();
		if (yakinduType == null && gammaParameters.isEmpty()) {
			return true;
		}
		if (!gammaParameters.isEmpty()) {
			Type eventType = gammaParameters.get(0).getType();
			if (eventType instanceof IntegerTypeDefinition) {
				if (yakinduType == null) {
					return false;
				}
				return yakinduType.getName().equals("integer") ||
						yakinduType.getName().equals("string"); 
			}
			else if (eventType instanceof BooleanTypeDefinition) {
				if (yakinduType == null) {
					return false;
				}
				return yakinduType.getName().equals("boolean");
			}
			else if (eventType instanceof DecimalTypeDefinition) {
				if (yakinduType == null) {
					return false;
				}
				return yakinduType.getName().equals("real");
			}
			else if (eventType instanceof TypeReference) {
				return false; // Yakindu does not support composite types
			}
			else {
				throw new IllegalArgumentException("Not known type: " + gammaParameters.get(0).getType());
			}
		}
		return false;
	}
	
	// Duplicated in StatechartModelValidator
	public Collection<ValidationResultMessage> checkComponentInstanceReferences(ComponentInstanceReferenceExpression reference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		ComponentInstance instance = reference.getComponentInstance();
		ComponentInstanceReferenceExpression child = reference.getChild();
		if (child != null) {
			ComponentInstance childInstance = child.getComponentInstance();
			if (!StatechartModelDerivedFeatures.contains(instance, childInstance)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					instance.getName() + " does not contain component instance " + childInstance.getName(),
						new ReferenceInfo(CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE)));
			}
		}
		
		if (StatechartModelDerivedFeatures.isFirst(reference)) {
			AnalysisModelTransformation model = ecoreUtil.getContainerOfType(reference, AnalysisModelTransformation.class);
			if (model != null) {
				ModelReference modelReference = model.getModel();
				if (modelReference instanceof ComponentReference) {
					ComponentReference componentReference = (ComponentReference) modelReference;
					Component component = componentReference.getComponent();
					List<ComponentInstance> containedComponents = StatechartModelDerivedFeatures.getInstances(component);
					if (!containedComponents.contains(instance)) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"The first component instance must be the component of " + component.getName(),
								new ReferenceInfo(CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE)));
					}
				}
			}
		}
		
		// The last instance is not necessarily a statechart instance here
		
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkNegatedInteractionInTestAutomatonGeneration(
			StatechartContractGeneration statechartGeneration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (statechartGeneration.getAutomatonType() == ContractAutomatonType.MONITOR) {
			return validationResultMessages;
		}
		List<NegatedDeterministicOccurrence> negatedModelinteractions = ecoreUtil
				.getAllContentsOfType(statechartGeneration.getScenario(), NegatedDeterministicOccurrence.class);
		if (negatedModelinteractions.size() > 0) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
					"The referenced scenario contains negated interactions, which will not take effect in the generated tests",
					new ReferenceInfo(GenmodelModelPackage.Literals.STATECHART_CONTRACT_GENERATION__SCENARIO,
							statechartGeneration)));
		}
		return validationResultMessages;
	}
	
	//
	
	
	public Collection<ValidationResultMessage> checkTasks(SafetyAssessment safetyAssessment) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();

		AnalysisModelTransformation analysisModelTransformation = safetyAssessment.getAnalysisModelTransformation();
		validationResultMessages.addAll(
				checkTasks(analysisModelTransformation));
		
		List<AnalysisLanguage> languages = analysisModelTransformation.getLanguages();
		if (languages.size() != 1 || languages.stream().anyMatch(it -> it != AnalysisLanguage.NUXMV)) {
			validationResultMessages.add(
				new ValidationResultMessage(ValidationResult.ERROR, "Only SMV/nuXmv is supported", 
					new ReferenceInfo(GenmodelModelPackage.Literals.SAFETY_ASSESSMENT__ANALYSIS_MODEL_TRANSFORMATION)));
		}
		
		List<String> faultExtensionInstructionsFile = safetyAssessment.getFaultExtensionInstructionsFile();
		int feiSize = faultExtensionInstructionsFile.size();
		List<String> faultModesFile = safetyAssessment.getFaultModesFile();
		int fmSize = faultModesFile.size();
		FaultExtensionInstructions gFei = safetyAssessment.getFaultExtensionInstructions();
		int gFeiSize = gFei == null ? 0 : 1;
		
		if (!(feiSize * fmSize * gFeiSize == 0 && feiSize + fmSize + gFeiSize == 1)) {
			validationResultMessages.add(
					new ValidationResultMessage(ValidationResult.ERROR, "A single fei or fm file must be specified", 
						new ReferenceInfo(safetyAssessment)));
			return validationResultMessages;
		}
		
		List<String> files = new ArrayList<String>();
		files.addAll(faultExtensionInstructionsFile);
		files.addAll(faultModesFile);
		
		File resourceFile = ecoreUtil.getFile(safetyAssessment.eResource());

		validationResultMessages.addAll(
				checkRelativeFilePaths(resourceFile, files,
						List.of(GenmodelModelPackage.Literals.SAFETY_ASSESSMENT__FAULT_EXTENSION_INSTRUCTIONS_FILE,
								GenmodelModelPackage.Literals.SAFETY_ASSESSMENT__FAULT_MODES_FILE))
				);
		
		return validationResultMessages;
	}
	
	
	public Collection<ValidationResultMessage> checkSafetyAssessment(SafetyAssessment safetyAssessment) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		AnalysisModelTransformation analysisModelTransformation = safetyAssessment.getAnalysisModelTransformation();
		List<String> fileName = safetyAssessment.getFileName();
		boolean noFileGiven = fileName.isEmpty();
		
		if (analysisModelTransformation == null && noFileGiven) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"The safety assessment task must have either an analysis model transformation specification " +
						"or a file name that refers to the extendable smv model",
					new ReferenceInfo(safetyAssessment)));
		}
		else if (analysisModelTransformation == null && !noFileGiven) {
			validationResultMessages.addAll(
					checkRelativeFilePath(safetyAssessment, fileName.get(0),
							GenmodelModelPackage.Literals.TASK__FILE_NAME));
		}
		
		//
		
		List<String> feiFile = safetyAssessment.getFaultExtensionInstructionsFile();
		FaultExtensionInstructions feiModel = safetyAssessment.getFaultExtensionInstructions();
		int feiFileSize = feiFile.size();
		int feiFilesSize = feiFileSize + (feiModel != null ? 1 : 0);
		boolean notOneFeiFileGiven = feiFilesSize != 1;
		
		if (notOneFeiFileGiven) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"A single fei file must be specified", new ReferenceInfo(safetyAssessment)));
		}
		else if (feiFileSize > 0) {
			validationResultMessages.addAll(
					checkRelativeFilePath(safetyAssessment, feiFile.get(0),
							GenmodelModelPackage.Literals.SAFETY_ASSESSMENT__FAULT_EXTENSION_INSTRUCTIONS_FILE));
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkFmeaTableGeneration(
			FmeaTableGeneration fmeaTableGeneration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		Expression cardinality = fmeaTableGeneration.getCardinality();
		if (cardinality == null) {
			return validationResultMessages;
		}
		
		try {
			int value = expressionEvaluator.evaluateInteger(cardinality);
			if (value < 1) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The cardinality must be a positive integer value",
						new ReferenceInfo(GenmodelModelPackage.Literals.FMEA_TABLE_GENERATION__CARDINALITY)));
			}
		} catch (IllegalArgumentException e) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"The cardinality must be a positive integer value",
					new ReferenceInfo(GenmodelModelPackage.Literals.FMEA_TABLE_GENERATION__CARDINALITY)));
		}
		
		return validationResultMessages;
	}
	
	//
	
	protected Collection<ValidationResultMessage> checkRelativeFilePath(EObject anchor,
			String relativeFilePath, EStructuralFeature reference) {
		File file = ecoreUtil.getFile(anchor.eResource());
		return checkRelativeFilePath(file, relativeFilePath, reference);
	}
	
	protected Collection<ValidationResultMessage> checkRelativeFilePath(File anchor,
			String relativeFilePath, EStructuralFeature reference) {
		return checkRelativeFilePaths(anchor, List.of(relativeFilePath), List.of(reference));
	}
	
	protected Collection<ValidationResultMessage> checkRelativeFilePaths(EObject anchor,
			List<String> relativeFilePaths, List<EStructuralFeature> references) {
		File file = ecoreUtil.getFile(anchor.eResource());
		return checkRelativeFilePaths(file, relativeFilePaths, references);
	}
	
	protected Collection<ValidationResultMessage> checkRelativeFilePaths(File anchor,
			List<String> relativeFilePaths, List<EStructuralFeature> references) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		for (var i = 0; i < relativeFilePaths.size(); i++) {
			String relativeFilePath = relativeFilePaths.get(i);
			if (!fileUtil.isValidRelativeFile(anchor, relativeFilePath)) {
				EStructuralFeature reference = references.get(i);
				validationResultMessages.add(
					new ValidationResultMessage(ValidationResult.ERROR, 
							"This is not a valid relative path: " + relativeFilePath, new ReferenceInfo(reference)));
			}
		}
		
		return validationResultMessages;
	}

}