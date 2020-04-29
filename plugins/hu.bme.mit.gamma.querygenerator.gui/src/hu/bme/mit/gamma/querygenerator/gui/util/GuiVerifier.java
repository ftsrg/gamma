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
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;

import com.google.inject.Injector;

import hu.bme.mit.gamma.querygenerator.application.Controller;
import hu.bme.mit.gamma.querygenerator.application.View;
import hu.bme.mit.gamma.trace.language.ui.internal.LanguageActivator;
import hu.bme.mit.gamma.trace.language.ui.serializer.TraceLanguageSerializer;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.TraceUtil;
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;
import hu.bme.mit.gamma.uppaal.verification.Verifier;
import hu.bme.mit.gamma.uppaal.verification.result.ThreeStateBoolean;

/** Runnable class responsible for the execution of formal verification. */
public class GuiVerifier extends SwingWorker<ThreeStateBoolean, Boolean> {
	// The query needs to be added to UPPAAL in addition to the model
	private String originalUppaalQueries;
	// Process running the UPPAAL verification
	private Verifier verifier;
	// Indicates whether this worker is cancelled: needed as the original isCancelled is updated late
	private volatile boolean isCancelled = false;
	// Indicates whether it should contribute to the View in any form
	private boolean contributeToView;
	
	private final View view;
	private final Controller controller;
	
	protected TraceUtil traceUtil = new TraceUtil();	
	protected Logger logger = Logger.getLogger("GammaLogger");
	
	public GuiVerifier(String uppaalQuery, boolean contributeToView, View view, Controller controller) {
		this.originalUppaalQueries = uppaalQuery;
		this.contributeToView = contributeToView;
		this.view = view;
		this.controller = controller;
	}
	
	@Override
	public ThreeStateBoolean doInBackground() throws Exception {
		try {
			// Disabling the verification buttons
			view.setVerificationButtons(false);
			// Common traceability and execution trace
			G2UTrace traceability = controller.loadTraceability();
			ExecutionTrace traceModel = null;
			// Verification starts
			verifier = new Verifier();
			traceModel = verifier.verifyQuery(traceability, controller.getParameters(),
					new File(controller.getUppaalXmlFile()), originalUppaalQueries, true, false);
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
			throw new IllegalArgumentException("Error! The generated UPPAAL file cannot be found.");
		} catch (FileNotFoundException e) {
			throw new IllegalArgumentException("Error! The generated UPPAAL file cannot be found.");
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
		Entry<String, Integer> fileNameAndId = controller.getFileName("get"); // File extension could be gtr or get
		fileNameAndId = saveModel(traceModel, fileNameAndId);
		// Have to be the SAME resource set as before (traceabilitySet) otherwise the trace model contains references to dead objects
		String packageName = controller.getProject().getName().toLowerCase();
		TestGenerator testGenerator = new TestGenerator(traceModel,
				packageName, "ExecutionTraceSimulation" + fileNameAndId.getValue());
		String testClassCode = testGenerator.execute();
		String testClassParentFolder = controller.getTestGenFolder() + "/" + 
				testGenerator.getPackageName().replaceAll("\\.", "\\/");
		writeToFile(testClassCode, testClassParentFolder,
				"ExecutionTraceSimulation" + fileNameAndId.getValue() + ".java");
		logger.log(Level.INFO, "Test generation has been finished.");
	}

	private Entry<String, Integer> saveModel(ExecutionTrace traceModel, Entry<String, Integer> fileNameAndId)
			throws CoreException, IOException {
		try {
			// Trying to serialize the model
			serialize(traceModel, controller.getTraceFolder(), fileNameAndId.getKey());
		} catch (Exception e) {
			logger.log(Level.SEVERE, e.getMessage() + System.lineSeparator() +
				"Possibly you have two more model elements with the same name specified in the previous error message.");
			new File(controller.getTraceFolder() + File.separator + fileNameAndId.getKey()).delete();
			// Saving like an EMF model
			fileNameAndId = controller.getFileName("gtr");
			serialize(traceModel, controller.getTraceFolder(), fileNameAndId.getKey());
		}
		return fileNameAndId;
	}
	
	private void serialize(EObject rootElem, String parentFolder, String fileName) throws IOException {
		// This is how an injected object can be retrieved
		Injector injector = LanguageActivator.getInstance()
				.getInjector(LanguageActivator.HU_BME_MIT_GAMMA_TRACE_LANGUAGE_TRACELANGUAGE);
		TraceLanguageSerializer serializer = injector.getInstance(TraceLanguageSerializer.class);
		serializer.save(rootElem, URI.decode(parentFolder + File.separator + fileName));
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
			if (controller.getVerifier() == this) {
				controller.setVerifier(null);
			}
			if (controller.getGeneratedTestVerifier() == null) {
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