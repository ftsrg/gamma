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
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer.StaticSingleAssignmentTransformer;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer.StaticSingleAssignmentTransformer.SsaType;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.XstsOptimizer;
import hu.bme.mit.gamma.property.derivedfeatures.PropertyModelDerivedFeatures;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.transformation.util.PropertyUnfolder;
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.nuxmv.transformation.XstsToNuxmvTransformer;
import hu.bme.mit.gamma.xsts.transformation.SystemReducer;
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer;
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever;
import hu.bme.mit.gamma.xsts.uppaal.transformation.XstsToUppaalTransformer;
import uppaal.NTA;

public class OptimizerAndVerificationHandler extends TaskHandler {
	
	//

	protected boolean serializeTraces; // Denotes whether traces are serialized
	
	protected VerificationHandler verificationHandler = null;
	
	//
	
	protected final SystemReducer xStsReducer = SystemReducer.INSTANCE;
	protected final ActionSerializer xStsSerializer = ActionSerializer.INSTANCE;
	protected final hu.bme.mit.gamma.xsts.promela.transformation.serializer.ModelSerializer promelaSerializer =
			hu.bme.mit.gamma.xsts.promela.transformation.serializer.ModelSerializer.INSTANCE;
	protected final hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer.ModelSerializer smvSerializer =
			hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer.ModelSerializer.INSTANCE;
	protected final VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE;
	
	//
	
	public OptimizerAndVerificationHandler(IFile file) {
		this(file, true);
	}
	
	public OptimizerAndVerificationHandler(IFile file, boolean serializeTraces) {
		super(file);
		this.serializeTraces = serializeTraces;
	}
	
	//
	
