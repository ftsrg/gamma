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

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.statechart.model.TimeSpecification;
import hu.bme.mit.gamma.statechart.model.composite.Component;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer;
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer.Scheduler;
import hu.bme.mit.gamma.uppaal.composition.transformation.ModelUnfolder;
import hu.bme.mit.gamma.uppaal.composition.transformation.ModelUnfolder.Trace;
import hu.bme.mit.gamma.uppaal.composition.transformation.Namings;
import hu.bme.mit.gamma.uppaal.composition.transformation.SimpleInstanceHandler;
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.Coverage;
import hu.bme.mit.gamma.genmodel.model.StateCoverage;
import hu.bme.mit.gamma.genmodel.model.TransitionCoverage;
import uppaal.NTA;

public class AnalysisModelTransformationHandler extends TaskHandler {

	public void execute(AnalysisModelTransformation analysisModelTransformation) throws IOException {
		checkArgument(analysisModelTransformation.getLanguage().size() == 1, 
				"A single formal modeling language must be specified: " + analysisModelTransformation.getLanguage());
		checkArgument(analysisModelTransformation.getLanguage().get(0) == AnalysisLanguage.UPPAAL, 
				"Currently only UPPAAL is supported.");
		setAnalysisModelTransformation(analysisModelTransformation);
		// Unfolding the given system
		Component component = analysisModelTransformation.getComponent();
		Package gammaPackage = (Package) component.eContainer();
		Trace trace = new ModelUnfolder().unfold(gammaPackage);
		Component newTopComponent = trace.getTopComponent();
		// Saving the Package of the unfolded model
		String flattenedModelFileName = "." + analysisModelTransformation.getFileName().get(0) + ".gsm";
		normalSave(trace.getPackage(), targetFolderUri, flattenedModelFileName);
		// Reading the model from disk as this is the only way it works
		ResourceSet resourceSet = new ResourceSetImpl(); // newTopComponent.eResource().getResourceSet() does not work
		resolveResources(newTopComponent, resourceSet, new HashSet<Resource>());
		logger.log(Level.INFO, "Resource set for flattened Gamma to UPPAAL transformation created: " + resourceSet);
		// Checking the model whether it contains forbidden elements
		hu.bme.mit.gamma.uppaal.transformation.ModelValidator validator = 
				new hu.bme.mit.gamma.uppaal.transformation.ModelValidator(resourceSet, newTopComponent, false);
		validator.checkModel();
		SimpleInstanceHandler simpleInstanceHandler = new SimpleInstanceHandler();
		// If there is no include in the coverage, it means all instances need to be tested
		Optional<Coverage> stateCoverage = analysisModelTransformation.getCoverages().stream()
						.filter(it -> it instanceof StateCoverage).findFirst();
		List<SynchronousComponentInstance> testedComponentsForStates = getIncludedSynchronousInstances(newTopComponent,
				stateCoverage, simpleInstanceHandler);
		// Replacing of instances is needed, as the old and new (cloned) instances are not equal,
		// thus, cannot be recognized by the SimpleInstanceHandler.contains method
		testedComponentsForStates.replaceAll(it -> trace.isMapped(it) ? (SynchronousComponentInstance) trace.get(it) : it);
		Optional<Coverage> transitionCoverage = analysisModelTransformation.getCoverages().stream()
						.filter(it -> it instanceof TransitionCoverage).findFirst();
		List<SynchronousComponentInstance> testedComponentsForTransitions = getIncludedSynchronousInstances(newTopComponent,
				transitionCoverage, simpleInstanceHandler);
		// Replacing of instances is needed, as the old and new (cloned) instances are not equal,
		// thus, cannot be recognized by the SimpleInstanceHandler.contains method
		testedComponentsForTransitions.replaceAll(it -> trace.isMapped(it) ? (SynchronousComponentInstance) trace.get(it) : it);
		logger.log(Level.INFO, "Resource set content for flattened Gamma to UPPAAL transformation: " + resourceSet);
		TimeSpecification minimumOrchestratingPeriod = analysisModelTransformation.getMinimumOrchestratingPeriod().isEmpty() ? 
				null : analysisModelTransformation.getMinimumOrchestratingPeriod().get(0); 
		TimeSpecification maximumOrchestratingPeriod = analysisModelTransformation.getMaximumOrchestratingPeriod().isEmpty() ? 
				null : analysisModelTransformation.getMaximumOrchestratingPeriod().get(0); 
		CompositeToUppaalTransformer transformer = new CompositeToUppaalTransformer(resourceSet,
			newTopComponent, analysisModelTransformation.getArguments(),
			getGammaScheduler(analysisModelTransformation.getScheduler().get(0)),
			minimumOrchestratingPeriod,
			maximumOrchestratingPeriod,
			analysisModelTransformation.isMinimalElementSet(),
			testedComponentsForStates, testedComponentsForTransitions); // newTopComponent
		SimpleEntry<NTA, G2UTrace> resultModels = transformer.execute();
		NTA nta = resultModels.getKey();
		// Saving the generated models
		normalSave(nta, targetFolderUri, "." + analysisModelTransformation.getFileName().get(0) + ".uppaal");
		normalSave(resultModels.getValue(), targetFolderUri, "." + analysisModelTransformation.getFileName().get(0) + ".g2u");
		// Serializing the NTA model to XML
		UppaalModelSerializer.saveToXML(nta, targetFolderUri, analysisModelTransformation.getFileName().get(0) + ".xml");
		// Creating a new query file
		new File(targetFolderUri + File.separator +	analysisModelTransformation.getFileName().get(0) + ".q").delete();
		if (analysisModelTransformation.getCoverages().stream().anyMatch(it -> it instanceof StateCoverage)) {
			UppaalModelSerializer.createStateReachabilityQueries(transformer.getTemplateLocationsMap(),
				Namings.getIsStableVariableName(), targetFolderUri, analysisModelTransformation.getFileName().get(0) + ".q");
		}
		if (analysisModelTransformation.getCoverages().stream().anyMatch(it -> it instanceof TransitionCoverage)) {
			// Suffix present? If not, all transitions can be reached; if yes, some transitions
			// are covered by transition fired in the same step, but the end is a stable state
			String querySuffix = Namings.getIsStableVariableName(); 
			UppaalModelSerializer.createTransitionFireabilityQueries(Namings.getTransitionIdVariableName(), transformer.getTransitionIdVariableIntervalValue(),
				querySuffix, targetFolderUri, analysisModelTransformation.getFileName().get(0) + ".q");
		}
		transformer.dispose();
	}
	
