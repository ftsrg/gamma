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
package hu.bme.mit.gamma.trace.testgeneration.c

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.util.FileUtil
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import org.eclipse.emf.common.util.URI

class MakefileGenerator {
	static val String ENV_NAME = "unity"
	/* requires manual reset after the test generation has finished */
	public static val tests = newArrayList
	
	val FileUtil fileUtil = FileUtil.INSTANCE
	
	val URI out
	val String name
	val ExecutionTrace trace
	
	new(ExecutionTrace trace, URI out, String name) {
		this.trace = trace
		this.name = name
		this.out = out
		tests.add(name.toLowerCase)
	}
	
	def String generate() {
		return '''
			CC = gcc
			CFLAGS = -Wall -lunity -fcommon «IF System.getenv(ENV_NAME) !== null»-L«System.getenv(ENV_NAME)»«ENDIF»
			SOURCES = «trace.component.name.toLowerCase».c «trace.component.name.toLowerCase».h «trace.component.name.toLowerCase»wrapper.c «trace.component.name.toLowerCase»wrapper.h
			TESTS = «tests.join('.c ')»
			OUTPUT = «trace.component.name.toLowerCase».exe
			
			all: «tests.join(' ')»
			
			«FOR test : tests SEPARATOR System.lineSeparator»
				«test»: $(SOURCES)
					$(CC) -o $(OUTPUT) «test».c $(SOURCES) $(CFLAGS)
					./$(OUTPUT)
					rm -f $(OUTPUT)
			«ENDFOR»
			
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