	public void execute(Verification verification) throws IOException, InterruptedException {
		List<AnalysisLanguage> analysisLanguages = verification.getAnalysisLanguages();
		AnalysisLanguage analysisLanguage = analysisLanguages.get(0);
		checkArgument(analysisLanguages.contains(AnalysisLanguage.THETA) ||
				analysisLanguages.contains(AnalysisLanguage.XSTS_UPPAAL) ||
				analysisLanguages.contains(AnalysisLanguage.PROMELA) ||
				analysisLanguages.contains(AnalysisLanguage.NUXMV) ||
				analysisLanguages.contains(AnalysisLanguage.IML),
				analysisLanguage + " is not supported for slicing");
		
		List<String> fileNames = verification.getFileName();
		String analysisFilePath = fileNames.get(0);
		File analysisFile = null;
		
		// Checking the file name
		try {
			analysisFile = super.exporeRelativeFile(verification, analysisFilePath);
		} catch (NullPointerException e) {
			if (!fileUtil.hasExtension(analysisFilePath) ) {
				String fileExtension = fileNamer.getFileExtension(analysisLanguage);
				analysisFilePath = fileUtil.changeExtension(analysisFilePath, fileExtension);
				fileNames.set(0, analysisFilePath);
			}
			try {
				analysisFile = super.exporeRelativeFile(verification, analysisFilePath);
			} catch (NullPointerException ex) {
				// Verification is not serialized?
				analysisFile = new File(projectLocation + File.separator + analysisFilePath);
			}
		}
		//
		
		String gStsFilePath = fileNamer.getEmfXStsUri(analysisFilePath);
		File gStsFile = super.exporeRelativeFile(verification, gStsFilePath);
		
		Component newTopComponent = null; // See property unfolding a few lines below
		
		boolean optimizeOutEvents = verification.isOptimizeOutEvents();
		
		Queue<CommentableStateFormula> formulas = new LinkedList<CommentableStateFormula>();
		List<PropertyPackage> propertyPackages = verification.getPropertyPackages();
		List<PropertyPackage> savedPropertyPackages = new ArrayList<PropertyPackage>(propertyPackages);
		
		PropertyPackage mainPropertyPackage = null;
		
		for (PropertyPackage propertyPackage : propertyPackages) {
			// Checking if it is unfolded
			if (!PropertyModelDerivedFeatures.isUnfolded(propertyPackage)) {
				if (newTopComponent == null) {
					logger.info("Loading unfolded package for property unfolding");
					
					String unfoldedGsmFilePath = fileNamer.getUnfoldedPackageUri(analysisFilePath);
					File unfoldedGsmFile = super.exporeRelativeFile(verification, unfoldedGsmFilePath);
					
					Package newPackage = (Package) ecoreUtil.normalLoad(unfoldedGsmFile);
					newTopComponent = StatechartModelDerivedFeatures.getFirstComponent(newPackage);
				}
				PropertyUnfolder propertyUnfolder =
						new PropertyUnfolder(propertyPackage, newTopComponent);
				propertyPackage = propertyUnfolder.execute();
			}
			//
			
			if (mainPropertyPackage == null) {
				mainPropertyPackage = ecoreUtil.clone(propertyPackage);
			}
			formulas.addAll(
					ecoreUtil.clone( // To prevent destroying the original property packages
							propertyPackage.getFormulas()));
		}
		
		propertyPackages.clear();
		List<CommentableStateFormula> checkableFormulas = mainPropertyPackage.getFormulas();
		
		// Only one property package - we will add the formulas one by one
		propertyPackages.add(mainPropertyPackage);
		// As such, it is unnecessary to optimize the generated trace(s)
		boolean isOptimize = verification.isOptimize();
//		verification.setOptimize(false); // Now one by one optimization is also supported
		
		// State slicing preparation
		Map<State, Collection<State>> reachableStates = new HashMap<State, Collection<State>>();
		Component component = mainPropertyPackage.getComponent();
		Collection<StatechartDefinition> statecharts = StatechartModelDerivedFeatures.getAllContainedStatecharts(component);
		for (StatechartDefinition statechart : statecharts) {
			Collection<State> states = StatechartModelDerivedFeatures.getAllStates(statechart);
			for (State state : states) {
				Collection<State> allReachableStates = StatechartModelDerivedFeatures.getAllReachableStates(state);
				reachableStates.put(state, allReachableStates);
			}
		}
		//
		
		// A single one to store the traces and support later optimization - false: no trace serialization
		verificationHandler = new VerificationHandler(file, false);
		//
		int i = 0; // Only for logging
		while (!formulas.isEmpty()) {
			CommentableStateFormula formula = formulas.poll();
			checkableFormulas.clear();
			checkableFormulas.add(formula);
			
			// Reload XSTS to retrieve all variables
			XSTS xSts = (XSTS) ecoreUtil.normalLoad(gStsFile);
			
			// Optimize XSTS based on formula
			List<ComponentInstanceVariableReferenceExpression> keepableVariableReferences =
					ecoreUtil.getAllContentsOfType(formula,
							ComponentInstanceVariableReferenceExpression.class); // Must reference the unwrapped
			List<VariableDeclaration> keepableGammaVariables = keepableVariableReferences.stream()
					.map(it -> it.getVariableDeclaration())
					.collect(Collectors.toList());
			List<ComponentInstanceStateReferenceExpression> keepableStateReferences =
					ecoreUtil.getAllContentsOfType(formula,
							ComponentInstanceStateReferenceExpression.class); // Must reference the unwrapped
			List<State> keepableGammaStates = keepableStateReferences.stream()
					.map(it -> it.getState())
					.collect(Collectors.toList());
			//
			
//			xStsReducer.deleteUnnecessaryStates(xSts, formula, reachableStates); // Still experimental
			if (optimizeOutEvents) {
				xStsReducer.deleteUnusedAndWrittenOnlyVariables(xSts, keepableGammaVariables);
			}
			else {
				xStsReducer.deleteUnusedAndWrittenOnlyVariablesExceptOutEvents(xSts, keepableGammaVariables);
			}
			xStsReducer.deleteUnusedInputEventVariables(xSts, keepableGammaVariables);
			xStsReducer.deleteTrivialCodomainVariablesExceptOutEvents(xSts, keepableGammaVariables, keepableGammaStates);
			xStsReducer.deleteUnnecessaryInputVariablesExceptOutEvents(xSts, keepableGammaVariables);
			// Deleting enum literals
			Set<EnumerationLiteralDefinition> keepableGammaEnumLiterals =
					ecoreUtil.getAllContentsOfType(formula, EnumerationLiteralExpression.class).stream()
							.map(it -> it.getReference())
							.collect(Collectors.toSet());
			if (!analysisLanguages.contains(AnalysisLanguage.XSTS_UPPAAL)) {
				// In UPPAAL, literals are referenced via indexes, so they cannot be removed
				xStsReducer.deleteUnusedEnumLiteralsExceptOne(xSts, keepableGammaEnumLiterals);
			}
			else {
				// Therefore, they are renamed to indicate that they are unused
				xStsReducer.renameUnusedEnumLiteralsExceptOne(xSts, keepableGammaEnumLiterals);
			}
			
			XstsOptimizer xStsOptimizer = XstsOptimizer.INSTANCE;
			xStsOptimizer.optimizeXSts(xSts); // To remove null/empty actions
			// Serialize XSTS
			if (analysisLanguages.contains(AnalysisLanguage.THETA)) {
				String xStsString = xStsSerializer.serializeXsts(xSts);
				fileUtil.saveString(analysisFile, xStsString);
			}
			if (analysisLanguages.contains(AnalysisLanguage.XSTS_UPPAAL)) {
				XstsToUppaalTransformer transformer = new XstsToUppaalTransformer(xSts);
				NTA nta = transformer.execute();
				UppaalModelSerializer.saveToXML(nta, analysisFile);
				
				String xStsString = xStsSerializer.serializeXsts(xSts);
				String xStsFile = fileUtil.changeExtension(
						analysisFile.toString(), GammaFileNamer.XSTS_XTEXT_EXTENSION);
				fileUtil.saveString(xStsFile, xStsString);
			}
			if (analysisLanguages.contains(AnalysisLanguage.PROMELA)) {
				String promelaString = promelaSerializer.serializePromela(xSts);
				fileUtil.saveString(analysisFile, promelaString);
				
				String xStsString = xStsSerializer.serializeXsts(xSts);
				String xStsFile = fileUtil.changeExtension(
						analysisFile.toString(), GammaFileNamer.XSTS_XTEXT_EXTENSION);
				fileUtil.saveString(xStsFile, xStsString);
			}
			if (analysisLanguages.contains(AnalysisLanguage.NUXMV)) {
				// SSE
				StaticSingleAssignmentTransformer sseTransformer =
						new StaticSingleAssignmentTransformer(xSts, SsaType.OUT_TRANS);
				sseTransformer.execute();
				// SMV
				XstsToNuxmvTransformer nuxmvTransformer = new XstsToNuxmvTransformer(xSts,
					analysisFile.getParentFile().toString(), analysisFile.getName());
				nuxmvTransformer.execute();
				// XSTS
				String xStsString = xStsSerializer.serializeXsts(xSts, true);
				String xStsFile = fileUtil.changeExtension(
						analysisFile.toString(), GammaFileNamer.XSTS_XTEXT_EXTENSION);
				fileUtil.saveString(xStsFile, xStsString);
			}
			//
			
			verificationHandler.execute(verification);
			
			// Checking if some of the unchecked properties are already covered by stored traces
			if (isOptimize) {
				verificationHandler.removeCoveredProperties2(formulas);
			}
			logger.info("The verification of property " + ++i + " finished; " + formulas.size() + " remaining");
		}
		
		if (isOptimize) {
			// Traces have not been serialized yet, doing it now
			verificationHandler.optimizeTraces();
		}
    
		ProgrammingLanguage programmingLanguage = verificationHandler.getProgrammingLanguage();
		if (serializeTraces) {
			verificationHandler.serializeTraces(programmingLanguage); // Serialization in one pass
		}
    
		// Reinstate original state
		propertyPackages.clear();
		propertyPackages.addAll(savedPropertyPackages);
	}
	
	//
	
	public VerificationHandler getVerificationHandler() {
		return verificationHandler;
	}
	
	public List<ExecutionTrace> getTraces() {
		return verificationHandler.getTraces();
	}

}