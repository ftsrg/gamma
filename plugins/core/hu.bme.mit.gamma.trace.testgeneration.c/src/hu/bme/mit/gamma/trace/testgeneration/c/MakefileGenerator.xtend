package hu.bme.mit.gamma.trace.testgeneration.c

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import org.eclipse.emf.common.util.URI
import java.io.File
import java.nio.file.Paths
import java.nio.file.Files
import hu.bme.mit.gamma.util.FileUtil

class MakefileGenerator {
	
	val FileUtil fileUtil = FileUtil.INSTANCE
	
	val URI out
	val String name
	val ExecutionTrace trace
	
	new(ExecutionTrace trace, URI out, String name) {
		this.trace = trace
		this.name = name
		this.out = out
	}
	
	def String generate() {
		return '''
			CC = gcc
			CFLAGS = -Wall -lunity -fcommon
			SOURCES = «name.toLowerCase».c «trace.component.name.toLowerCase».c «trace.component.name.toLowerCase».h «trace.component.name.toLowerCase»wrapper.c «trace.component.name.toLowerCase»wrapper.h
			OUTPUT = «name.toLowerCase».exe
			
			all: $(OUTPUT) run_tests clean
			
			$(OUTPUT): $(SOURCES)
				$(CC) -o $(OUTPUT) $(SOURCES) $(CFLAGS)
				
			run_tests: $(OUTPUT)
				./$(OUTPUT)
			
			clean:
				rm -f $(OUTPUT)
		'''
	}
	
	def save(String content) {
		/* create test-gen if not present */
		val URI testgen = out.appendSegment("test-gen")
		if (!new File(testgen.toString).exists())
			Files.createDirectories(Paths.get(testgen.toString()))
			
		/* create project folder if not present */
		val URI local = testgen.appendSegment(trace.component.name.toLowerCase)
		if (!new File(local.toString()).exists())
			Files.createDirectories(Paths.get(local.toString()))
			
		val URI fileUri = local.appendSegment("makefile")
		val File file = fileUtil.getFile(fileUri.toString())
		
		/* save generated test file */
		if (file.exists())
			fileUtil.forceDelete(file)	
		fileUtil.saveString(file, content)
	}
	
	def void execute() {
		generate.save
	}
	
}