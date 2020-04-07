package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.Clock
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueuesOfClocks
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.WrapperInEvents
import hu.bme.mit.gamma.uppaal.transformation.traceability.ClockRepresentation
import hu.bme.mit.gamma.uppaal.transformation.traceability.EventRepresentation
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.NTA
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.DeclarationsPackage
import uppaal.declarations.ExpressionInitializer
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.LiteralExpression

import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class AsynchronousConstantsCreator {
	// NTA target model
	final NTA target
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	protected final extension IModelManipulations manipulation
	// UPPAAL packages
	protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	// Trace
	protected final extension Trace modelTrace
	// Auxiliary objects
	protected final extension NtaBuilder ntaBuilder
	// Constant val
	var constantVal = 1 // // Starting from 1, as 0 means empty
	// Rules
	protected BatchTransformationRule<WrapperInEvents.Match, WrapperInEvents.Matcher> eventConstantsRule
	protected BatchTransformationRule<QueuesOfClocks.Match, QueuesOfClocks.Matcher> clockConstantsRule
	
	new(NtaBuilder ntaBuilder, IModelManipulations manipulation, Trace modelTrace) {
		this.target = ntaBuilder.nta
		this.ntaBuilder = ntaBuilder
		this.manipulation = manipulation
		this.modelTrace = modelTrace
	}
	
	def getEventConstantsRule() {
		if (eventConstantsRule === null) {
			eventConstantsRule = createRule(WrapperInEvents.instance).action [
				it.event.createConstRepresentation(it.port, it.wrapper)
			].build
		}
		return eventConstantsRule
	}
	
	def getClockConstantsRule() {
		if (clockConstantsRule === null) {
			clockConstantsRule = createRule(QueuesOfClocks.instance).action [
				it.clock.createConstRepresentation(it.wrapper)
			].build
		}
		return clockConstantsRule
	}
	
	/**
	 * Creates the Uppaal const representing the given signal.
	 */
	protected def createConstRepresentation(Event event, Port port, AsynchronousAdapter wrapper) {
			val name = event.getConstRepresentationName(port)
			event.createConstRepresentation(port, wrapper, name, constantVal++)
	}
	
	protected def createConstRepresentation(Clock clock, AsynchronousAdapter wrapper) {
			val name = clock.getConstRepresentationName
			clock.createConstRepresentation(wrapper, name, constantVal++)
	}
	
	protected def createConstRepresentation(Event event, Port port, AsynchronousAdapter wrapper, String name, int value) {
		// Only one constant for the same port-event pairs, hence the filtering
		var DataVariableDeclaration constRepr =	target.globalDeclarations.declaration
			.filter(DataVariableDeclaration).filter[it.prefix == DataVariablePrefix.CONST && it.variable.head.name == name].head
		if (constRepr === null) {
			constRepr = target.globalDeclarations.createVariable(DataVariablePrefix.CONST, target.int, name)
			constRepr.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
				it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
					it.text = value.toString
				]
			]		
		}
		val repr = constRepr
		traceRoot.createChild(g2UTrace_Traces, eventRepresentation) as EventRepresentation => [
			it.wrapper = wrapper
			it.port = port
			it.event = event
			it.constantRepresentation = repr			
		]		
	}
	
	protected def createConstRepresentation(Clock clock, AsynchronousAdapter wrapper, String name, int value) {
		// Only one constant for the same port-event pairs, hence the filtering
		var DataVariableDeclaration constRepr =	target.globalDeclarations.declaration
			.filter(DataVariableDeclaration).filter[it.prefix == DataVariablePrefix.CONST && it.variable.head.name == name].head
		if (constRepr === null) {
			constRepr = target.globalDeclarations.createVariable(DataVariablePrefix.CONST, target.int, name)
			constRepr.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
				it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
					it.text = value.toString
				]
			]
		}
		val repr = constRepr
		traceRoot.createChild(g2UTrace_Traces, clockRepresentation) as ClockRepresentation => [
			it.wrapper = wrapper
			it.clock = clock
			it.constantRepresentation = repr
		]		
	}
	
}