	private void setAnalysisModelTransformation(AnalysisModelTransformation analysisModelTransformation) {
		checkArgument(analysisModelTransformation.getFileName().size() <= 1);
		if (analysisModelTransformation.getFileName().isEmpty()) {
			String fileName = getNameWithoutExtension(getContainingFileName(analysisModelTransformation.getComponent()));
			analysisModelTransformation.getFileName().add(fileName);
		}
		checkArgument(analysisModelTransformation.getScheduler().size() <= 1);
		if (analysisModelTransformation.getScheduler().isEmpty()) {
			analysisModelTransformation.getScheduler().add(hu.bme.mit.gamma.genmodel.model.Scheduler.RANDOM);
		}
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
	
	private List<SynchronousComponentInstance> getIncludedSynchronousInstances(Component component, Optional<Coverage> coverage, SimpleInstanceHandler simpleInstanceHandler) {
		if (coverage.isPresent()) {
			Coverage presentCoverage = coverage.get();
			if (presentCoverage.getInclude().isEmpty()) {
				return simpleInstanceHandler.getSimpleInstances(component);
			}
			else {
				List<SynchronousComponentInstance> instances = new ArrayList<SynchronousComponentInstance>();
				// Include - exclude
				instances.addAll(simpleInstanceHandler.getSimpleInstances(presentCoverage.getInclude()));
				instances.removeAll(simpleInstanceHandler.getSimpleInstances(presentCoverage.getExclude()));
				return instances;
			}
		}
		return Collections.emptyList();
	}
	
	private Scheduler getGammaScheduler(hu.bme.mit.gamma.genmodel.model.Scheduler scheduler) {
		switch (scheduler) {
		case FAIR:
			return Scheduler.FAIR;
		default:
			return Scheduler.RANDOM;
		}
	}
	
}
