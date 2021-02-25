package hu.bme.mit.gamma.genmodel.util;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.xtext.EcoreUtil2;
import org.yakindu.base.types.Direction;
import org.yakindu.sct.model.sgraph.Statechart;
import org.yakindu.sct.model.stext.stext.InterfaceScope;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;
import hu.bme.mit.gamma.expression.util.ExpressionType;
import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint;
import hu.bme.mit.gamma.genmodel.model.CodeGeneration;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.Constraint;
import hu.bme.mit.gamma.genmodel.model.Coverage;
import hu.bme.mit.gamma.genmodel.model.EventMapping;
import hu.bme.mit.gamma.genmodel.model.EventPriorityTransformation;
import hu.bme.mit.gamma.genmodel.model.GenModel;
import hu.bme.mit.gamma.genmodel.model.GenmodelModelPackage;
import hu.bme.mit.gamma.genmodel.model.InterfaceMapping;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint;
import hu.bme.mit.gamma.genmodel.model.PhaseStatechartGeneration;
import hu.bme.mit.gamma.genmodel.model.SchedulingConstraint;
import hu.bme.mit.gamma.genmodel.model.StateCoverage;
import hu.bme.mit.gamma.genmodel.model.StatechartCompilation;
import hu.bme.mit.gamma.genmodel.model.Task;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.genmodel.model.TestReplayModelGeneration;
import hu.bme.mit.gamma.genmodel.model.TransitionCoverage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.genmodel.model.XSTSReference;
import hu.bme.mit.gamma.genmodel.model.YakinduCompilation;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class GenmodelValidator extends ExpressionModelValidator {
	
			protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
			protected final FileUtil fileUtil = FileUtil.INSTANCE;
			protected final GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE;
			protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
			
			// Checking tasks, only one parameter is acceptable
			
			
			public Collection<ValidationResultMessage> checkTasks(Task task) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				if (task.getFileName().size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At most one file name can be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.TASK__FILE_NAME, null)));
				}
				if (task.getTargetFolder().size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At most one target folder can be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.TASK__TARGET_FOLDER, null)));
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkTasks(YakinduCompilation yakinduCompilation) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				if (yakinduCompilation.getPackageName().size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At most one package name can be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.YAKINDU_COMPILATION__PACKAGE_NAME, null)));
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkTasks(StatechartCompilation statechartCompilation) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				if (statechartCompilation.getStatechartName().size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At most one statechart name can be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.STATECHART_COMPILATION__STATECHART_NAME, null)));
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkTasks(AnalysisModelTransformation analysisModelTransformation) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				if (analysisModelTransformation.getScheduler().size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At most one scheduler type can be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__SCHEDULER, null)));
				}
				List<AnalysisLanguage> languages = analysisModelTransformation.getLanguages();
				if (languages.size() != languages.stream().collect(Collectors.toSet()).size()) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "A single formal language can be specified only once.",
							new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__LANGUAGES, null)));
				}
				ModelReference modelReference = analysisModelTransformation.getModel();
				if (modelReference instanceof XSTSReference) {
					if (languages.stream().anyMatch(it -> it != AnalysisLanguage.UPPAAL)) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "XSTS models can be transformed only to UPPAAL",
								new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__LANGUAGES, null)));
					}
				}
				if (analysisModelTransformation.getCoverages().stream().filter(it -> it instanceof TransitionCoverage).count() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "A single transition coverage task can be defined.",
							new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__COVERAGES, null)));
				}
				if (analysisModelTransformation.getCoverages().stream().filter(it -> it instanceof StateCoverage).count() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "A single state coverage task can be defined.",
							new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__COVERAGES, null)));
				}
				Constraint constraint = analysisModelTransformation.getConstraint();
				if (constraint != null) {
					if (modelReference instanceof ComponentReference) {
						ComponentReference componentReference = (ComponentReference)modelReference;
						Component component = componentReference.getComponent();
						if (component instanceof AsynchronousComponent && constraint instanceof OrchestratingConstraint) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
									"Asynchronous component constraints must contain either a 'top' keyword or references to the contained instances.",
									new ReferenceInfo(GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__CONSTRAINT, null)));
						}
					}
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkTasks(Verification verification) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				List<AnalysisLanguage> languages = verification.getLanguages();
				if (languages.size() != 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "A single formal language must be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.VERIFICATION__LANGUAGES, null)));
				}
				File resourceFile = ecoreUtil.getFile(verification.eResource());
				List<String> modelFiles = verification.getFileName();
				if (modelFiles.size() != 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "A single model file must be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.TASK__FILE_NAME, null)));
				}
				for (String modelFile : modelFiles) {
					if (!fileUtil.isValidRelativeFile(resourceFile, modelFile)) {
						int index = modelFiles.indexOf(modelFile);
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "This is not a valid relative path to a model file: " + modelFile,
								new ReferenceInfo(GenmodelModelPackage.Literals.TASK__FILE_NAME, index)));
					}
				}
				List<String> queryFiles = verification.getQueryFiles();
				List<PropertyPackage> propertyPackages = verification.getPropertyPackages();
				if (queryFiles.size() + propertyPackages.size() < 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At least one query file must be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.VERIFICATION__QUERY_FILES, null)));
				}
				for (String queryFile : queryFiles) {
					if (!fileUtil.isValidRelativeFile(resourceFile, queryFile)) {
						int index = queryFiles.indexOf(queryFile);
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "This is not a valid relative path to a query file: " + queryFile,
								new ReferenceInfo(GenmodelModelPackage.Literals.VERIFICATION__QUERY_FILES, index)));
					}
				}
				List<String> testFolders = verification.getTestFolder();
				if (testFolders.size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At most one test folder can be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.VERIFICATION__TEST_FOLDER, null)));
				}
				
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkTasks(TestReplayModelGeneration modelGeneration) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				List<String> systemFileNames = modelGeneration.getFileName();
				if (systemFileNames.size() != 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "A single system file name must be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.TASK__FILE_NAME, null)));
				}
				List<String> targetFolders = modelGeneration.getTargetFolder();
				if (targetFolders.size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At most one test folder can be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.TASK__TARGET_FOLDER, null)));
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkTimeSpecification(TimeSpecification timeSpecification) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				if (!typeDeterminator.isInteger(timeSpecification.getValue())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Time values must be of type integer.",
							new ReferenceInfo(InterfaceModelPackage.Literals.TIME_SPECIFICATION__VALUE, null)));
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkConstraint(AsynchronousInstanceConstraint constraint) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				AnalysisModelTransformation analysisModelTransformation = EcoreUtil2.getContainerOfType(constraint, AnalysisModelTransformation.class);
				ModelReference modelReference = analysisModelTransformation.getModel();
				if (modelReference instanceof ComponentReference) {
					ComponentReference componentReference = (ComponentReference)modelReference;
					Component component = componentReference.getComponent();
					if (!hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.isAsynchronous(component)) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
								"Asynchronous component constraints must refer to an asynchronous component.",
								new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__ORCHESTRATING_CONSTRAINT, null)));
						return validationResultMessages;
					}
					SchedulingConstraint scheduling = EcoreUtil2.getContainerOfType(constraint, SchedulingConstraint.class);
					ComponentInstanceReference instance = constraint.getInstance();
					if (instance != null) {
						ComponentInstance lastInstance = instance.getComponentInstanceHierarchy().get(instance.getComponentInstanceHierarchy().size() - 1);
						if (!hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.isAsynchronous(lastInstance)) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
									"Asynchronous component constraints must contain a reference to a contained asynchronous instance.",
									new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE, null)));
						}
					}
					if (component instanceof AsynchronousCompositeComponent) {
						if (instance == null) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
									"Asynchronous component constraints must contain a reference to a contained instance.",
									new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE, null)));
						}
						if (scheduling.getInstanceConstraint().stream().filter(it -> ecoreUtil.helperEquals(it.getInstance(), instance)).count() > 1) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
									"The scheduling constraints for a certain asynchronous component can be defined at most once.",
									new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE, null)));
						}
					}
					if (component instanceof AsynchronousAdapter) {
						if (scheduling.getInstanceConstraint().size() > 1) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Asynchronous adapters can contain at most one constraint.",
									new ReferenceInfo(GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__ORCHESTRATING_CONSTRAINT, null)));
						}
					}
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkMinimumMaximumOrchestrationPeriodValues(OrchestratingConstraint orchestratingConstraint) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				try {
					TimeSpecification minimum = orchestratingConstraint.getMinimumPeriod();
					TimeSpecification maximum = orchestratingConstraint.getMaximumPeriod();
					if (minimum != null) {
						if (maximum != null) {
							int minimumIntegerValue = statechartUtil.evaluateMilliseconds(minimum);
							int maximumIntegerValue = statechartUtil.evaluateMilliseconds(maximum);
							if (minimumIntegerValue < 0) {
								validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Time value must be positive.",
										new ReferenceInfo(GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MINIMUM_PERIOD, null)));
							}
							if (maximumIntegerValue < 0) {
								validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Time value must be positive.",
										new ReferenceInfo(GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MAXIMUM_PERIOD, null)));
							}
							if (maximumIntegerValue < minimumIntegerValue) {
								validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
										"The minimum orchestrating period value must be greater than the maximum orchestrating period value.",
										new ReferenceInfo(GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MINIMUM_PERIOD, null)));
							}
						}
					}
				} catch (IllegalArgumentException e) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Both the minimum and maximum values must be of type integer.",
							new ReferenceInfo(GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MINIMUM_PERIOD, null)));
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkTasks(CodeGeneration codeGeneration) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				if (codeGeneration.getPackageName().size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At most one package name can be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME, null)));
				}
				if (codeGeneration.getLanguage().size() != 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "A single programming language must be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME, null)));
				}
			}
			
			
			public Collection<ValidationResultMessage> checkTasks(TestGeneration testGeneration) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				if (testGeneration.getPackageName().size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "At most one package name can be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME, null)));
				}
				if (testGeneration.getLanguage().size() != 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "A single programming language must be specified.",
							new ReferenceInfo(GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME, null)));
				}
				return validationResultMessages;
			}
			
			// Additional validation rules
			
			
			public Collection<ValidationResultMessage> checkGammaImports(GenModel genmodel) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				Set<Package> packageImports = genmodel.getPackageImports().stream().collect(Collectors.toSet());
				for (CodeGeneration codeGenerationTask : javaUtil.filter(genmodel.getTasks(),CodeGeneration.class)) {
					Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(codeGenerationTask.getComponent());
					packageImports.remove(parentPackage);
				}
				for (AnalysisModelTransformation analysisModelTransformationTask : javaUtil.filter(genmodel.getTasks(), AnalysisModelTransformation.class)) {
					ModelReference modelReference = analysisModelTransformationTask.getModel();
					if (modelReference instanceof ComponentReference) {
						ComponentReference componentReference = (ComponentReference)modelReference;
						Component component = componentReference.getComponent();
						Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(component);
						packageImports.remove(parentPackage);
					}
					for (Coverage coverage : analysisModelTransformationTask.getCoverages()) {
						List<ComponentInstanceReference> allCoverages = new ArrayList<ComponentInstanceReference>();
						allCoverages.addAll(coverage.getInclude());
						allCoverages.addAll(coverage.getExclude());
						for (ComponentInstanceReference instance : allCoverages) {
							Package instanceParentPackage = StatechartModelDerivedFeatures.getContainingPackage(instance);
							packageImports.remove(instanceParentPackage);
						}
					}
				}
				for (StatechartCompilation statechartCompilationTask : javaUtil.filter(genmodel.getTasks(), StatechartCompilation.class)) {
					for (InterfaceMapping interfaceMapping : statechartCompilationTask.getInterfaceMappings()) {
						Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(interfaceMapping.getGammaInterface());
						packageImports.remove(parentPackage);
					}
				}
				for (EventPriorityTransformation eventPriorityTransformationTask : javaUtil.filter(genmodel.getTasks(), EventPriorityTransformation.class)) {
					Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(eventPriorityTransformationTask.getStatechart());
					packageImports.remove(parentPackage);
				}
				for (AdaptiveContractTestGeneration adaptiveContractTestGenerationTask : javaUtil.filter(genmodel.getTasks(), AdaptiveContractTestGeneration.class)) {
					Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(adaptiveContractTestGenerationTask.getStatechartContract());
					packageImports.remove(parentPackage);
				}
				for (PhaseStatechartGeneration phaseStatechartGenerationTask : javaUtil.filter(genmodel.getTasks(), PhaseStatechartGeneration.class)) {
					Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(phaseStatechartGenerationTask.getStatechart());
					packageImports.remove(parentPackage);
				}
				for (Package packageImport : packageImports) {
					int index = genmodel.getPackageImports().indexOf(packageImport);
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, "This Gamma package import is not used.",
							new ReferenceInfo(GenmodelModelPackage.Literals.GEN_MODEL__PACKAGE_IMPORTS, index)));
				}
				return validationResultMessages;
			}

			
			public Collection<ValidationResultMessage> checkYakinduImports(GenModel genmodel) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				Set<Statechart> statechartImports = genmodel.getStatechartImports().stream().collect(Collectors.toSet());
				for (YakinduCompilation statechartCompilationTask : javaUtil.filter(genmodel.getTasks(), YakinduCompilation.class)) {
					statechartImports.remove(statechartCompilationTask.getStatechart()); //remove removeAll
				}
				for (Statechart statechartImport : statechartImports) {
					int index = genmodel.getStatechartImports().indexOf(statechartImport);
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, "This Yakindu import is not used.",
							new ReferenceInfo(GenmodelModelPackage.Literals.GEN_MODEL__STATECHART_IMPORTS, index)));
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkTraceImports(GenModel genmodel) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				Set<ExecutionTrace> traceImports = genmodel.getTraceImports().stream().collect(Collectors.toSet());
				for (TestGeneration testGenerationTask : javaUtil.filter(genmodel.getTasks(), TestGeneration.class)) {
					traceImports.remove(testGenerationTask.getExecutionTrace());
				}
				for (TestReplayModelGeneration testReplayModelGeneration : javaUtil.filter(genmodel.getTasks(), TestReplayModelGeneration.class)) {
					traceImports.remove(testReplayModelGeneration.getExecutionTrace());
				}
				for (ExecutionTrace traceImport : traceImports) {
					int index = genmodel.getTraceImports().indexOf(traceImport);
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, "This execution trace import is not used.",
							new ReferenceInfo(GenmodelModelPackage.Literals.GEN_MODEL__TRACE_IMPORTS, index)));
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkParameters(ComponentReference componentReference) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				Component type = componentReference.getComponent();
				if (componentReference.getArguments().size() != type.getParameterDeclarations().size()) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "The number of arguments is wrong.",
							new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, null)));
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkComponentInstanceArguments(AnalysisModelTransformation analysisModelTransformation) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				try {
					ModelReference modelReference = analysisModelTransformation.getModel();
					if (modelReference instanceof ComponentReference) {
						ComponentReference componentReference = (ComponentReference)modelReference;
						Component type = componentReference.getComponent();
						List<ParameterDeclaration> parameters = type.getParameterDeclarations();
						for (var i = 0; i < parameters.size(); i++) {
							ParameterDeclaration parameter = parameters.get(i);
							Expression argument = modelReference.getArguments().get(i);
							Type declarationType = parameter.getType();
							ExpressionType argumentType = typeDeterminator.getType(argument);
							if (!typeDeterminator.equals(declarationType, argumentType)) {
								validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
										"The types of the declaration and the right hand side expression are not the same: " +
										typeDeterminator.transform(declarationType).toString().toLowerCase() + " and " +
										argumentType.toString().toLowerCase() + ".", new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, i)));
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
				Set<InterfaceScope> interfaces = new HashSet<InterfaceScope>();//(Set<InterfaceScope>)statechartCompilation.getStatechart().getScopes().stream().filter(it -> it instanceof InterfaceScope).collect(Collectors.toSet());
				for (InterfaceScope interfaceScope: statechartCompilation.getStatechart().getScopes()) {
					
				}
				Set<InterfaceScope> mappedInterfaces = new HashSet<InterfaceScope>();//statechartCompilation.getInterfaceMappings().stream().map(it -> it.get);///.map(it -> it.getYakinduInterface()).collect(Collectors.toSet());
				for (InterfaceMapping interfaceMapping: statechartCompilation.getInterfaceMappings()) {
					mappedInterfaces.add(interfaceMapping.getYakinduInterface());
				}
				interfaces.removeAll(mappedInterfaces);
				if (!interfaces.isEmpty()) {
					Set<InterfaceScope> interfacesWithEvents = interfaces.stream().filter(it -> !it.getEvents().isEmpty()).collect(Collectors.toSet());
					Set<InterfaceScope> interfacesWithoutEvents = interfaces.stream().filter(it -> it.getEvents().isEmpty()).collect(Collectors.toSet());
					if (!interfacesWithEvents.isEmpty()) {
						for (InterfaceScope interfacesWithEventsMap : interfacesWithEvents) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
									"The following interfaces with events are not mapped: " + interfacesWithEventsMap.getName() + ".",
									new ReferenceInfo(GenmodelModelPackage.Literals.YAKINDU_COMPILATION__STATECHART, null)));
						}
					}
					if (!interfacesWithoutEvents.isEmpty()) {
						for (InterfaceScope interfacesWithoutEventsMap : interfacesWithoutEvents) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO, 
									"The following interfaces without events are not mapped: " + interfacesWithoutEventsMap.getName() + ".",
									new ReferenceInfo(GenmodelModelPackage.Literals.YAKINDU_COMPILATION__STATECHART, null)));
						}
					}
				}
				return validationResultMessages;
			}
			
			
			public Collection<ValidationResultMessage> checkInterfaceConformance(InterfaceMapping mapping) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				if (!(checkConformance(mapping))) {
					switch (mapping.getRealizationMode()) {
						case PROVIDED:
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
									"In case of provided realization mode number of in/out events must equal to the number of in/out events in the Gamma interface and vice versa.",
									new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE, null)));
						case REQUIRED:
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
									"In case of required realization mode number of in/out events must equal to the number of out/in events in the Gamma interface and vice versa",
									new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE, null)));
						default:
							throw new IllegalArgumentException("Such interface realization mode is not supported: " + mapping.getRealizationMode());
					}
				}
				return validationResultMessages;
			}
			
			/** It checks the events of the parent interfaces as well. */
			private boolean checkConformance(InterfaceMapping mapping) {
				int yOut = mapping.getYakinduInterface().getEvents().stream().filter(it.direction == Direction.OUT).size
				int yIn = mapping.getYakinduInterface().getEvents().filter[it.direction == Direction.IN].size
				int gOut = mapping.gammaInterface.allEventDeclarations.filter[it.direction != EventDirection.IN].size // Regarding in-out events
				int gIn = mapping.gammaInterface.allEventDeclarations.filter[it.direction != EventDirection.OUT].size // Regarding in-out events
				RealizationMode realMode = mapping.realizationMode
				return (realMode == RealizationMode.PROVIDED && yOut == gOut && yIn == gIn) ||
					(realMode == RealizationMode.REQUIRED && yOut == gIn && yIn == gOut)
			}
			
			
			public Collection<ValidationResultMessage> checkInterfaceMappingWithoutEventMapping(InterfaceMapping mapping) {
				Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
				// 0 event mapping is acceptable if the two interfaces are equal
				RealizationMode realizationMode = mapping.getRealizationMode();
				if (mapping.getEventMappings().size() == 0) {
					// If the interface has in-out events, 0 event mapping is surely not acceptable
					if (!mapping.getGammaInterface().getEvents().stream().filter[it.direction == EventDirection.INOUT].empty) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "The Gamma interface has in-out events, thus an automatic mapping is not possible",
								new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE, null)));
						return validationResultMessages;
					}
					for (Event yakinduEvent : mapping.getYakinduInterface().getEvents()) {
						List<Event> gammaEvents = new ArrayList<Event>();//mapping.getGammaInterface().getEvents().map[it.event].filter[it.name.equals(yakinduEvent.name)]
						for (EventDeclaration events: mapping.getGammaInterface().getEvents()) {
							if ((events.getEvent().getName()).equals(yakinduEvent.getName())) {
								gammaEvents.add(events.getEvent());
							}
						}
						Event gammaEvent = gammaEvents.get(0);
						if (!(gammaEvents.size() == 1 && checkParameters(yakinduEvent, gammaEvent)
							&& realizationMode.areWellDirected(yakinduEvent, (EventDeclaration)gammaEvent.eContainer()))) {
							String typeName = if (yakinduEvent.type !== null) {" : " + yakinduEvent.getType().getName()} else {""};
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
									"Interface mapping without event mapping is only possible if the names and types of the events of the interfaces are equal. " 
									+ yakinduEvent.getName() + typeName + " has no equivalent event in the Gamma interface.",
									new ReferenceInfo(GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE, null)));
						}			
					}
			
				return validationResultMessages;
		}
			
			/**
			 * Checks whether the event directions conform to the realization mode.
			 */
			private boolean areWellDirected(RealizationMode interfaceType, Event yEvent, EventDeclaration gEvent) {
				if (interfaceType == RealizationMode.PROVIDED) {
					return (yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.IN) ||
					(yEvent.direction == Direction.IN && gEvent.direction != EventDirection.OUT)
				}
				else if (interfaceType == RealizationMode.REQUIRED) {
					return (yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.OUT) ||
					(yEvent.direction == Direction.IN && gEvent.direction != EventDirection.IN)
				}
				else {
					throw new IllegalArgumentException("No such direction: " + interfaceType)
				}
			}
			
			
			def checkMappingCount(InterfaceMapping mapping) {
				// Check only if the interface mapping is not trivial (size != 0)
				if (mapping.eventMappings.size != 0 && mapping.yakinduInterface.events.size != mapping.eventMappings.size) {
					error("Each Yakindu event has to be mapped exactly once.", GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
				}
			}
			
			
			def checkYakinduInterfaceUniqueness(InterfaceMapping mapping) {
				val interfaces = new HashSet<InterfaceScope>
				val statechartCompilation = mapping.eContainer as StatechartCompilation
				for (interface : statechartCompilation.interfaceMappings.map[it.yakinduInterface]) {
					if (interfaces.contains(interface)){
						error("Each Yakindu event has to be mapped exactly once.", GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
					}
					else {
						interfaces.add(interface)
					}			
				}
			}
			
			
			def checkEventMappingCount(InterfaceMapping mapping) {
				val mappedYakinduEvents = new HashSet<Event>
				val mappedGammaEvents = new HashMap<hu.bme.mit.gamma.statechart.interface_.Event, Set<Event>>
				for (eventMapping : mapping.eventMappings) {
					val yakinduEvent = eventMapping.yakinduEvent
					val gammaEvent = eventMapping.gammaEvent
					// Yakindu validation
					if (mappedYakinduEvents.contains(yakinduEvent)) {
						error("This event is mapped multiple times: " + yakinduEvent.name + ".", GenmodelModelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)
					}
					else {
						mappedYakinduEvents += yakinduEvent			
					}
					// Gamma validation
					if (mappedGammaEvents.containsKey(gammaEvent)) {
						val gammaEventDeclaration = gammaEvent.eContainer as EventDeclaration
						if (gammaEventDeclaration.direction == EventDirection.INOUT) {
							val yakinduEventSet = mappedGammaEvents.get(gammaEvent)
							yakinduEventSet += yakinduEvent
							// A single in and a single out event has to be now in yakinduEventSet
							if (!(yakinduEventSet.filter[it.direction == Direction.IN].size == 1 &&
									yakinduEventSet.filter[it.direction == Direction.OUT].size == 1)) {
								error("A single in and a single out event has to be mapped onto this Gamma event: " + gammaEvent.name + ".",
									GenmodelModelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)
							}
						}
						else {
							// Not an in-out event
							error("Multiple Yakindu events are mapped to this Gamma event: " + gammaEvent.name + ".", GenmodelModelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)
						}
					}
					else {
						// First entry
						mappedGammaEvents.put(gammaEvent, newHashSet(yakinduEvent))			
					}
				}		
			}
			
			
			def checkEventConformance(EventMapping mapping) {		
				val ifReal = mapping.eContainer as InterfaceMapping
				if (!(mapping.checkConformance)) {
					switch (ifReal.realizationMode) {
						case RealizationMode.PROVIDED:
							error("In case of provided realization mode Yakindu events must have the same direction and parameter as Gamma events.", GenmodelModelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT)
						case RealizationMode.REQUIRED:
							error("In case of required realization mode Yakindu events must have the opposite direction and same parameter of Gamma events.", GenmodelModelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT)		
					default:
						throw new IllegalArgumentException("Such interface realization mode is not supported: " + ifReal.realizationMode)				
					}
				}
			}
			
			
			def checkTraces(TestGeneration testGeneration) {
				val genmodel = testGeneration.eContainer as GenModel
				val usedInterfaces = testGeneration.executionTrace.component.ports
										.map[it.interfaceRealization.interface]
										.map[it.name].toSet
				val transformedInterfaces = genmodel.tasks.filter(InterfaceCompilation)
										.map[it.statechart.scopes].flatten
										.filter(InterfaceScope).map[it.name].toSet
				usedInterfaces.retainAll(transformedInterfaces)
				if (!usedInterfaces.isEmpty) {
					warning("This trace depends on interfaces " + usedInterfaces + ", which seem to be about to be recompiled. " + 
						"The recompilation of interfaces just before the generation of tests might cause a break in the generated test suite.",
						 GenmodelModelPackage.Literals.TEST_GENERATION__EXECUTION_TRACE)
				}
			}
			
			private def boolean checkConformance(EventMapping mapping) {
				val yEvent = mapping.yakinduEvent
				val gEvent = mapping.gammaEvent.eContainer as EventDeclaration
				val ifReal = mapping.eContainer as InterfaceMapping
				val realMode = ifReal.realizationMode
				return checkEventConformance(yEvent, gEvent, realMode)
			}
			
			private def checkEventConformance(Event yEvent, EventDeclaration gEvent, RealizationMode realMode) {
				switch (realMode) {
					 // Regarding in-out events
					case RealizationMode.PROVIDED:
						return yEvent.direction == Direction.IN && gEvent.direction != EventDirection.OUT && checkParameters(yEvent, gEvent.event) ||
							yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.IN && checkParameters(yEvent, gEvent.event)
					case RealizationMode.REQUIRED:
						return yEvent.direction == Direction.IN && gEvent.direction != EventDirection.IN && checkParameters(yEvent, gEvent.event) ||
							yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.OUT && checkParameters(yEvent, gEvent.event)
					default:
						throw new IllegalArgumentException("Such interface realization mode is not supported: " + realMode)				
				}
			}
			
			private boolean checkParameters(Event yEvent, hu.bme.mit.gamma.statechart.interface_.Event gEvent) {
				// event.type is null not void if no explicit type is declared
				if (yEvent.type === null && gEvent.parameterDeclarations.empty) {
					return true
				}
				if (!gEvent.parameterDeclarations.empty) {
					switch (gEvent.parameterDeclarations.head.type) {
						IntegerTypeDefinition: {
							if (yEvent.type === null) {
								return false
							}
							return yEvent.type.name.equals("integer") ||
								yEvent.type.name.equals("string") // strings are mapped to integers					
						}
						BooleanTypeDefinition: {
							if (yEvent.type === null) {
								return false
							}
							return yEvent.type.name.equals("boolean")					
						}
						DecimalTypeDefinition: {
							if (yEvent.type === null) {
								return false
							}
							return yEvent.type.name.equals("real")					
						}
						default:
							throw new IllegalArgumentException("Not known type: " + gEvent.parameterDeclarations.head.type)
					}		
				}
				return false
			}
			
			
			def checkComponentInstanceReferences(ComponentInstanceReference reference) {
				val instances = reference.getComponentInstanceHierarchy
				if (instances.empty) {
					return
				}
				for (var i = 0; i < instances.size - 1; i++) {
					val instance = instances.get(i)
					val nextInstance = instances.get(i + 1)
					val type = instance.derivedType
					val containedInstances = type.eContents
					if (!containedInstances.contains(nextInstance)) {
						error(instance.name + " does not contain component instance " + nextInstance.name,
							CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE_HIERARCHY, i)
					}
				}
				val model = ecoreUtil.getContainerOfType(reference, AnalysisModelTransformation)
				if (model !== null) {
					val modelReference = model.model
					if (modelReference instanceof ComponentReference) {
						val component = modelReference.component
						val containedComponents = component.eContents.filter(ComponentInstance).toList
						val firstInstance = instances.head
						if (!containedComponents.contains(firstInstance)) {
							error("The first component instance must be the component of " + component.name,
								CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE_HIERARCHY, 0)
						}
					}
				}
			}
}
