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
package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map.Entry;
import java.util.Optional;
import java.util.Set;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;

import com.google.common.collect.Maps;

import hu.bme.mit.gamma.composition.xsts.uppaal.transformation.Gamma2XstsUppaalTransformerSerializer;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.Coverage;
import hu.bme.mit.gamma.genmodel.model.DataflowCoverage;
import hu.bme.mit.gamma.genmodel.model.DeadlockCoverage;
import hu.bme.mit.gamma.genmodel.model.EventCoverage;
import hu.bme.mit.gamma.genmodel.model.InteractionCoverage;
import hu.bme.mit.gamma.genmodel.model.InteractionDataflowCoverage;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.NonDeterministicTransitionCoverage;
import hu.bme.mit.gamma.genmodel.model.OutEventCoverage;
import hu.bme.mit.gamma.genmodel.model.StateCoverage;
import hu.bme.mit.gamma.genmodel.model.TransitionCoverage;
import hu.bme.mit.gamma.genmodel.model.TransitionPairCoverage;
import hu.bme.mit.gamma.genmodel.model.TrapStateCoverage;
import hu.bme.mit.gamma.genmodel.model.UnstableStateCoverage;
import hu.bme.mit.gamma.genmodel.model.XstsReference;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging;
import hu.bme.mit.gamma.ocra.transformation.api.Gamma2OcraTransformerSerializer;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.OcraPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.PromelaPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.PropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.ThetaPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.UppaalPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.XstsUppaalPropertySerializer;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.transformation.util.annotations.AnnotatablePreprocessableElements;
import hu.bme.mit.gamma.transformation.util.annotations.ComponentInstancePortReferences;
import hu.bme.mit.gamma.transformation.util.annotations.ComponentInstancePortStateTransitionReferences;
import hu.bme.mit.gamma.transformation.util.annotations.ComponentInstanceReferences;
import hu.bme.mit.gamma.transformation.util.annotations.ComponentInstanceVariableReferences;
import hu.bme.mit.gamma.transformation.util.annotations.ComponentPortReferences;
import hu.bme.mit.gamma.transformation.util.annotations.ComponentStateReferences;
import hu.bme.mit.gamma.transformation.util.annotations.ComponentTransitionReferences;
import hu.bme.mit.gamma.transformation.util.annotations.ComponentVariableReferences;
import hu.bme.mit.gamma.transformation.util.annotations.DataflowCoverageCriterion;
import hu.bme.mit.gamma.transformation.util.annotations.InteractionCoverageCriterion;
import hu.bme.mit.gamma.transformation.util.preprocessor.AnalysisModelPreprocessor;
import hu.bme.mit.gamma.uppaal.composition.transformation.AsynchronousInstanceConstraint;
import hu.bme.mit.gamma.uppaal.composition.transformation.AsynchronousSchedulerTemplateCreator.Scheduler;
import hu.bme.mit.gamma.uppaal.composition.transformation.Constraint;
import hu.bme.mit.gamma.uppaal.composition.transformation.OrchestratingConstraint;
import hu.bme.mit.gamma.uppaal.composition.transformation.SchedulingConstraint;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.Gamma2UppaalTransformerSerializer;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.UppaalModelPreprocessor;
import hu.bme.mit.gamma.xsts.iml.transformation.Gamma2XstsImlTransformerSerializer;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.nuxmv.transformation.Gamma2XstsNuxmvTransformerSerializer;
import hu.bme.mit.gamma.xsts.promela.transformation.Gamma2XstsPromelaTransformerSerializer;
import hu.bme.mit.gamma.xsts.transformation.InitialStateSetting;
import hu.bme.mit.gamma.xsts.transformation.api.Gamma2XstsTransformerSerializer;
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer;
import hu.bme.mit.gamma.xsts.uppaal.transformation.api.Xsts2UppaalTransformerSerializer;

public class AnalysisModelTransformationHandler extends TaskHandler {
	
	public AnalysisModelTransformationHandler(IFile file) {
		super(file);
	}
	
	public void execute(AnalysisModelTransformation transformation) throws IOException {
		// Setting target folder
		setTargetFolder(transformation);
		//
		ModelReference modelReference = transformation.getModel();
		setAnalysisModelTransformation(transformation);
		Set<AnalysisLanguage> languagesSet = new LinkedHashSet<AnalysisLanguage>(
				transformation.getLanguages()); // To retain order
		for (AnalysisLanguage analysisLanguage : languagesSet) {
			AnalysisModelTransformer transformer;
			switch (analysisLanguage) {
				case UPPAAL:
					if (modelReference instanceof ComponentReference) {
						transformer = new Gamma2UppaalTransformer();
					}
					else if (modelReference instanceof XstsReference) {
						transformer = new Xsts2UppaalTransformer();
					}
					else {
						throw new IllegalArgumentException("Not known model reference: " + modelReference);
					}
					break;
				case THETA:
					transformer = new Gamma2XstsTransformer();
					break;
				case XSTS_UPPAAL:
					transformer = new Gamma2XstsUppaalTransformer();
					break;
				case PROMELA:
					transformer = new Gamma2XstsPromelaTransformer();
					break;
				case NUXMV:
					transformer = new Gamma2XstsNuxmvTransformer();
					break;
				case OCRA: // Keep in mind that OCRA is not a model checker though
					transformer = new Gamma2OcraTransformer();
					break;
				case IML:
					transformer = new Gamma2XstsImlTransformer();
					break;
				default:
					throw new IllegalArgumentException(analysisLanguage + " is not supported");
			}
			transformer.execute(transformation);
		}
	}
	
