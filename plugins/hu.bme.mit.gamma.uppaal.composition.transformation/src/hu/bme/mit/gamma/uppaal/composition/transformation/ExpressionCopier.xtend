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

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.util.EcoreUtil.Copier
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.expressions.ArithmeticExpression
import uppaal.expressions.AssignmentExpression
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
import uppaal.templates.Synchronization
import uppaal.templates.TemplatesPackage

/**
 * This class is responsible for copying a tree of expressions.
 */
class ExpressionCopier {
    
	final extension IModelManipulations manipulation	 
    // Factories
    final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
    final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
    // Trace
	final extension Trace traceModel
	
	new(IModelManipulations manipulation, Trace traceModel) {
		this.manipulation = manipulation
		this.traceModel = traceModel
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
		if (object.synchronization !== null) {
			edgeClone.synchronization = object.synchronization.clone(true, true)
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
	
	def helperEquals(EObject lhs, EObject rhs) {
		val helperEquals = new EqualityHelper
		return helperEquals.equals(lhs, rhs)
	}
	
}
	