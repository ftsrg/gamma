package hu.bme.mit.gamma.statechart.contract.testgeneration.java

import hu.bme.mit.gamma.codegenerator.java.util.CodeGeneratorUtil
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.querygenerator.QueryGenerator
import hu.bme.mit.gamma.querygenerator.TemporalOperator
import hu.bme.mit.gamma.statechart.contract.tracegeneration.StatechartContractToTraceTransformer
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.contract.AdaptiveContractAnnotation
import hu.bme.mit.gamma.statechart.model.contract.StateContractAnnotation
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.DefaultCompositionToUppaalTransformer
import hu.bme.mit.gamma.uppaal.verification.Verifier
import java.io.File
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartToTestTransformer {
	
	val queryParameters = "-C -t1"
	
	extension CodeGeneratorUtil codeGeneratorUtil = new CodeGeneratorUtil
	extension StatechartUtil statechartUtil = new StatechartUtil
	
	def execute(StatechartDefinition statechart, File containingFile, File testFolder, String basePackageName) {
		execute(statechart, #[], containingFile, testFolder, basePackageName, null)
	}
	
	def execute(StatechartDefinition statechart, List<Expression> arguments, File containingFile,
			File testFolder, String basePackageName, String fileName) {
		val adaptiveContractAnnotation = statechart.annotation as AdaptiveContractAnnotation
		var id = 0
		// Transforming the statechart to UPPAAL
		val uppaalTransformer = new DefaultCompositionToUppaalTransformer
		val uppaalResult = uppaalTransformer.transformComponent(statechart.containingPackage, arguments, containingFile)
		val uppaalTraceability = uppaalResult.key
		val traceabilityResourceSet = uppaalTraceability.eResource.resourceSet
		val newPackage = uppaalTraceability.gammaPackage
		val newStatechart = newPackage.components.filter(StatechartDefinition).head
		val uppaalFile = uppaalResult.value.key
		
		// Getting traces from the simple states
		val instances = newStatechart.referencingComponentInstances.filter(SynchronousComponentInstance)
		checkState(instances.size == 1)
		val instance = instances.head		
		for (simpleState : statechart.allStates.filter[!it.isComposite]) {
			// Getting traces to the simple states
			val queryGenerator = new QueryGenerator(traceabilityResourceSet)
			val stateName = queryGenerator.getStateName(instance, simpleState.parentRegion, simpleState)
			val uppaalQuery =  queryGenerator.parseRegular('''E<> («stateName») && isStable''', TemporalOperator.MIGHT_EVENTUALLY)
			val verifier = new Verifier
			val simpleStateExecutionTrace = verifier.verifyQuery(traceabilityResourceSet, queryParameters,
				uppaalFile, uppaalQuery, true, false)
			
			simpleStateExecutionTrace => [
				it.import = adaptiveContractAnnotation.monitoredComponent.containingPackage
				it.component = adaptiveContractAnnotation.monitoredComponent
				// No arguments supported yet
			]
			
			// Transforming traces from the referenced statecharts
			val contractStates = newArrayList(simpleState)
			contractStates += simpleState.ancestors
			val contractStatecharts = newArrayList
			contractStatecharts += contractStates.map[it.annotation].filter(StateContractAnnotation)
				.map[it.contractStatecharts].flatten.toSet
			
			val finalTraces = newArrayList
			val contractToTraceTransformer = new StatechartContractToTraceTransformer
			for (contractStatechart : contractStatecharts) {
				val contractTraces = contractToTraceTransformer.execute(newStatechart)
				for (contractTrace : contractTraces) {
					val finalTrace = simpleStateExecutionTrace.clone(true, true)
					finalTrace.steps += contractTrace.steps
					finalTraces += finalTrace
				}
				// Generating tests
				val className = '''«IF fileName === null»«simpleState.name.toFirstUpper»«contractStatechart.name.toFirstUpper»ExecutionTrace«id++»«ELSE»«fileName»«ENDIF»'''
				val testGenerator = new TestGenerator(traceabilityResourceSet, finalTraces,
					className, basePackageName)
				val testClass = testGenerator.execute
				val testClassFile = getFile(testFolder, testGenerator.packageName, className)
				testClassFile.saveString(testClass)
			}
		}
	}
	
}