	private void setAnalysisModelTransformation(AnalysisModelTransformation analysisModelTransformation) {
		List<String> fileNames = analysisModelTransformation.getFileName();
		checkArgument(fileNames.size() <= 1);
		if (fileNames.isEmpty()) {
			EObject sourceModel = GenmodelDerivedFeatures.getModel(analysisModelTransformation);
			String fileName = getNameWithoutExtension(
					getContainingFileName(sourceModel));
			fileNames.add(fileName);
		}
		List<hu.bme.mit.gamma.genmodel.model.Scheduler> schedulers = analysisModelTransformation.getScheduler();
		checkArgument(schedulers.size() <= 1);
		if (schedulers.isEmpty()) {
			schedulers.add(hu.bme.mit.gamma.genmodel.model.Scheduler.RANDOM);
		}
	}
	
	public String getFileName(String plainFileName, AnalysisLanguage analysisLanguage) {
		switch (analysisLanguage) {
		case THETA:
			return fileNamer.getXtextXStsFileName(plainFileName);
		case UPPAAL:
			return fileNamer.getXmlUppaalFileName(plainFileName);
		case XSTS_UPPAAL:
			return fileNamer.getXmlUppaalFileName(plainFileName);
		case PROMELA:
			return fileNamer.getPmlPromelaFileName(plainFileName);
		case NUXMV:
			return fileNamer.getSmvNuxmvFileName(plainFileName);
		case IML:
			return fileNamer.getImlImandraFileName(plainFileName);
		default:
			throw new IllegalArgumentException("Not known language " + analysisLanguage);
		}
	}
	
	abstract class AnalysisModelTransformer {
		
		protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
		
		public abstract void execute(AnalysisModelTransformation transformation) throws IOException;

		protected void serializeProperties(String fileName) throws IOException {
			try {
				File propertyFile = new File(targetFolderUri + File.separator +
					fileNamer.getHiddenEmfPropertyFileName(fileName));
				PropertyPackage propertyPackage = (PropertyPackage) ecoreUtil.normalLoad(propertyFile);
				// ! The object has to be removed from the resource if we want to serialize it
				ecoreUtil.deleteResource(propertyPackage);
				serializeProperties(propertyPackage, fileName);
			} catch (Exception e) {
				// Property was not serialized
			}
		}
		
		protected void serializeProperties(PropertyPackage propertyPackage, String fileName)
				throws IOException {
			if (propertyPackage != null) {
				serializer.saveModel(propertyPackage, targetFolderUri, fileNamer.getHiddenPropertyFileName(fileName));
				serializeStringProperties(propertyPackage, fileName);
			}
		}

		protected void serializeStringProperties(PropertyPackage propertyPackage, String fileName) {
			if (propertyPackage != null) {
				PropertySerializer propertySerializer = getPropertySerializer();
				String serializedFormulas = propertySerializer.serializeCommentableStateFormulas(propertyPackage.getFormulas());
				fileUtil.saveString(targetFolderUri + File.separator +
						fileName + "." + getQueryFileExtension(), serializedFormulas);
			}
		}
		
		protected abstract PropertySerializer getPropertySerializer();
		
		protected abstract String getQueryFileExtension();
		
		protected ComponentInstanceReferences getCoverageInstances(
				Collection<Coverage> coverages, Class<? extends Coverage> clazz) {
			Optional<Coverage> coverage = coverages.stream().filter(it -> clazz.isInstance(it)).findFirst();
			if (coverage.isEmpty()) {
				return null;
			}
			Coverage notNullCoverage = coverage.get();
			return new ComponentInstanceReferences(notNullCoverage.getInclude(),
					notNullCoverage.getExclude());
		}
		
		protected ComponentInstancePortReferences getCoveragePorts(
				Collection<Coverage> coverages, Class<? extends EventCoverage> clazz) {
			Optional<Coverage> coverage = coverages.stream().filter(it -> clazz.isInstance(it)).findFirst();
			if (coverage.isEmpty()) {
				return null;
			}
			EventCoverage notNullCoverage = (EventCoverage) coverage.get();
			return new ComponentInstancePortReferences(
				new ComponentInstanceReferences(notNullCoverage.getInclude(),
					notNullCoverage.getExclude()),
				new ComponentPortReferences(notNullCoverage.getPortInclude(),
					notNullCoverage.getPortExclude()));
		}
		
		protected ComponentInstancePortStateTransitionReferences getCoverageInteractions(
				Collection<Coverage> coverages, Class<? extends InteractionCoverage> clazz) {
			Optional<Coverage> optionalInteractionCoverage = coverages.stream()
					.filter(it -> clazz.isInstance(it)).findFirst();
			if (optionalInteractionCoverage.isEmpty()) {
				return null;
			}
			InteractionCoverage coverage = (InteractionCoverage) optionalInteractionCoverage.get();
			return new ComponentInstancePortStateTransitionReferences(
				new ComponentInstanceReferences(coverage.getInclude(),
						coverage.getExclude()),
				new ComponentPortReferences(coverage.getPortInclude(),
						coverage.getPortExclude()),
				new ComponentStateReferences(coverage.getStateInclude(),
						coverage.getStateExclude()),
				new ComponentTransitionReferences(coverage.getTransitionInclude(),
						coverage.getTransitionExclude())
			);
		}
		
		protected Entry<InteractionCoverageCriterion, InteractionCoverageCriterion> getInteractionCoverageCriteria(
				Collection<Coverage> coverages) {
			Optional<Coverage> optionalInteractionCoverage = coverages.stream()
					.filter(it -> it instanceof InteractionCoverage).findFirst();
			if (optionalInteractionCoverage.isEmpty()) {
				return Maps.immutableEntry(InteractionCoverageCriterion.EVERY_INTERACTION, 
					InteractionCoverageCriterion.EVERY_INTERACTION);
			}
			InteractionCoverage coverage = (InteractionCoverage) optionalInteractionCoverage.get();
			return Maps.immutableEntry(
					transformCoverageCriterion(coverage.getSenderCoverageCriterion()), 
					transformCoverageCriterion(coverage.getReceiverCoverageCriterion()));
		}
		
