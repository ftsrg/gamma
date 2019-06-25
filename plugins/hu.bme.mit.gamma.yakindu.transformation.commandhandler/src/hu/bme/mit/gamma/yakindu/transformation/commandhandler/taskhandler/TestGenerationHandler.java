package hu.bme.mit.gamma.yakindu.transformation.commandhandler.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.logging.Level;

import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.uppaal.backannotation.TestGenerator;
import hu.bme.mit.gamma.yakindu.genmodel.ProgrammingLanguage;
import hu.bme.mit.gamma.yakindu.genmodel.TestGeneration;

public class TestGenerationHandler extends TaskHandler {

	public void execte(TestGeneration testGeneration, String packageName) throws IOException {
		checkArgument(testGeneration.getLanguage().size() == 1, 
				"A single programming language must be specified: " + testGeneration.getLanguage());
		checkArgument(testGeneration.getLanguage().get(0) == ProgrammingLanguage.JAVA, 
				"Currently only Java is supported.");
		setTestGeneration(testGeneration, packageName);
		ExecutionTrace executionTrace = testGeneration.getExecutionTrace();
		ResourceSet testGenerationResourceSet = new ResourceSetImpl();
		testGenerationResourceSet.getResource(testGeneration.eResource().getURI(), true);
		logger.log(Level.INFO, "Resource set content for test generation: " + testGenerationResourceSet);
		TestGenerator testGenerator = new TestGenerator(testGenerationResourceSet, executionTrace,
				testGeneration.getPackageName().get(0), testGeneration.getFileName().get(0));
		String testClass = testGenerator.execute();
		saveCode(targetFolderUri + File.separator + testGenerator.getPackageName().replaceAll("\\.", "/"),
				testGeneration.getFileName().get(0) + ".java", testClass);
		
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
