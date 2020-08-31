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

import java.io.File;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.logging.Level;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.Coverage;
import hu.bme.mit.gamma.genmodel.model.InteractionCoverage;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.OutEventCoverage;
import hu.bme.mit.gamma.genmodel.model.StateCoverage;
import hu.bme.mit.gamma.genmodel.model.TransitionCoverage;
import hu.bme.mit.gamma.genmodel.model.XSTSReference;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.util.PropertyGenerator;
import hu.bme.mit.gamma.querygenerator.serializer.PropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.ThetaPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.UppaalPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.XSTSUppaalPropertySerializer;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.transformation.util.AnalysisModelPreprocessor;
import hu.bme.mit.gamma.transformation.util.GammaStatechartAnnotator;
import hu.bme.mit.gamma.transformation.util.SimpleInstanceHandler;
import hu.bme.mit.gamma.uppaal.composition.transformation.AsynchronousInstanceConstraint;
import hu.bme.mit.gamma.uppaal.composition.transformation.AsynchronousSchedulerTemplateCreator.Scheduler;
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer;
import hu.bme.mit.gamma.uppaal.composition.transformation.Constraint;
import hu.bme.mit.gamma.uppaal.composition.transformation.OrchestratingConstraint;
import hu.bme.mit.gamma.uppaal.composition.transformation.SchedulingConstraint;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.UppaalModelPreprocessor;
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer;
import hu.bme.mit.gamma.uppaal.transformation.ModelValidator;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.transformation.GammaToXSTSTransformer;
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer;
import hu.bme.mit.gamma.xsts.uppaal.transformation.XSTSToUppaalTransformer;
import uppaal.NTA;

public class AnalysisModelTransformationHandler extends TaskHandler {
	
	public AnalysisModelTransformationHandler(IFile file) {
		super(file);
	}
	
	public void execute(AnalysisModelTransformation analysisModelTransformation) throws IOException {
		ModelReference modelReference = analysisModelTransformation.getModel();
		setAnalysisModelTransformation(analysisModelTransformation);
		Set<AnalysisLanguage> languagesSet = new HashSet<AnalysisLanguage>(analysisModelTransformation.getLanguages());
		for (AnalysisLanguage analysisLanguage : languagesSet) {
			AnalysisModelTransformer transformer;
			switch (analysisLanguage) {
				case UPPAAL:
					if (modelReference instanceof ComponentReference) {
						transformer = new Gamma2UppaalTransformer();
					}
					else if (modelReference instanceof XSTSReference) {
						transformer = new XSTS2UppaalTransformer();
					}
					else {
						throw new IllegalArgumentException("Not known model reference: " + modelReference);
					}
					break;
				case THETA:
					transformer = new Gamma2XSTSTransformer();
					break;
				case XSTS_UPPAAL:
					transformer = new Gamma2XSTSUppaalTransformer();
					break;
				default:
					throw new IllegalArgumentException("Currently only UPPAAL and Theta are supported.");
			}
			transformer.execute(analysisModelTransformation);
		}
	}
	
	private void setAnalysisModelTransformation(AnalysisModelTransformation analysisModelTransformation) {
		checkArgument(analysisModelTransformation.getFileName().size() <= 1);
		if (analysisModelTransformation.getFileName().isEmpty()) {
			EObject sourceModel = GenmodelDerivedFeatures.getModel(analysisModelTransformation);
			String fileName = getNameWithoutExtension(getContainingFileName(sourceModel));
			analysisModelTransformation.getFileName().add(fileName);
		}
		checkArgument(analysisModelTransformation.getScheduler().size() <= 1);
		if (analysisModelTransformation.getScheduler().isEmpty()) {
			analysisModelTransformation.getScheduler().add(hu.bme.mit.gamma.genmodel.model.Scheduler.RANDOM);
		}
	}
	
	abstract class AnalysisModelTransformer {
		protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
		protected FileUtil fileUtil = FileUtil.INSTANCE;
		
		protected final String XSTS_EMF_EXTENSION = "gsts";
		protected final String XSTS_XTEXT_EXTENSION = "xsts";
		
		public abstract void execute(AnalysisModelTransformation analysisModelTransformation) throws IOException;
	