		protected ComponentInstanceVariableReferences getDataflowCoverageVariables(
				Collection<Coverage> coverages, Class<? extends DataflowCoverage> clazz) {
			Optional<Coverage> optionalCoverage = coverages.stream().filter(
					it -> clazz.isInstance(it)).findFirst();
			if (optionalCoverage.isEmpty()) {
				return null;
			}
			DataflowCoverage coverage = (DataflowCoverage) optionalCoverage.get();
			return new ComponentInstanceVariableReferences(
				new ComponentInstanceReferences(coverage.getInclude(), coverage.getExclude()),
				new ComponentVariableReferences(coverage.getVariableInclude(), coverage.getVariableExclude()));
		}
		
		protected DataflowCoverageCriterion getDataflowCoverageCriterion(
				Collection<? extends Coverage> coverages) {
			Optional<?> coverage = coverages.stream().filter(it -> it instanceof DataflowCoverage).findFirst();
			if (coverage.isEmpty()) {
				return null;
			}
			DataflowCoverage notNullCoverage = (DataflowCoverage) coverage.get();
			return transformCoverageCriterion(notNullCoverage.getDataflowCoverageCriterion());
		}
		
		protected DataflowCoverageCriterion getInteractionDataflowCoverageCriterion(
				Collection<? extends Coverage> coverages) {
			Optional<?> coverage = coverages.stream().filter(it -> it instanceof InteractionDataflowCoverage).findFirst();
			if (coverage.isEmpty()) {
				return null;
			}
			InteractionDataflowCoverage notNullCoverage = (InteractionDataflowCoverage) coverage.get();
			return transformCoverageCriterion(notNullCoverage.getInteractionDataflowCoverageCriterion());
		}
				
		protected Entry<Integer, Integer> evaluateConstraint(hu.bme.mit.gamma.genmodel.model.Constraint constraint) {
			if (constraint == null) {
				return null;
			}
			
			hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint orchestratingConstraint = null;
			if (constraint instanceof hu.bme.mit.gamma.genmodel.model.SchedulingConstraint schedulingConstraint) {
				List<hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint> instanceConstraints =
						schedulingConstraint.getInstanceConstraint();
				if (instanceConstraints.size() == 1) {
					hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint topConstraint =
							instanceConstraints.get(0);
					orchestratingConstraint = topConstraint.getOrchestratingConstraint();
				}
			}
			else if (constraint instanceof hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint aConstraint) {
				orchestratingConstraint = aConstraint;
			}
			
			if (orchestratingConstraint != null) {
				TimeSpecification minimumPeriod = orchestratingConstraint.getMinimumPeriod();
				TimeSpecification maximumPeriod = orchestratingConstraint.getMaximumPeriod();
				int min = statechartUtil.evaluateMilliseconds(minimumPeriod);
				int max = statechartUtil.evaluateMilliseconds(maximumPeriod);
				return new SimpleEntry<Integer, Integer>(min, max);
			}
			
			throw new IllegalArgumentException("Not known constraint: " + constraint);
		}
		
		protected InteractionCoverageCriterion transformCoverageCriterion(
				hu.bme.mit.gamma.genmodel.model.InteractionCoverageCriterion criterion) {
			switch (criterion) {
				case EVERY_INTERACTION:
					return InteractionCoverageCriterion.EVERY_INTERACTION;
				case STATES_AND_EVENTS:
					return InteractionCoverageCriterion.STATES_AND_EVENTS;
				case EVENTS:
					return InteractionCoverageCriterion.EVENTS;
				default:
					throw new IllegalArgumentException("Not known criterion: " + criterion);
			}
		}
		
		protected DataflowCoverageCriterion transformCoverageCriterion(
				hu.bme.mit.gamma.genmodel.model.DataflowCoverageCriterion criterion) {
			switch (criterion) {
				case ALL_DEF:
					return DataflowCoverageCriterion.ALL_DEF;
				case ALL_PUSE:
					return DataflowCoverageCriterion.ALL_P_USE;
				case ALL_CUSE:
					return DataflowCoverageCriterion.ALL_C_USE;
				case ALL_USE:
					return DataflowCoverageCriterion.ALL_USE;
				default:
					throw new IllegalArgumentException("Not known criterion: " + criterion);
			}
		}
		
		protected InitialStateSetting transformInitialStateSetting(
				hu.bme.mit.gamma.genmodel.model.InitialStateSetting initialStateSetting) {
			switch (initialStateSetting) {
				case EXECUTE_ENTRY_ACTIONS:
					return InitialStateSetting.EXECUTE_ENTRY_ACTIONS;
				case SKIP_ENTRY_ACTIONS:
					return InitialStateSetting.SKIP_ENTRY_ACTIONS;
				default:
					throw new IllegalArgumentException("Not known criterion: " + initialStateSetting);
			}
		}
		
	}
	
	class Gamma2UppaalTransformer extends AnalysisModelTransformer {
		
		protected final UppaalModelPreprocessor preprocessor = UppaalModelPreprocessor.INSTANCE;
		
