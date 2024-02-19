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
import hu.bme.mit.gamma.trace.model.impl.TimeElapseImpl
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.VariableDeclarationSerializer
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import java.util.List
import org.eclipse.emf.common.util.URI

import static extension hu.bme.mit.gamma.trace.testgeneration.c.util.TestGeneratorUtil.*

class TestGenerator {
	
	val FileUtil fileUtil = FileUtil.INSTANCE
	
	val URI out
	val String name
	val ExecutionTrace trace
	
	val ActSerializer actSerializer = new ActSerializer
	val ExpressionSerializer expressionSerializer = new ExpressionSerializer
	val VariableDeclarationSerializer variableDeclarationSerializer = VariableDeclarationSerializer.INSTANCE
	
	new(ExecutionTrace trace, URI out, String name) {
		this.trace = trace
		this.name = name
		this.out = out
	}
	
	def String generate() {
		val List<String> timers = newArrayList
		trace.steps.forEach[step | step.actions.forEach[action | if (action instanceof TimeElapseImpl) timers.add(expressionSerializer.serialize(action.elapsedTime, ''))]]
		timers += '0' // No time elapsed
		
		return '''
			#include <stdio.h>
			#include <stdbool.h>
			#include <unity/unity.h>
			
			#include "«trace.component.name.toLowerCase».h"
			#include "«trace.component.name.toLowerCase»wrapper.h"
			
			/* The component under test */
			«trace.component.name.toFirstUpper»Wrapper statechart;
			
			«IF trace.variableDeclarations.size > 0»/* Global declarations */«ENDIF»
			«FOR declaration : trace.variableDeclarations SEPARATOR System.lineSeparator»«variableDeclarationSerializer.serialize(declaration)»«ENDFOR»
			
			«FOR timer : timers.toSet SEPARATOR System.lineSeparator»
				uint32_t getElapsed«timer»(«trace.component.name.toFirstUpper»Wrapper* statechart) {
					return «timer»U;
				}
			«ENDFOR»
			
			void setUp(void) {
				«IF trace.variableDeclarations.filter[it.expression !== null].size == 0»/* Empty */«ENDIF»
				«FOR declaration : trace.variableDeclarations.filter[it.expression !== null]»
					«declaration.name» = «expressionSerializer.serialize(declaration.expression, declaration.name)»;
				«ENDFOR»
			}
			
			«FOR index : 0 ..< trace.steps.size SEPARATOR System.lineSeparator»
				void test_step«index»() {
					«IF !trace.steps.get(index).actions.containsElapse»statechart.getElapsed = &getElapsed0;«ENDIF»
					«FOR action : trace.steps.get(index).actions SEPARATOR System.lineSeparator»«actSerializer.serialize(action, trace.component.name)»«ENDFOR»
					«FOR expression : trace.steps.get(index).asserts.filter[it.necessary] SEPARATOR System.lineSeparator»«expression.testMethod»(«expressionSerializer.serialize(expression, trace.component.name)»«expression.testParameter.toString»);«ENDFOR»
				}
			«ENDFOR»
			
			void tearDown(void) {
				/* Empty  */
			}
			
			int main() {
				UNITY_BEGIN();
				
				«FOR index : 0 ..< trace.steps.size»
					RUN_TEST(test_step«index»);
				«ENDFOR»
				
				return UNITY_END();
			}
		'''
	}
	
	def save(String content) {
		/* create test-gen if not present */
		val URI testgen = out.appendSegment("test-gen")
		if (!new File(testgen.toString()).exists())
			Files.createDirectories(Paths.get(testgen.toString()))
			
		/* create project folder if not present */
		val URI local = testgen.appendSegment(trace.component.name.toLowerCase)
		if (!new File(local.toString()).exists())
			Files.createDirectories(Paths.get(local.toString()))
			
		val URI fileUri = local.appendSegment(name.toLowerCase + ".c")
		val File file = fileUtil.getFile(fileUri.toString())
		
		/* save generated test file */
		if (file.exists())
			fileUtil.forceDelete(file)	
		fileUtil.saveString(file, content)
	}
	
	def execute() {
		save(generate)
	}
	
}