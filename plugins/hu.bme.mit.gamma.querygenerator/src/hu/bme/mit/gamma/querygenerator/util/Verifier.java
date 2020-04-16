package hu.bme.mit.gamma.querygenerator.util;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map.Entry;
import java.util.Scanner;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.swing.SwingWorker;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.ResourceSet;

import com.google.inject.Injector;

import hu.bme.mit.gamma.querygenerator.application.Controller;
import hu.bme.mit.gamma.querygenerator.application.View;
import hu.bme.mit.gamma.trace.language.ui.internal.LanguageActivator;
import hu.bme.mit.gamma.trace.language.ui.serializer.TraceLanguageSerializer;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.TraceUtil;
import hu.bme.mit.gamma.uppaal.backannotation.EmptyTraceException;
import hu.bme.mit.gamma.uppaal.backannotation.StringTraceBackAnnotator;
import hu.bme.mit.gamma.uppaal.backannotation.TestGenerator;

public 	/** Runnable class responsible for the execution of formal verification. */
class Verifier extends SwingWorker<ThreeStateBoolean, Boolean> {
	// The query needs to be added to UPPAAL in addition to the model
	private String originalUppaalQueries;
	// Process running the UPPAAL verification
	private Process process;
	// Indicates whether this worker is cancelled: needed as the original isCancelled is updated late
	private volatile boolean isCancelled = false;
	// Indicates whether it should contribute to the View in any form
	private boolean contributeToView;
	
	private final View view;
	private final Controller controller;
	
	protected TraceUtil traceUtil = new TraceUtil();	
	protected Logger logger = Logger.getLogger("GammaLogger");
	
	public Verifier(String uppaalQuery, boolean contributeToView, View view, Controller controller) {
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
			ResourceSet traceabilitySet = controller.loadTraceability();
			ExecutionTrace traceModel = null;
			// Verification starts
			traceModel = verifyQuery(originalUppaalQueries, traceabilitySet);
			if (traceModel == null) {
				throw new IllegalArgumentException("None of the specified queries resulted in a trace.");
			}
			if (view.isOptimizeTestSet()) {
				// Removal of covered steps
				try {
				traceUtil.removeCoveredSteps(traceModel);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
			serializeTestCode(traceModel, traceabilitySet);
			// There is a generated trace, so the result is the opposite of the empty trace
			return handleEmptyLines(originalUppaalQueries).opposite();
		} catch (EmptyTraceException e) {
			return handleEmptyLines(originalUppaalQueries);
		} catch (NotBackannotatedException e) {
			return e.getThreeStateBoolean();
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
				IllegalArgumentException ex = new IllegalArgumentException("Error! " + e.getMessage());
				ex.initCause(e);
				throw ex;
			}
		}
	}
	
	private ExecutionTrace verifyQuery(String actualUppaalQuery, ResourceSet traceabilitySet)
			throws IOException, NotBackannotatedException, EmptyTraceException {
		Scanner resultReader = null;
		Scanner traceReader = null;
		VerificationResultReader verificationResultReader = null;
		try {
			// Writing the query to a temporary file
			File tempQueryfile = writeToFile(actualUppaalQuery, controller.getParentFolder(), ".temporary_query.q");
			// Deleting the file on the exit of the JVM
			tempQueryfile.deleteOnExit();
			// verifyta -t0 -T TestOneComponent.xml asd.q 
			StringBuilder command = new StringBuilder();
			command.append("verifyta " + controller.getParameters() + " \"" + controller.getUppaalXmlFile() + "\" \"" + tempQueryfile.getCanonicalPath() + "\"");
			// Executing the command
			logger.log(Level.INFO, "Executing command: " + command.toString());
			process =  Runtime.getRuntime().exec(command.toString());
			InputStream outputStream = process.getInputStream();
			InputStream errorStream = process.getErrorStream();
			// Reading the result of the command
			resultReader = new Scanner(outputStream);
			verificationResultReader = new VerificationResultReader(resultReader);
			verificationResultReader.start();
			traceReader = new Scanner(errorStream);
			if (isCancelled) {
				// If the process is killed, this is where it can be checked
				throw new NotBackannotatedException(ThreeStateBoolean.UNDEF);
			}
			if (!traceReader.hasNext()) {
				// No back annotation of empty lines
				throw new NotBackannotatedException(handleEmptyLines(originalUppaalQueries));
			}
			// Warning lines are now deleted if there was any
			logger.log(Level.INFO, "Resource set content for string trace back-annotation: " + traceabilitySet);
			StringTraceBackAnnotator backAnnotator = new StringTraceBackAnnotator(traceabilitySet, traceReader);
			ExecutionTrace traceModel = backAnnotator.execute();
			if (!controller.isNeedsBackAnnotation()) {
				// If back-annotation is not needed, we return after checking if it is an empty trace (watching out for warning lines)
				throw new NotBackannotatedException(handleEmptyLines(originalUppaalQueries).opposite());
			} 
			return traceModel;
		} finally {
			resultReader.close();
			traceReader.close();
			verificationResultReader.cancel();
		}
	}
	
	private void serializeTestCode(ExecutionTrace traceModel, ResourceSet traceabilitySet)
			throws CoreException, IOException, FileNotFoundException {
		Entry<String, Integer> fileNameAndId = controller.getFileName("get"); // File extension could be gtr or get
		fileNameAndId = saveModel(traceModel, fileNameAndId);
		// Have to be the SAME resource set as before (traceabilitySet) otherwise the trace model contains references to dead objects
		String packageName = controller.getProject().getName().toLowerCase();
		TestGenerator testGenerator = new TestGenerator(traceabilitySet,
				traceModel, packageName, "ExecutionTraceSimulation" + fileNameAndId.getValue());
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
	
	/**
	 * Returns the correct verification answer when there is no generated trace by the UPPAAL.
	 */
	private ThreeStateBoolean handleEmptyLines(String uppaalQuery) {
		if (uppaalQuery.startsWith("A[]") || uppaalQuery.startsWith("A<>")) {
			// In case of A, empty trace means the requirement is met
			return ThreeStateBoolean.TRUE;
		}
		// In case of E, empty trace means the requirement is not met
		return ThreeStateBoolean.FALSE;
	}
	
	@Override
	protected void process(final List<Boolean> chunks) {}
	
	/**
	 * Releases the verifyta process.
	 */
	private void destroyProcess() {
		// Killing the process
		if (process != null) {
			process.destroy();
			try {
				// Waiting for process to end
				process.waitFor();
			} catch (InterruptedException e) {}
		}
	}
	
	/**
	 * Cancels this particular Verifier object.
	 */
	public boolean cancelProcess(boolean mayInterrupt) {
		isCancelled = true;
		destroyProcess();
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
			destroyProcess();
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