		protected void annotateModelAndGenerateProperties(
				AnalysisModelTransformation analysisModelTransformation, 
				Component newTopComponent) throws IOException {
			Package newPackage = StatechartModelDerivedFeatures.getContainingPackage(newTopComponent);

			// State coverage
			Optional<Coverage> stateCoverage = analysisModelTransformation.getCoverages().stream()
							.filter(it -> it instanceof StateCoverage).findFirst();
			List<SynchronousComponentInstance> testedComponentsForStates = getIncludedSynchronousInstances(
					newTopComponent, stateCoverage);
			// Transition coverage
			Optional<Coverage> transitionCoverage = analysisModelTransformation.getCoverages().stream()
							.filter(it -> it instanceof TransitionCoverage).findFirst();
			List<SynchronousComponentInstance> testedComponentsForTransitions = getIncludedSynchronousInstances(
					newTopComponent, transitionCoverage);
			// Out event coverage
			Optional<Coverage> outEventCoverage = analysisModelTransformation.getCoverages().stream()
							.filter(it -> it instanceof OutEventCoverage).findFirst();
			List<SynchronousComponentInstance> testedComponentsForOutEvents = getIncludedSynchronousInstances(
					newTopComponent, outEventCoverage);
			// Interaction coverage
			Optional<Coverage> interactionCoverage = analysisModelTransformation.getCoverages().stream()
							.filter(it -> it instanceof InteractionCoverage).findFirst();
			List<SynchronousComponentInstance> testedComponentsForInteractions = getIncludedSynchronousInstances(
					newTopComponent, interactionCoverage);
			
			GammaStatechartAnnotator statechartAnnotator = new GammaStatechartAnnotator(newPackage,
					testedComponentsForTransitions, testedComponentsForInteractions);
			statechartAnnotator.annotateModel();
			ecoreUtil.save(newPackage); // It must be saved so the property package can be serialized
			// We are after model unfolding, so the argument is true
			PropertyGenerator propertyGenerator = new PropertyGenerator(true);
			PropertyPackage propertyPackage = propertyGenerator.initializePackage(newTopComponent);
			propertyPackage.getFormulas().addAll(
					propertyGenerator.createTransitionReachability(
							statechartAnnotator.getTransitionVariables()));
			propertyPackage.getFormulas().addAll(
					propertyGenerator.createInteractionReachability(
							statechartAnnotator.getInteractions()));
			propertyPackage.getFormulas().addAll(
					propertyGenerator.createStateReachability(
							testedComponentsForStates));
			propertyPackage.getFormulas().addAll(
					propertyGenerator.createOutEventReachability(newTopComponent,
							testedComponentsForOutEvents));
			// Saving the property package
			saveModel(propertyPackage, targetFolderUri, "." + analysisModelTransformation.getFileName().get(0) + ".gpd");
			PropertySerializer propertySerializer = getPropertySerializer();
			String serializedFormulas = propertySerializer.serializeCommentableStateFormulas(propertyPackage.getFormulas());
			fileUtil.saveString(targetFolderUri + File.separator + analysisModelTransformation.getFileName().get(0) + "." + getQueryFileExtension(), serializedFormulas);
		}
		
		protected abstract PropertySerializer getPropertySerializer();
		
		protected abstract String getQueryFileExtension();
		
		protected List<SynchronousComponentInstance> getIncludedSynchronousInstances(Component component,
				Optional<Coverage> coverage) {
			SimpleInstanceHandler simpleInstanceHandler = SimpleInstanceHandler.INSTANCE;
			if (coverage.isPresent()) {
				Coverage presentCoverage = coverage.get();
				return simpleInstanceHandler.getNewSimpleInstances(presentCoverage.getInclude(),
					presentCoverage.getExclude(), component);
			}
			return Collections.emptyList();
		}
		
	}
	
	class Gamma2UppaalTransformer extends AnalysisModelTransformer {
		
		protected final UppaalModelPreprocessor preprocessor = UppaalModelPreprocessor.INSTANCE;
		
