package hu.bme.mit.gamma.trace.testgeneration.c

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.io.File
import org.eclipse.emf.common.util.URI
import java.nio.file.Files
import java.nio.file.Paths
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.impl.TimeElapseImpl
import java.util.List

class TestGenerator {
	
	val FileUtil fileUtil = FileUtil.INSTANCE
	
	val URI out
	val ExecutionTrace trace
	
	val ActSerializer actSerializer = new ActSerializer
	val ExpressionSerializer expressionSerializer = new ExpressionSerializer
	
	new(ExecutionTrace trace, URI out) {
		this.trace = trace
		this.out = out
	}
	
	def String generate() {
		val List<String> timers = newArrayList
		trace.steps.forEach[step | step.actions.forEach[action | if (action instanceof TimeElapseImpl) timers.add(expressionSerializer.serialize(action.elapsedTime, ''))]]
		
		return '''
			#include <stdio.h>
			#include <stdbool.h>
			#include <unity/unity.h>
			
			#include "«trace.component.name.toLowerCase».h"
			#include "«trace.component.name.toLowerCase»wrapper.h"
			
			/* The component under test */
			«trace.component.name.toFirstUpper»Wrapper statechart;
			
			«FOR timer : timers.toSet SEPARATOR System.lineSeparator»
				uint32_t getElapsed«timer»(«trace.component.name.toFirstUpper»Wrapper* statechart) {
					return «timer»U;
				}
			«ENDFOR»
			
			void setUp(void) {
				/* Empty  */
			}
			
			«FOR index : 0 ..< trace.steps.size SEPARATOR System.lineSeparator»
				void test_step«index»() {
					«FOR action : trace.steps.get(index).actions SEPARATOR System.lineSeparator»«actSerializer.serialize(action, trace.component.name)»«ENDFOR»
					«FOR expression : trace.steps.get(index).asserts SEPARATOR System.lineSeparator»TEST_ASSERT_TRUE(«expressionSerializer.serialize(expression, trace.component.name)»);«ENDFOR»
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
		if (!new File(testgen.toFileString).exists())
			Files.createDirectories(Paths.get(testgen.toFileString()))
			
		/* create project folder if not present */
		val URI local = testgen.appendSegment(trace.component.name.toLowerCase)
		if (!new File(local.toFileString()).exists())
			Files.createDirectories(Paths.get(local.toFileString()))
			
		val URI fileUri = local.appendSegment(trace.name + ".c")
		val File file = fileUtil.getFile(fileUri.toFileString())
		
		/* save generated test file */
		if (file.exists())
			fileUtil.forceDelete(file)	
		fileUtil.saveString(file, content)
	}
	
	def execute() {
		save(generate)
	}
	
}