		public void execute(AnalysisModelTransformation transformation) throws IOException {
			logger.info("Starting UPPAAL transformation");
			String fileName = transformation.getFileName().get(0);
			// Unfolding the given system
			ComponentReference reference = (ComponentReference) transformation.getModel();
			Component component = reference.getComponent();
			// Coverages
			List<Coverage> coverages = transformation.getCoverages();
			
			ComponentInstanceReferences testedComponentsForStates = getCoverageInstances(
					coverages, StateCoverage.class);
			ComponentInstanceReferences testedComponentsForUnstableStates = getCoverageInstances(
					coverages, UnstableStateCoverage.class);
			ComponentInstanceReferences testedComponentsForTrapStates = getCoverageInstances(
					coverages, TrapStateCoverage.class);
			ComponentInstanceReferences testedComponentsForDeadlock = getCoverageInstances(
					coverages, DeadlockCoverage.class);
			ComponentInstanceReferences testedComponentsForNondeterministicTransitions = getCoverageInstances(
					coverages, NonDeterministicTransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitions = getCoverageInstances(
					coverages, TransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitionPairs = getCoverageInstances(
					coverages, TransitionPairCoverage.class);
			ComponentInstancePortReferences testedComponentsForOutEvents = getCoveragePorts(
					coverages, OutEventCoverage.class);
			ComponentInstancePortStateTransitionReferences testedInteractions = getCoverageInteractions(
					coverages, InteractionCoverage.class);
			Entry<InteractionCoverageCriterion, InteractionCoverageCriterion> criterion = getInteractionCoverageCriteria(coverages);
			InteractionCoverageCriterion senderCoverageCriterion = criterion.getKey();
			InteractionCoverageCriterion receiverCoverageCriterion = criterion.getValue();
			ComponentInstanceVariableReferences dataflowTestedVariables = getDataflowCoverageVariables(
					coverages, DataflowCoverage.class);
			DataflowCoverageCriterion dataflowCoverageCriterion = getDataflowCoverageCriterion(coverages);
			ComponentInstancePortReferences testedComponentsForInteractionDataflow = getCoveragePorts(
					coverages, InteractionDataflowCoverage.class);
			DataflowCoverageCriterion interactionDataflowCoverageCriterion =
				getInteractionDataflowCoverageCriterion(coverages);
			
			Constraint constraint = transformSchedulingConstraint(transformation.getConstraint());
			Scheduler scheduler = getGammaScheduler(transformation.getScheduler().get(0));
			Gamma2UppaalTransformerSerializer transformer = new Gamma2UppaalTransformerSerializer(
					component, reference.getArguments(),
					targetFolderUri, fileName, constraint, scheduler,
					transformation.isOptimize(), transformation.getPropertyPackage(),
					new AnnotatablePreprocessableElements(
						testedComponentsForStates,
						testedComponentsForUnstableStates,
						testedComponentsForTrapStates,
						testedComponentsForDeadlock,
						testedComponentsForNondeterministicTransitions,
						testedComponentsForTransitions,
						testedComponentsForTransitionPairs,
						testedComponentsForOutEvents,
						testedInteractions, senderCoverageCriterion, receiverCoverageCriterion,
						dataflowTestedVariables, dataflowCoverageCriterion,
						testedComponentsForInteractionDataflow, interactionDataflowCoverageCriterion
					)
			);
			transformer.execute();
			// Property serialization
			serializeProperties(fileName);
			logger.info("The UPPAAL transformation has been finished");
		}
		
		private Constraint transformSchedulingConstraint(hu.bme.mit.gamma.genmodel.model.Constraint constraint) {
			if (constraint == null) {
				return null;
			}
			if (constraint instanceof hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint orchestratingConstraint) {
				return new OrchestratingConstraint(ecoreUtil.clone(orchestratingConstraint.getMinimumPeriod()),
					ecoreUtil.clone(orchestratingConstraint.getMaximumPeriod())); // Cloning to prevent cross-references
			}
			if (constraint instanceof hu.bme.mit.gamma.genmodel.model.SchedulingConstraint schedulingConstraint) {
				SchedulingConstraint gammaSchedulingConstraint = new SchedulingConstraint();
				for (var instanceConstraint : schedulingConstraint.getInstanceConstraint()) {
					gammaSchedulingConstraint.getInstanceConstraints().add(
							transformAsynchronousInstanceConstraint(instanceConstraint));
				}
				return gammaSchedulingConstraint;
			}
			throw new IllegalArgumentException("Not known constraint: " + constraint);
		}
		
		private AsynchronousInstanceConstraint transformAsynchronousInstanceConstraint(
				hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint asynchronousInstanceConstraint) {
			ComponentInstanceReferenceExpression reference = asynchronousInstanceConstraint.getInstance();
				return new AsynchronousInstanceConstraint(reference /* null in the case of AA */,
					(OrchestratingConstraint) transformSchedulingConstraint(asynchronousInstanceConstraint.getOrchestratingConstraint()));
		}
		
		private Scheduler getGammaScheduler(hu.bme.mit.gamma.genmodel.model.Scheduler scheduler) {
			switch (scheduler) {
			case FAIR:
				return Scheduler.FAIR;
			default:
				return Scheduler.RANDOM;
			}
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return UppaalPropertySerializer.INSTANCE;
		}

		@Override
		protected String getQueryFileExtension() {
			return GammaFileNamer.UPPAAL_QUERY_EXTENSION;
		}
		
	}
	
	class Gamma2XstsTransformer extends AnalysisModelTransformer {
		
		protected final AnalysisModelPreprocessor modelPreprocessor = AnalysisModelPreprocessor.INSTANCE;
		protected final ActionSerializer actionSerializer = ActionSerializer.INSTANCE;
		
		public void execute(AnalysisModelTransformation transformation) throws IOException {
			logger.info("Starting XSTS transformation");
			ComponentReference reference = (ComponentReference) transformation.getModel();
			Component component = reference.getComponent();
			Entry<Integer, Integer> schedulingConstraint = evaluateConstraint(transformation.getConstraint());
			Integer minSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getKey() : null;
			Integer maxSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getValue() : null;
			
			String fileName = transformation.getFileName().get(0);
			// Coverages
			List<Coverage> coverages = transformation.getCoverages();
			
			ComponentInstanceReferences testedComponentsForStates = getCoverageInstances(
					coverages, StateCoverage.class);
			ComponentInstanceReferences testedComponentsForUnstableStates = getCoverageInstances(
					coverages, UnstableStateCoverage.class);
			ComponentInstanceReferences testedComponentsForTrapStates = getCoverageInstances(
					coverages, TrapStateCoverage.class);
			ComponentInstanceReferences testedComponentsForDeadlock = getCoverageInstances(
					coverages, DeadlockCoverage.class);
			ComponentInstanceReferences testedComponentsForNondeterministicTransitions = getCoverageInstances(
					coverages, NonDeterministicTransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitions = getCoverageInstances(
					coverages, TransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitionPairs = getCoverageInstances(
					coverages, TransitionPairCoverage.class);
			ComponentInstancePortReferences testedComponentsForOutEvents = getCoveragePorts(
					coverages, OutEventCoverage.class);
			ComponentInstancePortStateTransitionReferences testedInteractions = getCoverageInteractions(
					coverages, InteractionCoverage.class);
			Entry<InteractionCoverageCriterion, InteractionCoverageCriterion> criterion = getInteractionCoverageCriteria(coverages);
			InteractionCoverageCriterion senderCoverageCriterion = criterion.getKey();
			InteractionCoverageCriterion receiverCoverageCriterion = criterion.getValue();
			ComponentInstanceVariableReferences dataflowTestedVariables = getDataflowCoverageVariables(
					coverages, DataflowCoverage.class);
			DataflowCoverageCriterion dataflowCoverageCriterion = getDataflowCoverageCriterion(coverages);
			ComponentInstancePortReferences testedComponentsForInteractionDataflow = getCoveragePorts(
					coverages, InteractionDataflowCoverage.class);
			DataflowCoverageCriterion interactionDataflowCoverageCriterion =
				getInteractionDataflowCoverageCriterion(coverages);
			
			InitialStateSetting initialStateSetting = transformInitialStateSetting(
					transformation.getInitialStateSetting());
			
			boolean optimize = transformation.isOptimize();
			boolean optimizeEnvironmentalMessageQueues = transformation.isOptimizeEnvironmentalMessageQueues();
			boolean optimizeArrays = optimizeEnvironmentalMessageQueues; // Same as optimizeEnvMQ to support code generation
			boolean optimizeMessageQueues = optimizeEnvironmentalMessageQueues; // ...
			
			Gamma2XstsTransformerSerializer transformer = new Gamma2XstsTransformerSerializer(
					component, reference.getArguments(),
					targetFolderUri, fileName,
					minSchedulingConstraint, maxSchedulingConstraint,
					optimize, optimizeArrays, optimizeMessageQueues, optimizeEnvironmentalMessageQueues,
					TransitionMerging.HIERARCHICAL,
					transformation.getPropertyPackage(),
					new AnnotatablePreprocessableElements(
						testedComponentsForStates,
						testedComponentsForUnstableStates,
						testedComponentsForTrapStates,
						testedComponentsForDeadlock,
						testedComponentsForNondeterministicTransitions,
						testedComponentsForTransitions,
						testedComponentsForTransitionPairs,
						testedComponentsForOutEvents,
						testedInteractions, senderCoverageCriterion, receiverCoverageCriterion,
						dataflowTestedVariables, dataflowCoverageCriterion,
						testedComponentsForInteractionDataflow, interactionDataflowCoverageCriterion
					),
					transformation.getInitialState(), initialStateSetting
			);
			transformer.execute();
			// Property serialization
			serializeProperties(fileName);
			logger.info("The XSTS transformation has been finished");
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return ThetaPropertySerializer.INSTANCE;
		}

		@Override
		protected String getQueryFileExtension() {
			return GammaFileNamer.THETA_QUERY_EXTENSION;
		}
	
	}
	
	class Xsts2UppaalTransformer extends AnalysisModelTransformer {
		
		public void execute(AnalysisModelTransformation transformation) {
			logger.info("Starting XSTS-UPPAAL transformation");
			XSTS xSts = (XSTS) GenmodelDerivedFeatures.getModel(transformation);
			String fileName = transformation.getFileName().get(0);
			execute(xSts, fileName);
		}

		public void execute(XSTS xSts, String fileName) {
			Xsts2UppaalTransformerSerializer xStsToUppaalTransformer =
					new Xsts2UppaalTransformerSerializer(xSts, targetFolderUri, fileName);
			xStsToUppaalTransformer.execute();
			logger.info("The XSTS-UPPAAL transformation has been finished");
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return XstsUppaalPropertySerializer.INSTANCE;
		}

		@Override
		protected String getQueryFileExtension() {
			return GammaFileNamer.UPPAAL_QUERY_EXTENSION;
		}
		
	}
	
	class Gamma2XstsUppaalTransformer extends AnalysisModelTransformer {
		
		public void execute(AnalysisModelTransformation transformation) throws IOException {
			logger.info("Starting Gamma -> XSTS-UPPAAL transformation");
			ComponentReference reference = (ComponentReference) transformation.getModel();
			Component component = reference.getComponent();
			Entry<Integer, Integer> schedulingConstraint = evaluateConstraint(transformation.getConstraint());
			Integer minSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getKey() : null;
			Integer maxSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getValue() : null;
			String fileName = transformation.getFileName().get(0);
			// Coverages
			List<Coverage> coverages = transformation.getCoverages();
			
			ComponentInstanceReferences testedComponentsForStates = getCoverageInstances(
					coverages, StateCoverage.class);
			ComponentInstanceReferences testedComponentsForUnstableStates = getCoverageInstances(
					coverages, UnstableStateCoverage.class);
			ComponentInstanceReferences testedComponentsForTrapStates = getCoverageInstances(
					coverages, TrapStateCoverage.class);
			ComponentInstanceReferences testedComponentsForDeadlock = getCoverageInstances(
					coverages, DeadlockCoverage.class);
			ComponentInstanceReferences testedComponentsForNondeterministicTransitions = getCoverageInstances(
					coverages, NonDeterministicTransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitions = getCoverageInstances(
					coverages, TransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitionPairs = getCoverageInstances(
					coverages, TransitionPairCoverage.class);
			ComponentInstancePortReferences testedComponentsForOutEvents = getCoveragePorts(
					coverages, OutEventCoverage.class);
			ComponentInstancePortStateTransitionReferences testedInteractions = getCoverageInteractions(
					coverages, InteractionCoverage.class);
			Entry<InteractionCoverageCriterion, InteractionCoverageCriterion> criterion = getInteractionCoverageCriteria(coverages);
			InteractionCoverageCriterion senderCoverageCriterion = criterion.getKey();
			InteractionCoverageCriterion receiverCoverageCriterion = criterion.getValue();
			ComponentInstanceVariableReferences dataflowTestedVariables = getDataflowCoverageVariables(
					coverages, DataflowCoverage.class);
			DataflowCoverageCriterion dataflowCoverageCriterion = getDataflowCoverageCriterion(coverages);
			ComponentInstancePortReferences testedComponentsForInteractionDataflow = getCoveragePorts(
					coverages, InteractionDataflowCoverage.class);
			DataflowCoverageCriterion interactionDataflowCoverageCriterion =
				getInteractionDataflowCoverageCriterion(coverages);
			
			InitialStateSetting initialStateSetting = transformInitialStateSetting(
					transformation.getInitialStateSetting());
			
			Gamma2XstsUppaalTransformerSerializer transformer = new Gamma2XstsUppaalTransformerSerializer(
					component, reference.getArguments(),
					targetFolderUri, fileName,
					minSchedulingConstraint, maxSchedulingConstraint,
					transformation.isOptimize(),
					TransitionMerging.HIERARCHICAL,
					transformation.getPropertyPackage(),
					new AnnotatablePreprocessableElements(
						testedComponentsForStates,
						testedComponentsForUnstableStates,
						testedComponentsForTrapStates,
						testedComponentsForDeadlock,
						testedComponentsForNondeterministicTransitions,
						testedComponentsForTransitions,
						testedComponentsForTransitionPairs,
						testedComponentsForOutEvents,
						testedInteractions, senderCoverageCriterion, receiverCoverageCriterion,
						dataflowTestedVariables, dataflowCoverageCriterion,
						testedComponentsForInteractionDataflow, interactionDataflowCoverageCriterion
					),
					transformation.getInitialState(), initialStateSetting
			);
			transformer.execute();
			// Property serialization
			serializeProperties(fileName);
			logger.info("The Gamma -> XSTS-UPPAAL transformation has been finished");
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return XstsUppaalPropertySerializer.INSTANCE;
		}

		@Override
		protected String getQueryFileExtension() {
			return GammaFileNamer.UPPAAL_QUERY_EXTENSION;
		}
		
	}
	
	class Gamma2XstsPromelaTransformer extends AnalysisModelTransformer {
		
		public void execute(AnalysisModelTransformation transformation) throws IOException {
			ComponentReference reference = (ComponentReference) transformation.getModel();
			Component component = reference.getComponent();
			Entry<Integer, Integer> schedulingConstraint = evaluateConstraint(transformation.getConstraint());
			Integer minSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getKey() : null;
			Integer maxSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getValue() : null;
			String fileName = transformation.getFileName().get(0);
			// Coverages
			List<Coverage> coverages = transformation.getCoverages();
			
			ComponentInstanceReferences testedComponentsForStates = getCoverageInstances(
					coverages, StateCoverage.class);
			ComponentInstanceReferences testedComponentsForUnstableStates = getCoverageInstances(
					coverages, UnstableStateCoverage.class);
			ComponentInstanceReferences testedComponentsForTrapStates = getCoverageInstances(
					coverages, TrapStateCoverage.class);
			ComponentInstanceReferences testedComponentsForDeadlock = getCoverageInstances(
					coverages, DeadlockCoverage.class);
			ComponentInstanceReferences testedComponentsForNondeterministicTransitions = getCoverageInstances(
					coverages, NonDeterministicTransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitions = getCoverageInstances(
					coverages, TransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitionPairs = getCoverageInstances(
					coverages, TransitionPairCoverage.class);
			ComponentInstancePortReferences testedComponentsForOutEvents = getCoveragePorts(
					coverages, OutEventCoverage.class);
			ComponentInstancePortStateTransitionReferences testedInteractions = getCoverageInteractions(
					coverages, InteractionCoverage.class);
			Entry<InteractionCoverageCriterion, InteractionCoverageCriterion> criterion = getInteractionCoverageCriteria(coverages);
			InteractionCoverageCriterion senderCoverageCriterion = criterion.getKey();
			InteractionCoverageCriterion receiverCoverageCriterion = criterion.getValue();
			ComponentInstanceVariableReferences dataflowTestedVariables = getDataflowCoverageVariables(
					coverages, DataflowCoverage.class);
			DataflowCoverageCriterion dataflowCoverageCriterion = getDataflowCoverageCriterion(coverages);
			ComponentInstancePortReferences testedComponentsForInteractionDataflow = getCoveragePorts(
					coverages, InteractionDataflowCoverage.class);
			DataflowCoverageCriterion interactionDataflowCoverageCriterion =
				getInteractionDataflowCoverageCriterion(coverages);
			
			InitialStateSetting initialStateSetting = transformInitialStateSetting(
					transformation.getInitialStateSetting());
			
			Gamma2XstsPromelaTransformerSerializer transformer = new Gamma2XstsPromelaTransformerSerializer(
					component, reference.getArguments(),
					targetFolderUri, fileName,
					minSchedulingConstraint, maxSchedulingConstraint,
					transformation.isOptimize(),
					TransitionMerging.HIERARCHICAL,
					transformation.getPropertyPackage(),
					new AnnotatablePreprocessableElements(
						testedComponentsForStates,
						testedComponentsForUnstableStates,
						testedComponentsForTrapStates,
						testedComponentsForDeadlock,
						testedComponentsForNondeterministicTransitions,
						testedComponentsForTransitions,
						testedComponentsForTransitionPairs,
						testedComponentsForOutEvents,
						testedInteractions, senderCoverageCriterion, receiverCoverageCriterion,
						dataflowTestedVariables, dataflowCoverageCriterion,
						testedComponentsForInteractionDataflow, interactionDataflowCoverageCriterion
					),
					transformation.getInitialState(), initialStateSetting
			);
			transformer.execute();
			// Property serialization
			serializeProperties(fileName);
			logger.info("The Gamma -> XSTS-Promela transformation has been finished");
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return PromelaPropertySerializer.INSTANCE;
		}

		@Override
		protected String getQueryFileExtension() {
			return GammaFileNamer.PROMELA_QUERY_EXTENSION;
		}
	}
	
	class Gamma2XstsNuxmvTransformer extends AnalysisModelTransformer {
		
		public void execute(AnalysisModelTransformation transformation) throws IOException {
			ComponentReference reference = (ComponentReference) transformation.getModel();
			Component component = reference.getComponent();
			Entry<Integer, Integer> schedulingConstraint = evaluateConstraint(transformation.getConstraint());
			Integer minSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getKey() : null;
			Integer maxSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getValue() : null;
			String fileName = transformation.getFileName().get(0);
			// Coverages
			List<Coverage> coverages = transformation.getCoverages();
			
			ComponentInstanceReferences testedComponentsForStates = getCoverageInstances(
					coverages, StateCoverage.class);
			ComponentInstanceReferences testedComponentsForUnstableStates = getCoverageInstances(
					coverages, UnstableStateCoverage.class);
			ComponentInstanceReferences testedComponentsForTrapStates = getCoverageInstances(
					coverages, TrapStateCoverage.class);
			ComponentInstanceReferences testedComponentsForDeadlock = getCoverageInstances(
					coverages, DeadlockCoverage.class);
			ComponentInstanceReferences testedComponentsForNondeterministicTransitions = getCoverageInstances(
					coverages, NonDeterministicTransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitions = getCoverageInstances(
					coverages, TransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitionPairs = getCoverageInstances(
					coverages, TransitionPairCoverage.class);
			ComponentInstancePortReferences testedComponentsForOutEvents = getCoveragePorts(
					coverages, OutEventCoverage.class);
			ComponentInstancePortStateTransitionReferences testedInteractions = getCoverageInteractions(
					coverages, InteractionCoverage.class);
			Entry<InteractionCoverageCriterion, InteractionCoverageCriterion> criterion = getInteractionCoverageCriteria(coverages);
			InteractionCoverageCriterion senderCoverageCriterion = criterion.getKey();
			InteractionCoverageCriterion receiverCoverageCriterion = criterion.getValue();
			ComponentInstanceVariableReferences dataflowTestedVariables = getDataflowCoverageVariables(
					coverages, DataflowCoverage.class);
			DataflowCoverageCriterion dataflowCoverageCriterion = getDataflowCoverageCriterion(coverages);
			ComponentInstancePortReferences testedComponentsForInteractionDataflow = getCoveragePorts(
					coverages, InteractionDataflowCoverage.class);
			DataflowCoverageCriterion interactionDataflowCoverageCriterion =
				getInteractionDataflowCoverageCriterion(coverages);
			
			InitialStateSetting initialStateSetting = transformInitialStateSetting(
					transformation.getInitialStateSetting());
			
			Gamma2XstsNuxmvTransformerSerializer transformer = new Gamma2XstsNuxmvTransformerSerializer(
					component, reference.getArguments(),
					targetFolderUri, fileName,
					minSchedulingConstraint, maxSchedulingConstraint,
					transformation.isOptimize(),
					TransitionMerging.HIERARCHICAL,
					transformation.getPropertyPackage(),
					new AnnotatablePreprocessableElements(
						testedComponentsForStates,
						testedComponentsForUnstableStates,
						testedComponentsForTrapStates,
						testedComponentsForDeadlock,
						testedComponentsForNondeterministicTransitions,
						testedComponentsForTransitions,
						testedComponentsForTransitionPairs,
						testedComponentsForOutEvents,
						testedInteractions, senderCoverageCriterion, receiverCoverageCriterion,
						dataflowTestedVariables, dataflowCoverageCriterion,
						testedComponentsForInteractionDataflow, interactionDataflowCoverageCriterion
					),
					transformation.getInitialState(), initialStateSetting
			);
			transformer.execute();
			// Property serialization
			serializeProperties(fileName);
			logger.info("The Gamma -> XSTS-NuXMV transformation has been finished");
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return NuxmvPropertySerializer.INSTANCE;
		}

		@Override
		protected String getQueryFileExtension() {
			return GammaFileNamer.PROMELA_QUERY_EXTENSION;
		}
	}
	
	class Gamma2OcraTransformer extends AnalysisModelTransformer {
		
		public void execute(AnalysisModelTransformation transformation) throws IOException {
			ComponentReference componentReference = (ComponentReference) transformation.getModel();
			List<Expression> arguments = componentReference.getArguments();
			Component component = componentReference.getComponent();
			Entry<Integer, Integer> schedulingConstraint = evaluateConstraint(transformation.getConstraint());
			Integer minSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getKey() : null;
			Integer maxSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getValue() : null;
			
			String fileName = transformation.getFileName().get(0);
			targetFolderUri = targetFolderUri + File.separator + "ocra";
			
			serializeProperties(transformation.getPropertyPackage(), fileName);
			
			
			Gamma2OcraTransformerSerializer gamma2OcraTransformer =
					new Gamma2OcraTransformerSerializer(component, arguments, targetFolderUri, fileName, minSchedulingConstraint, maxSchedulingConstraint);
			gamma2OcraTransformer.execute();
		}

		@Override
		protected PropertySerializer getPropertySerializer() {
			return OcraPropertySerializer.INSTANCE; 
		}

		@Override
		protected String getQueryFileExtension() {
			return GammaFileNamer.OCRA_CONTRACT_EXTENSION; 
		}
		
		@Override
		protected void serializeStringProperties(PropertyPackage propertyPackage, String fileName) {
			if (propertyPackage != null) {
				PropertySerializer propertySerializer = getPropertySerializer();
				
				//String serializedFormulas = propertySerializer.serializeCommentableStateFormulas(propertyPackage.getFormulas());
		        String serializedContracts = ((OcraPropertySerializer) propertySerializer).serializeContracts(propertyPackage.getContracts(), propertyPackage.getComponent());
		        //String combinedSerialization = serializedFormulas + "\n" + serializedContracts;

				fileUtil.saveString(targetFolderUri + File.separator + "." +
						fileName + "." + getQueryFileExtension(), serializedContracts);
			}
		}
		
	
	}
	
	class Gamma2XstsImlTransformer extends AnalysisModelTransformer {
		
		public void execute(AnalysisModelTransformation transformation) throws IOException {
			ComponentReference reference = (ComponentReference) transformation.getModel();
			Component component = reference.getComponent();
			Entry<Integer, Integer> schedulingConstraint = evaluateConstraint(transformation.getConstraint());
			Integer minSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getKey() : null;
			Integer maxSchedulingConstraint = (schedulingConstraint != null) ? schedulingConstraint.getValue() : null;
			String fileName = transformation.getFileName().get(0);
			// Coverages
			List<Coverage> coverages = transformation.getCoverages();
			
			ComponentInstanceReferences testedComponentsForStates = getCoverageInstances(
					coverages, StateCoverage.class);
			ComponentInstanceReferences testedComponentsForUnstableStates = getCoverageInstances(
					coverages, UnstableStateCoverage.class);
			ComponentInstanceReferences testedComponentsForTrapStates = getCoverageInstances(
					coverages, TrapStateCoverage.class);
			ComponentInstanceReferences testedComponentsForDeadlock = getCoverageInstances(
					coverages, DeadlockCoverage.class);
			ComponentInstanceReferences testedComponentsForNondeterministicTransitions = getCoverageInstances(
					coverages, NonDeterministicTransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitions = getCoverageInstances(
					coverages, TransitionCoverage.class);
			ComponentInstanceReferences testedComponentsForTransitionPairs = getCoverageInstances(
					coverages, TransitionPairCoverage.class);
			ComponentInstancePortReferences testedComponentsForOutEvents = getCoveragePorts(
					coverages, OutEventCoverage.class);
			ComponentInstancePortStateTransitionReferences testedInteractions = getCoverageInteractions(
					coverages, InteractionCoverage.class);
			Entry<InteractionCoverageCriterion, InteractionCoverageCriterion> criterion = getInteractionCoverageCriteria(coverages);
			InteractionCoverageCriterion senderCoverageCriterion = criterion.getKey();
			InteractionCoverageCriterion receiverCoverageCriterion = criterion.getValue();
			ComponentInstanceVariableReferences dataflowTestedVariables = getDataflowCoverageVariables(
					coverages, DataflowCoverage.class);
			DataflowCoverageCriterion dataflowCoverageCriterion = getDataflowCoverageCriterion(coverages);
			ComponentInstancePortReferences testedComponentsForInteractionDataflow = getCoveragePorts(
					coverages, InteractionDataflowCoverage.class);
			DataflowCoverageCriterion interactionDataflowCoverageCriterion =
				getInteractionDataflowCoverageCriterion(coverages);
			
			InitialStateSetting initialStateSetting = transformInitialStateSetting(
					transformation.getInitialStateSetting());
			
			Gamma2XstsImlTransformerSerializer transformer = new Gamma2XstsImlTransformerSerializer(
					component, reference.getArguments(),
					targetFolderUri, fileName,
					minSchedulingConstraint, maxSchedulingConstraint,
					transformation.isOptimize(),
					TransitionMerging.HIERARCHICAL,
					transformation.getPropertyPackage(),
					new AnnotatablePreprocessableElements(
						testedComponentsForStates,
						testedComponentsForUnstableStates,
						testedComponentsForTrapStates,
						testedComponentsForDeadlock,
						testedComponentsForNondeterministicTransitions,
						testedComponentsForTransitions,
						testedComponentsForTransitionPairs,
						testedComponentsForOutEvents,
						testedInteractions, senderCoverageCriterion, receiverCoverageCriterion,
						dataflowTestedVariables, dataflowCoverageCriterion,
						testedComponentsForInteractionDataflow, interactionDataflowCoverageCriterion
					),
					transformation.getInitialState(), initialStateSetting
			);
			transformer.execute();
			// Property serialization
			serializeProperties(fileName);
			logger.info("The Gamma -> XSTS-IML transformation has been finished");
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return null; // Not supported yet
		}

		@Override
		protected String getQueryFileExtension() {
			return null; // Not supported yet
		}
		
	}
	
}