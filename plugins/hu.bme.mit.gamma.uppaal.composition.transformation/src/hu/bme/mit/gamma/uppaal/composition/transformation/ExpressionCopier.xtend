/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.uppaal.transformation.queries.ExpressionTraces
import hu.bme.mit.gamma.uppaal.transformation.queries.InstanceTraces
import hu.bme.mit.gamma.uppaal.transformation.queries.Traces
import hu.bme.mit.gamma.uppaal.transformation.traceability.ExpressionTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.InstanceTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.Trace
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import java.util.HashSet
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.util.EcoreUtil.Copier
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.expressions.ArithmeticExpression
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.BinaryExpression
import uppaal.expressions.BitShiftExpression
import uppaal.expressions.BitwiseExpression
import uppaal.expressions.CompareExpression
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.IncrementDecrementExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.MinusExpression
import uppaal.expressions.NegationExpression
import uppaal.expressions.PlusExpression
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.Synchronization
import uppaal.templates.TemplatesPackage

/**
 * This class is responsible for copying a tree of expressions.
 */
class ExpressionCopier {
	
	protected ViatraQueryEngine traceEngine
    protected G2UTrace traceRoot
    
	extension IModelManipulations manipulation	 
    
    extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
    extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
    extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
    
	extension ExpressionTransformer expTransf

	new(IModelManipulations manipulation, G2UTrace traceRoot, ViatraQueryEngine traceEngine, ExpressionTransformer expTransf) {
		this.manipulation = manipulation
		this.traceRoot = traceRoot 
		this.traceEngine = traceEngine
		this.expTransf = expTransf
	}
	
	private def addToTraceTo(EObject oldRef, EObject newRef) {
		for	(oldTrace : Traces.Matcher.on(traceEngine).getAllValuesOftrace(null, oldRef)) { // Always one trace
			if (oldTrace.from.size > 1) {
				throw new Exception("The OldTrace contains more than one reference.")
			}
			val from = oldTrace.from.head
			addToTrace(from, #{newRef}, trace)		
		}	
	}
	
	private def addToExpressionTraceTo(EObject oldRef, EObject newRef) {
		for	(oldTrace : ExpressionTraces.Matcher.on(traceEngine).getAllValuesOftrace(null, oldRef)) { // Always one trace
			if (oldTrace.from.size > 1) {
				throw new Exception("The OldTrace contains more than one reference.")
			}
			val from = oldTrace.from.head
			addToTrace(from, #{newRef}, expressionTrace)		
		}		
	}
	
	def removeFromTraces(EObject object) {
		val traces = new HashSet<Trace>(Traces.Matcher.on(traceEngine).getAllValuesOftrace(null, object).toSet)
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
	
	
	def EObject copySync(EObject container, EReference reference, Synchronization sync) {
		container.createChild(reference, synchronization) as Synchronization => [
			it.kind = sync.kind
			it.copy(synchronization_ChannelExpression, sync.channelExpression)
		]
	}
	
	/**
	 * EcoreUtil copy.
	 */
	def <T extends EObject> T clone(T model, boolean a, boolean b) {
		// A new copier should be user every time, otherwise anomalies happen (references are changed without asking)
		val copier = new Copier(a, b)
		val clone = copier.copy(model);
		copier.copyReferences();
		return clone as T;
	}	
	
	def dispatch EObject clone(EObject object) {
		throw new IllegalArgumentException("Not supported container: " + object)
	}	
	
	def dispatch EObject clone(Edge object) {
		val container = object.parentTemplate
		val edgeClone = container.createChild(template_Edge, edge) as Edge => [
			it.source = object.source
			it.target = object.target
		]
		if (object.guard !== null) {
			edgeClone.copy(edge_Guard, object.guard)
		}
		if (object.update !== null) {
			for (update : object.update) {
				edgeClone.copy(edge_Update, update)
			}		
		}
		object.addToTraceTo(edgeClone)
		return edgeClone
	}
	
	def dispatch EObject copy(EObject container, EReference reference, Expression expression) {
		throw new IllegalArgumentException("Not know expression: " + expression)
	}
	
	def dispatch EObject copy(EObject container, EReference reference, LiteralExpression expression) {
		val newExp = container.createChild(reference, literalExpression) as LiteralExpression => [
			it.text = expression.text
		]
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, IdentifierExpression expression) {
		val newExp = container.createChild(reference, identifierExpression) as IdentifierExpression
		newExp.identifier = expression.identifier
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	private def void copyBinaryExpressions(EObject container, Expression lhs, Expression rhs) {
		container.copy(binaryExpression_FirstExpr, lhs)
		container.copy(binaryExpression_SecondExpr, rhs)
	}
	
	def dispatch EObject copy(EObject container, EReference reference, AssignmentExpression expression) {
		val newExp = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.operator = expression.operator			
		]
		newExp.copyBinaryExpressions(expression.firstExpr, expression.secondExpr)
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, NegationExpression expression) {
		val newExp = container.createChild(reference, negationExpression) as NegationExpression => [
			it.copy(negationExpression_NegatedExpression, expression.negatedExpression)	
		]
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, PlusExpression expression) {
		val newExp = container.createChild(reference, plusExpression) as PlusExpression => [
			it.copy(negationExpression_NegatedExpression, expression.confirmedExpression)	
		]
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, MinusExpression expression) {
		val newExp = container.createChild(reference, minusExpression) as MinusExpression => [
			it.copy(negationExpression_NegatedExpression, expression.invertedExpression)	
		]
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, ArithmeticExpression expression) {
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = expression.operator			
		]
		newExp.copyBinaryExpressions(expression.firstExpr, expression.secondExpr)
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, LogicalExpression expression) {
		val newExp = container.createChild(reference, logicalExpression) as LogicalExpression => [
			it.operator = expression.operator			
		]
		newExp.copyBinaryExpressions(expression.firstExpr, expression.secondExpr)
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, CompareExpression expression) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = expression.operator			
		]
		newExp.copyBinaryExpressions(expression.firstExpr, expression.secondExpr)
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, IncrementDecrementExpression expression) {
		val newExp = container.createChild(reference, incrementDecrementExpression) as IncrementDecrementExpression => [
			it.operator = expression.operator
			it.position = expression.position			
			it.copy(negationExpression_NegatedExpression, expression.expression)	
		]
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, BitShiftExpression expression) {
		val newExp = container.createChild(reference, bitShiftExpression) as BitShiftExpression => [
			it.operator = expression.operator			
		]
		newExp.copyBinaryExpressions(expression.firstExpr, expression.secondExpr)
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
	def dispatch EObject copy(EObject container, EReference reference, BitwiseExpression expression) {
		val newExp = container.createChild(reference, bitwiseExpression) as BitwiseExpression => [
			it.operator = expression.operator			
		]
		newExp.copyBinaryExpressions(expression.firstExpr, expression.secondExpr)
		expression.addToExpressionTraceTo(newExp)
		return newExp
	}
	
}
	