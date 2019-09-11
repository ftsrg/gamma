package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.MessageQueue
import hu.bme.mit.gamma.uppaal.transformation.queries.ExpressionTraces
import hu.bme.mit.gamma.uppaal.transformation.queries.InstanceTraces
import hu.bme.mit.gamma.uppaal.transformation.queries.MessageQueueTraces
import hu.bme.mit.gamma.uppaal.transformation.queries.PortTraces
import hu.bme.mit.gamma.uppaal.transformation.queries.Traces
import hu.bme.mit.gamma.uppaal.transformation.traceability.AbstractTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.ExpressionTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.InstanceTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.MessageQueueTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import java.util.HashSet
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.FunctionDeclaration
import uppaal.declarations.VariableDeclaration
import uppaal.expressions.BinaryExpression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.MinusExpression
import uppaal.expressions.NegationExpression
import uppaal.expressions.PlusExpression
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.Synchronization

class Trace {
	
	protected final ViatraQueryEngine traceEngine
	protected final G2UTrace traceRoot
	
	final extension IModelManipulations manipulation	
	
	final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	
	new(IModelManipulations manipulation, G2UTrace traceRoot) {
		this.manipulation = manipulation
		this.traceRoot = traceRoot 
		this.traceEngine = ViatraQueryEngine.on(new EMFScope(traceRoot))
	}
	
	/**
	 * Returns a Set of EObjects that are created of the given "from" object.
	 */
	def getAllValuesOfTo(EObject from) {
		return Traces.Matcher.on(traceEngine).getAllValuesOfto(null, from)
	}
	
	/**
	 * Returns a Set of EObjects that the given "to" object is created of.
	 */
	def getAllValuesOfFrom(EObject to) {
		return Traces.Matcher.on(traceEngine).getAllValuesOffrom(null, to)
	}
	
	def isTraced(EObject object) {
		return !object.allValuesOfTo.empty || 
			!ExpressionTraces.Matcher.on(traceEngine).getAllValuesOfto(null, object).empty
	}
	
	/** 
	 * Returns the ComponentInstance the given object is element of.
	 */
	def ComponentInstance getOwner(EObject object) {
		val traces = InstanceTraces.Matcher.on(traceEngine).getAllValuesOfinstance(null, object)
		if (traces.size != 1) {
			throw new IllegalArgumentException("The number of owners of this object is not one! Object: " + object + " Size: " + traces.size + " Owners: " + traces.map[it.owner])
		}
		return traces.head		
	}
	
	def getPort(VariableDeclaration variable) {
		val traces = PortTraces.Matcher.on(traceEngine).getAllValuesOfport(null, variable)
		if (traces.size != 1) {
			throw new IllegalArgumentException("The number of owners of this object is not one! Object: " + variable + " Size: " + traces.size + " Owners: " + traces.map[it.owner])
		}
		return traces.head		
	}
	
	/** 
	 * Returns the MessageQueueTrace the given queue is saved in.
	 */
	def MessageQueueTrace getTrace(MessageQueue queue, ComponentInstance owner) {
		var traces = MessageQueueTraces.Matcher.on(traceEngine).getAllValuesOftrace(queue)
		if (owner !== null) {
			traces = traces.filter[it.queue.owner === owner].toSet
		}
		if (traces.size != 1) {
			throw new IllegalArgumentException("The number of owners of this object is not one! " + traces)
		}
		return traces.head		
	}
	
	 /** 
	 * Creates a message queue trace.
	 */
	def addQueueTrace(MessageQueue queue, DataVariableDeclaration sizeConst, DataVariableDeclaration capacityVar,
		FunctionDeclaration peekFunction, FunctionDeclaration shiftFunction, FunctionDeclaration pushFunction,
		FunctionDeclaration isFullFunction, DataVariableDeclaration array) {
		traceRoot.createChild(g2UTrace_Traces, messageQueueTrace) as MessageQueueTrace => [
			it.queue = queue
			it.sizeConst = sizeConst
			it.capacityVar = capacityVar
			it.peekFunction = peekFunction
			it.shiftFunction = shiftFunction
			it.pushFunction = pushFunction
			it.isFullFunction = isFullFunction
			it.array = array
		]
	}
	
