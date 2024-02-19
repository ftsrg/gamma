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

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.util.FileUtil
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import java.util.List
import org.eclipse.emf.common.util.URI

class MakefileGenerator {
	static val String ENV_NAME = "unity"
	
	val FileUtil fileUtil = FileUtil.INSTANCE
	
	val URI out
	val Component component
	val List<ExecutionTrace> traces
	
	new(ExecutionTrace trace, URI out) {
		this(#[trace], out)
	}
	
	new(List<ExecutionTrace> traces, URI out) {
		if (traces.size == 0) {
			throw new IllegalArgumentException('At least one trace is required.')
		}
		this.component = traces.get(0).component
		this.traces = traces
		this.out = out
	}
	
	//
	
	def String generate() {
		return '''
			CC = gcc
			CFLAGS = -Wall -lunity -fcommon «IF System.getenv(ENV_NAME) !== null»-L«System.getenv(ENV_NAME)»«ENDIF»
			SOURCES = «component.name.toLowerCase».c «component.name.toLowerCase».h «component.name.toLowerCase»wrapper.c «component.name.toLowerCase»wrapper.h
			TESTS = «traces.map[it.name].join('.c ')»
			OUTPUT = «component.name.toLowerCase».exe
			
			all: «traces.map[it.name].join(' ')»
			
			«FOR trace : traces SEPARATOR System.lineSeparator»
				«trace.name»: $(SOURCES)
					$(CC) -o $(OUTPUT) «trace.name».c $(SOURCES) $(CFLAGS)
					./$(OUTPUT)
					rm -f $(OUTPUT)
			«ENDFOR»
			
		'''
	}
	
	def save(String content) {
		/* create test-gen if not present */
//		val URI testgen = out.appendSegment("test-gen")
//		if (!new File(testgen.toString).exists) {
//			Files.createDirectories(Paths.get(testgen.toString))
//		}
			
		/* create project folder if not present */
		val URI local = out.appendSegment(component.name.toLowerCase)
		if (!new File(local.toString).exists) {
			Files.createDirectories(Paths.get(local.toString))
		}
			
		val URI fileUri = local.appendSegment("makefile")
		val File file = fileUtil.getFile(fileUri.toString)
		
		/* save generated test file */
		if (file.exists()) {
			fileUtil.forceDelete(file)
		}
			
		fileUtil.saveString(file, content)
	}
	
	def void execute() {
		generate.save
	}
	
}