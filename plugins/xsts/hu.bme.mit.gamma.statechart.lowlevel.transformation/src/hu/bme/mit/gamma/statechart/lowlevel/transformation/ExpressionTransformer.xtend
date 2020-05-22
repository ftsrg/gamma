package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.EventParameterReferenceExpression
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.Copier

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.model.derivedfeatures.ExpressionModelDerivedFeatures.*

class ExpressionTransformer {
	// Expression factory
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
	}
	
	def dispatch Expression transformExpression(NullaryExpression expression) {
		return expression.clone
	}
	
	def dispatch Expression transformExpression(UnaryExpression expression) {
		return create(expression.eClass) as UnaryExpression => [
			it.operand = expression.operand.transformExpression
		]
	}
	
	def dispatch Expression transformExpression(IfThenElseExpression expression) {
		return createIfThenElseExpression => [
			it.condition = expression.condition.transformExpression
			it.then = expression.then.transformExpression
			it.^else = expression.^else.transformExpression
		]
	}

	// Key method
	def dispatch Expression transformExpression(ReferenceExpression expression) {
		val declaration = expression.declaration
		if (declaration instanceof ConstantDeclaration) {
			return declaration.expression.transformExpression
		}
		checkState(declaration instanceof VariableDeclaration || 
			declaration instanceof ParameterDeclaration, declaration)
		val referenceExpression = createReferenceExpression
		if (declaration instanceof VariableDeclaration) {
			checkState(trace.isMapped(declaration), declaration)
			return referenceExpression => [
				it.declaration = trace.get(declaration)
			]
		}
		else if (declaration instanceof ParameterDeclaration) {
			checkState(trace.isMapped(declaration), declaration)
			return referenceExpression => [
				it.declaration = trace.get(declaration)
			]
		}
	}
	
	// Key method
	def dispatch Expression transformExpression(EventParameterReferenceExpression expression) {
		val port = expression.port
		val event = expression.event
		val parameter = expression.parameter
		return createReferenceExpression => [
			it.declaration = trace.get(port, event, parameter).get(EventDirection.IN)
		]
	}
	
	def dispatch Expression transformExpression(BinaryExpression expression) {
		return create(expression.eClass) as BinaryExpression => [
			it.leftOperand = expression.leftOperand.transformExpression
			it.rightOperand = expression.rightOperand.transformExpression
		]
	}
	
	def dispatch Expression transformExpression(MultiaryExpression expression) {
		val newExpression = create(expression.eClass) as MultiaryExpression
		for (containedExpression : expression.operands) {
			newExpression.operands += containedExpression.transformExpression
		}
		return newExpression
	}
	
	protected def dispatch Type transformType(Type type) {
		throw new IllegalArgumentException("Not known type: " + type)
	}

	protected def dispatch Type transformType(BooleanTypeDefinition type) {
		return type.clone
	}

	protected def dispatch Type transformType(IntegerTypeDefinition type) {
		return type.clone
	}

	protected def dispatch Type transformType(DecimalTypeDefinition type) {
		return type.clone
	}
	
	protected def dispatch Type transformType(RationalTypeDefinition type) {
		return type.clone
	}
	
	protected def dispatch Type transformType(EnumerationTypeDefinition type) {
		return type.clone
	}
	
	protected def dispatch Type transformType(TypeReference type) {
		val typeDeclaration = type.reference
		val typeDefinition = typeDeclaration.type
		// Inlining primitive types
		if (typeDefinition.isPrimitive) {
			return typeDefinition.transformType
		}
		checkState(trace.isMapped(typeDeclaration))		
		return createTypeReference => [
			it.reference = trace.get(typeDeclaration)
		]
	}
	
	protected def VariableDeclaration transformVariable(VariableDeclaration variable) {
		return createVariableDeclaration => [
			it.name = variable.name
			it.type = variable.type.transformType
			it.expression = variable.expression?.transformExpression
		]
	}
	
	protected def <T extends EObject> T clone(T element) {
		// A new copier should be used every time, otherwise anomalies happen (references are changed without asking)
		val copier = new Copier(true, true)
		val clone = copier.copy(element) as T;
		copier.copyReferences();
		return clone;
	}
}