		public void execute(AnalysisModelTransformation analysisModelTransformation) throws IOException {
			// Unfolding the given system
			ComponentReference componentReference = (ComponentReference) analysisModelTransformation.getModel();
			Component component = componentReference.getComponent();
			Package gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(component);
			Component newTopComponent = preprocessor.preprocess(gammaPackage, componentReference.getArguments(),
				new File(targetFolderUri + File.separator + analysisModelTransformation.getFileName().get(0) + ".gcd"));
			// Top component arguments are now be contained by the Package (preprocess)
			// Checking the model whether it contains forbidden elements
			ModelValidator validator = new ModelValidator(newTopComponent, false);
			validator.checkModel();
			// Annotate model for test generation
			annotateModelAndGenerateProperties(analysisModelTransformation, newTopComponent);
			// Normal transformation
			logger.log(Level.INFO, "Resource set content for flattened Gamma to UPPAAL transformation: " +
					newTopComponent.eResource().getResourceSet());
			Constraint constraint = transformConstraint(analysisModelTransformation.getConstraint(), newTopComponent);
			CompositeToUppaalTransformer transformer = new CompositeToUppaalTransformer(
				newTopComponent, // newTopComponent
				getGammaScheduler(analysisModelTransformation.getScheduler().get(0)),
				constraint,
				analysisModelTransformation.isMinimalElementSet()); 
			SimpleEntry<NTA, G2UTrace> resultModels = transformer.execute();
			NTA nta = resultModels.getKey();
			// Saving the generated models
			ecoreUtil.normalSave(nta, targetFolderUri, "." + analysisModelTransformation.getFileName().get(0) + ".uppaal");
			ecoreUtil.normalSave(resultModels.getValue(), targetFolderUri, "." + analysisModelTransformation.getFileName().get(0) + ".g2u");
			// Serializing the NTA model to XML
			UppaalModelSerializer.saveToXML(nta, targetFolderUri, analysisModelTransformation.getFileName().get(0) + ".xml");
			logger.log(Level.INFO, "The UPPAAL transformation has been finished.");
		}
		
		private Constraint transformConstraint(hu.bme.mit.gamma.genmodel.model.Constraint constraint, Component newComponent) {
			if (constraint == null) {
				return null;
			}
			if (constraint instanceof hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint) {
				hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint orchestratingConstraint = (hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint) constraint;
				return new OrchestratingConstraint(orchestratingConstraint.getMinimumPeriod(), orchestratingConstraint.getMaximumPeriod());
			}
			if (constraint instanceof hu.bme.mit.gamma.genmodel.model.SchedulingConstraint) {
				hu.bme.mit.gamma.genmodel.model.SchedulingConstraint schedulingConstraint = (hu.bme.mit.gamma.genmodel.model.SchedulingConstraint) constraint;
				SchedulingConstraint gammaSchedulingConstraint = new SchedulingConstraint();
				for (hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint instanceConstraint : schedulingConstraint.getInstanceConstraint()) {
					gammaSchedulingConstraint.getInstanceConstraints().addAll(transformAsynchronousInstanceConstraint(instanceConstraint, newComponent));
				}
				return gammaSchedulingConstraint;
			}
			throw new IllegalArgumentException("Not known constraint: " + constraint);
		}
		
		private List<AsynchronousInstanceConstraint> transformAsynchronousInstanceConstraint(
				hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint asynchronousInstanceConstraint, Component newComponent) {
			if (newComponent instanceof AsynchronousAdapter) {
				// In the case of asynchronous adapters, the referred instance will be null
				return Collections.singletonList(new AsynchronousInstanceConstraint(null,
					(OrchestratingConstraint) transformConstraint(asynchronousInstanceConstraint.getOrchestratingConstraint(), newComponent)));
			}
			// Asynchronous composite components
			SimpleInstanceHandler instanceHandler = SimpleInstanceHandler.INSTANCE;
			List<AsynchronousInstanceConstraint> asynchronousInstanceConstraints = new ArrayList<AsynchronousInstanceConstraint>();
			ComponentInstanceReference originalInstance = asynchronousInstanceConstraint.getInstance();
			List<AsynchronousComponentInstance> newAsynchronousSimpleInstances = instanceHandler
					.getNewAsynchronousSimpleInstances(originalInstance, newComponent);
			for (AsynchronousComponentInstance newAsynchronousSimpleInstance : newAsynchronousSimpleInstances) {
				asynchronousInstanceConstraints.add(new AsynchronousInstanceConstraint(newAsynchronousSimpleInstance,
					(OrchestratingConstraint) transformConstraint(asynchronousInstanceConstraint.getOrchestratingConstraint(), newComponent)));
			}
			return asynchronousInstanceConstraints;
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
			return "q";
		}
		
	}
	
	class Gamma2XSTSTransformer extends AnalysisModelTransformer {
		
		protected final AnalysisModelPreprocessor modelPreprocessor = AnalysisModelPreprocessor.INSTANCE;
		protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
		protected final ActionSerializer actionSerializer = ActionSerializer.INSTANCE;
		
