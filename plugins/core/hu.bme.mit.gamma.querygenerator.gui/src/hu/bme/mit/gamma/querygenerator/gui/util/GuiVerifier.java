/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.gui.util;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map.Entry;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.swing.SwingWorker;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.querygenerator.application.View;
import hu.bme.mit.gamma.querygenerator.controller.AbstractController;
import hu.bme.mit.gamma.trace.language.ui.serializer.TraceLanguageSerializer;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator;
import hu.bme.mit.gamma.trace.util.TraceUtil;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;
import hu.bme.mit.gamma.verification.util.AbstractVerifier;
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result;

/** Runnable class responsible for the execution of formal verification. */
public class GuiVerifier extends SwingWorker<ThreeStateBoolean, Boolean> {
	// The query needs to be added in addition to the model
	private String originalQueries;
	// Process running the verification
	private AbstractVerifier verifier;
	// Indicates whether this worker is cancelled: needed as the original isCancelled is updated late
	private volatile boolean isCancelled = false;
	// Indicates whether it should contribute to the View in any form
	private boolean contributeToView;
	
	private final View view;
	
	protected final TraceUtil traceUtil = TraceUtil.INSTANCE;	
	protected final Logger logger = Logger.getLogger("GammaLogger");
	
	public GuiVerifier(String query, boolean contributeToView, View view) {
		this.originalQueries = query;
		this.contributeToView = contributeToView;
		this.view = view;
	}
	
	private AbstractController getController() {
		return view.getController();
	}
	
	@Override
	public ThreeStateBoolean doInBackground() throws Exception {
		try {
			// Disabling the verification buttons
			view.setVerificationButtons(false);
			// Common traceability and execution trace
			Object traceability = getController().getTraceability();
			ExecutionTrace traceModel = null;
			// Verification starts
			verifier = getController().createVerifier();
			Result result = verifier.verifyQuery(traceability, getController().getParameters(),
					new File(getController().getModelFile()), originalQueries);
			traceModel = result.getTrace();
			if (traceModel != null) {
				// No trace
				if (view.isOptimizeTestSet()) {
					// Removal of covered steps
					traceUtil.removeCoveredSteps(traceModel);
				}
				serializeTestCode(traceModel);
			}
			return verifier.getResult();
		} catch (NullPointerException e) {
			e.printStackTrace();
			throw new IllegalArgumentException("Error! The generated model file cannot be found.");
		} catch (FileNotFoundException e) {
			throw new IllegalArgumentException("Error! The generated model file cannot be found.");
		} catch (Throwable e) {
			final String errorMessage = "Cannot handle deadlock predicate for models with priorities or guarded broadcast receivers.";
			if (e.getMessage().contains(errorMessage)) {
				// Not a big problem
				logger.log(Level.SEVERE, errorMessage);
				return ThreeStateBoolean.UNDEF;
			}
			else {
				e.printStackTrace();
				IllegalArgumentException ex = new IllegalArgumentException("Error! " + e.getMessage());
				ex.initCause(e);
				throw ex;
			}
		} finally {
			verifier = null;
		}
	}
	
	private void serializeTestCode(ExecutionTrace traceModel)
			throws CoreException, IOException, FileNotFoundException {
		Entry<String, Integer> fileNameAndId = getController().getFileName("get"); // File extension could be gtr or get
		fileNameAndId = saveModel(traceModel, fileNameAndId);
		// Have to be the SAME resource set as before (traceabilitySet) otherwise the trace model contains references to dead objects
		String packageName = getController().getBasePackage();
		TestGenerator testGenerator = new TestGenerator(traceModel,
				packageName, "ExecutionTraceSimulation" + fileNameAndId.getValue());
		String testClassCode = testGenerator.execute();
		String testClassParentFolder = getController().getTestGenFolder() + "/" + 
				testGenerator.getPackageName().replaceAll("\\.", "\\/");
		writeToFile(testClassCode, testClassParentFolder,
				"ExecutionTraceSimulation" + fileNameAndId.getValue() + ".java");
		logger.log(Level.INFO, "Test generation has been finished.");
	}

	private Entry<String, Integer> saveModel(ExecutionTrace traceModel, Entry<String, Integer> fileNameAndId)
			throws CoreException, IOException {
		try {
			// Trying to serialize the model
			serialize(traceModel, getController().getTraceFolder(), fileNameAndId.getKey());
		} catch (Exception e) {
			e.printStackTrace();
			logger.log(Level.SEVERE, e.getMessage() + System.lineSeparator() +
				"Possibly you have two more model elements with the same name specified in the previous error message.");
			new File(getController().getTraceFolder() + File.separator + fileNameAndId.getKey()).delete();
			// Saving like an EMF model
			fileNameAndId = getController().getFileName("gtr");
			serialize(traceModel, getController().getTraceFolder(), fileNameAndId.getKey());
		}
		return fileNameAndId;
	}
	
	private void serialize(EObject rootElem, String parentFolder, String fileName) throws IOException {
		TraceLanguageSerializer serializer = new TraceLanguageSerializer();
		serializer.serialize(rootElem, parentFolder, fileName);
   }
	
	@Override
	protected void process(final List<Boolean> chunks) {}
	
	/**
	 * Cancels this particular Verifier object.
	 */
	public boolean cancelProcess(boolean mayInterrupt) {
		isCancelled = true;
		if (verifier != null) {
			verifier.cancel();
		}
		return super.cancel(mayInterrupt);
	}
	
	public boolean isProcessCancelled() {
		return isCancelled;
	}
	 
	@Override
	protected void done() {
		try {
			if (contributeToView) {
				ThreeStateBoolean result = get();
				if (!isCancelled) {
					if (result == ThreeStateBoolean.TRUE) {
						view.setVerificationLabelToTrue();
					}
					else if (result == ThreeStateBoolean.FALSE) {
						view.setVerificationLabelToFalse();
					}
				}
			}
		} catch (ExecutionException e) {
			e.printStackTrace();
			view.handleVerificationExceptions((Exception) e.getCause());
		} catch (InterruptedException | CancellationException e) {
			// Killing the process
			cancelProcess(true);
		} finally {
			// Removing this object from the attributes
			if (getController().getVerifier() == this) {
				getController().setVerifier(null);
			}
			if (getController().getGeneratedTestVerifier() == null) {
				// Enabling the verification buttons only if it is a simple query
				view.setVerificationButtons(true);
			}
		}
	}
	
	private File writeToFile(String string, String parentFolder, String fileName) throws FileNotFoundException {
		new File(parentFolder).mkdirs(); // Creating parent folder if needed
		String fileLocation = parentFolder + File.separator + fileName;
		File file = new File(fileLocation);
		try (PrintWriter writer = new PrintWriter(fileLocation)) {
			writer.print(string);
		}
		return file;
	}
	
}