	/**
	 * Responsible for putting the "from" -> "to" mapping into a trace. If the "from" object is already in
	 * another trace object, it is fetched and it will contain the "to" object as well.
	 */
	def addToTrace(EObject from, Set<EObject> to, EClass traceClass) {
		// So from values will not be duplicated if they are already present in the trace model
		var AbstractTrace aTrace 
		switch (traceClass) {
			case instanceTrace: {
				val instance = from as ComponentInstance
				aTrace = InstanceTraces.Matcher.on(traceEngine).getAllValuesOftrace(instance, null).head
			}
			case portTrace: {
				val port = from as Port
				aTrace = PortTraces.Matcher.on(traceEngine).getAllValuesOftrace(port, null).head
			}
			case expressionTrace: 
				aTrace = ExpressionTraces.Matcher.on(traceEngine).getAllValuesOftrace(from, null).head
			case trace: 
				aTrace = Traces.Matcher.on(traceEngine).getAllValuesOftrace(from, null).head 
		}
		// Otherwise a new trace object is created
		if (aTrace === null) {
			aTrace = traceRoot.createChild(g2UTrace_Traces, traceClass) as AbstractTrace
			switch (traceClass) {
				case instanceTrace: 			
					aTrace.set(instanceTrace_Owner, from)
				case portTrace: 
					aTrace.set(portTrace_Port, from)
				case expressionTrace: 			
					aTrace.addTo(expressionTrace_From, from)
				case trace: 
					aTrace.addTo(trace_From, from)
			}
		}
		val AbstractTrace finalTrace = aTrace
		switch (traceClass) {
				case instanceTrace: 			
					to.forEach[finalTrace.addTo(instanceTrace_Element, it)]
				case portTrace: 
					to.forEach[finalTrace.addTo(portTrace_Declarations, it)]
				case expressionTrace: 			
					to.forEach[finalTrace.addTo(expressionTrace_To, it)]
				case trace: 
					to.forEach[finalTrace.addTo(trace_To, it)]
		}
		return finalTrace
	}
	
	def addToTraceTo(EObject oldRef, EObject newRef) {
		for	(oldTrace : Traces.Matcher.on(traceEngine).getAllValuesOftrace(null, oldRef)) { // Always one trace
			if (oldTrace.from.size > 1) {
				throw new Exception("The OldTrace contains more than one reference.")
			}
			val from = oldTrace.from.head
			addToTrace(from, #{newRef}, trace)		
		}	
	}
	
	def addToExpressionTraceTo(EObject oldRef, EObject newRef) {
		for	(oldTrace : ExpressionTraces.Matcher.on(traceEngine).getAllValuesOftrace(null, oldRef)) { // Always one trace
			if (oldTrace.from.size > 1) {
				throw new Exception("The OldTrace contains more than one reference.")
			}
			val from = oldTrace.from.head
			addToTrace(from, #{newRef}, expressionTrace)		
		}		
	}
	
	def removeFromTraces(EObject object) {
		val traces = newHashSet
		traces += Traces.Matcher.on(traceEngine).getAllValuesOftrace(null, object)
		for	(oldTrace : traces) { // Always one trace
			val traceRoot = oldTrace.eContainer as G2UTrace
			if (oldTrace.to.size > 1) {
				oldTrace.remove(trace_To, object)
			}
			else {
				traceRoot.traces.remove(oldTrace)
			}		
		}
		val expTraces = new HashSet<ExpressionTrace>(ExpressionTraces.Matcher.on(traceEngine).getAllValuesOftrace(null, object).toSet)
		for	(oldTrace : expTraces) { // Always one trace
			val traceRoot = oldTrace.eContainer as G2UTrace
			if (oldTrace.to.size > 1) {
				oldTrace.remove(expressionTrace_To, object)
			}
			else {
				traceRoot.traces.remove(oldTrace)
			}		
		}
		val instanceTraces = new HashSet<InstanceTrace>(InstanceTraces.Matcher.on(traceEngine).getAllValuesOftrace(null, object).toSet)
		for	(oldTrace : instanceTraces) { // Always one trace
			val traceRoot = oldTrace.eContainer as G2UTrace
			if (oldTrace.element.size > 1) {
				oldTrace.remove(instanceTrace_Element, object)
			}
			else {
				traceRoot.traces.remove(oldTrace)
			}		
		}
	}	
	
	def dispatch void removeTrace(EObject object) {
		throw new IllegalArgumentException("This object cannot be removed from trace: " + object)
	}
	
	def dispatch void removeTrace(Edge edge) {
		if (edge.synchronization !== null) {
			edge.synchronization.removeTrace		
		}
		if (edge.guard !== null) {
			edge.guard.removeTrace		
		}
		edge.update.forEach[it.removeTrace]
		edge.removeFromTraces
	}
	
	def dispatch void removeTrace(Location object) {
		if (object.invariant !== null) {
			object.invariant.removeTrace
		}
		object.removeFromTraces
	}
	
	def dispatch void removeTrace(Synchronization object) {
		object.channelExpression.removeTrace
		object.removeFromTraces
	}
	
	def dispatch void removeTrace(BinaryExpression object) {
		object.firstExpr.removeTrace
		object.secondExpr.removeTrace
		object.removeFromTraces
	}
	
	def dispatch void removeTrace(IdentifierExpression object) {
		object.removeFromTraces
	}
	
	def dispatch void removeTrace(NegationExpression object) {
		object.negatedExpression.removeTrace
		object.removeFromTraces
	}
	
	def dispatch void removeTrace(PlusExpression object) {
		object.confirmedExpression.removeTrace
		object.removeFromTraces
	}
	
	def dispatch void removeTrace(MinusExpression object) {
		object.invertedExpression.removeTrace
		object.removeFromTraces
	}
	
	def dispatch void removeTrace(LiteralExpression object) {
		object.removeFromTraces
	}
	
}