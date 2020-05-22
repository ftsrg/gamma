package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.Copier

import static com.google.common.base.Preconditions.checkState

class ExpressionTransformer {
	// Trace needed for variable references
	protected final Trace trace
	// Auxiliary objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	
	new(Trace trace) {
		this.trace = trace
	}
	
	def dispatch Expression transformExpression(NullaryExpression expression) {
		return expression.clone
	}
	
	def dispatch Expression transformExpression(UnaryExpression expression) {
		return expression.clone => [
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
		checkState(expression.declaration instanceof VariableDeclaration)
		val declaration = expression.declaration as VariableDeclaration
		return expression.clone => [
			it.declaration = trace.getXStsVariable(declaration)
		]
	}
	
	def dispatch Expression transformExpression(BinaryExpression expression) {
		return expression.clone => [
			it.leftOperand = expression.leftOperand.transformExpression
			it.rightOperand = expression.rightOperand.transformExpression
		]
	}
	
	def dispatch Expression transformExpression(MultiaryExpression expression) {
		val newExpression = expression.clone
		newExpression.operands.clear
		for (containedExpression : expression.operands) {
			newExpression.operands += containedExpression.transformExpression
		}
		return newExpression
	}
	
	def dispatch Type transformType(Type type) {
		return type.clone
	}
	
	def dispatch Type transformType(TypeReference type) {
		val lowlevelTypeDeclaration = type.reference
		checkState(trace.getXStsTypeDeclaration(lowlevelTypeDeclaration) !== null)
		val xStsTypeDeclaration = trace.getXStsTypeDeclaration(lowlevelTypeDeclaration)
		return createTypeReference => [
			it.reference = xStsTypeDeclaration
		]
	}
	
	protected def <T extends EObject> T clone(T element) {
		// A new copier should be used every time, otherwise anomalies happen (references are changed without asking)
		val copier = new Copier(true, true)
		val clone = copier.copy(element) as T
		copier.copyReferences()
		return clone
	}
	
}