		public void execute(AnalysisModelTransformation analysisModelTransformation) throws IOException {
			logger.log(Level.INFO, "Starting XSTS transformation.");
			// Unfolding the given system
			ComponentReference componentReference = (ComponentReference) analysisModelTransformation.getModel();
			Component component = componentReference.getComponent();
			Package gammaPackage = (Package) component.eContainer();
			Integer schedulingConstraint = transformConstraint(analysisModelTransformation.getConstraint());
			GammaToXSTSTransformer gammaToXSTSTransformer = new GammaToXSTSTransformer(schedulingConstraint, true, true);
			String fileName = analysisModelTransformation.getFileName().get(0);
			File xStsFile = new File(targetFolderUri + File.separator + fileName + "." + XSTS_XTEXT_EXTENSION);
			// Preprocess
			Component newComponent = modelPreprocessor.preprocess(gammaPackage,
					componentReference.getArguments(), xStsFile);
			Package newGammaPackage = StatechartModelDerivedFeatures.getContainingPackage(newComponent);
			// Property generation
			annotateModelAndGenerateProperties(analysisModelTransformation, newComponent);
			// Normal transformation
			XSTS xSts = gammaToXSTSTransformer.execute(newGammaPackage);
			// EMF
			ecoreUtil.normalSave(xSts, targetFolderUri, fileName + "." + XSTS_EMF_EXTENSION);
			// String
			String xStsString = actionSerializer.serializeXSTS(xSts);
			fileUtil.saveString(xStsFile, xStsString);
			logger.log(Level.INFO, "The XSTS transformation has been finished.");
		}
		
		private Integer transformConstraint(hu.bme.mit.gamma.genmodel.model.Constraint constraint) {
			if (constraint == null) {
				return null;
			}
			if (constraint instanceof hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint) {
				hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint orchestratingConstraint =
						(hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint) constraint;
				TimeSpecification minimumPeriod = orchestratingConstraint.getMinimumPeriod();
				TimeSpecification maximumPeriod = orchestratingConstraint.getMaximumPeriod();
				int min = statechartUtil.evaluateMilliseconds(minimumPeriod);
				int max = statechartUtil.evaluateMilliseconds(maximumPeriod);
				if (min == max) {
					return min;
				}
			}
			throw new IllegalArgumentException("Not known constraint: " + constraint);
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return ThetaPropertySerializer.INSTANCE;
		}

		@Override
		protected String getQueryFileExtension() {
			return "prop";
		}
	
	}
	
	class XSTS2UppaalTransformer extends AnalysisModelTransformer {
		
		public void execute(AnalysisModelTransformation analysisModelTransformation) {
			logger.log(Level.INFO, "Starting XSTS-UPPAAL transformation.");
			XSTS xSts = (XSTS) GenmodelDerivedFeatures.getModel(analysisModelTransformation);
			String fileName = analysisModelTransformation.getFileName().get(0);
			execute(xSts, fileName);
		}

		public void execute(XSTS xSts, String fileName) {
			XSTSToUppaalTransformer xStsToUppaalTransformer = new XSTSToUppaalTransformer(xSts);
			NTA nta = xStsToUppaalTransformer.execute();
			ecoreUtil.normalSave(nta, targetFolderUri, "." + fileName + ".uppaal");
			// Serializing the NTA model to XML
			UppaalModelSerializer.saveToXML(nta, targetFolderUri, fileName + ".xml");
			// Creating a new query file
			logger.log(Level.INFO, "The transformation has been finished.");
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return XSTSUppaalPropertySerializer.INSTANCE;
		}

		@Override
		protected String getQueryFileExtension() {
			return "q";
		}
		
	}
	
	class Gamma2XSTSUppaalTransformer extends AnalysisModelTransformer {
		
		public void execute(AnalysisModelTransformation analysisModelTransformation) throws IOException {
			logger.log(Level.INFO, "Starting Gamma -> XSTS-UPPAAL transformation.");
			Gamma2XSTSTransformer thetaTransformer = new Gamma2XSTSTransformer();
			thetaTransformer.execute(analysisModelTransformation);
			String fileName = analysisModelTransformation.getFileName().get(0);
			XSTS xSts = (XSTS) ecoreUtil.normalLoad(targetFolderUri, fileName + "." + XSTS_EMF_EXTENSION);
			XSTS2UppaalTransformer xSts2UppaalTransformer = new XSTS2UppaalTransformer();
			xSts2UppaalTransformer.execute(xSts, fileName);
			// Creating a new query file
			logger.log(Level.INFO, "The transformation has been finished.");
		}
		
		@Override
		protected PropertySerializer getPropertySerializer() {
			return XSTSUppaalPropertySerializer.INSTANCE; // Will not work, due to the thetaTransformer.execute call
		}

		@Override
		protected String getQueryFileExtension() {
			return "q";
		}
		
	}
	
}
