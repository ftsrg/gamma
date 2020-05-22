package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.xsts.model.model.Action
import hu.bme.mit.gamma.xsts.model.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.model.SequentialAction
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.Copier

class ActionToExpressionTransformer {
	// Logger for indicating some strange or unnecessary elements, e.g., EmptyActions
	protected final Logger logger = Logger.getLogger("GammaLogger");
	// Model factory
	protected final extension ExpressionModelFactory constraintModelFactory = ExpressionModelFactory.eINSTANCE
	
	def transform(Action action) {
		action.transformAction
	}
	
	protected def dispatch Expression transformAction(EmptyAction action) {
		logger.log(Level.WARNING, "Empty action is present.")
		return createTrueExpression
	}
	
	protected def dispatch Expression transformAction(AssignmentAction action) {
		return createEqualityExpression => [
			it.leftOperand = action.lhs.clone
			it.rightOperand = action.rhs.clone
		]
	}
	
	protected def dispatch Expression transformAction(AssumeAction action) {
		return action.assumption.clone
	}
	
	protected def dispatch Expression transformAction(ParallelAction action) {
		throw new UnsupportedOperationException("Parallel actions are not yet supported: " + action)
	}
	
	protected def dispatch Expression transformAction(SequentialAction action) {
		val andExpression = createAndExpression
		for (containedXStsAction : action.actions) {
			andExpression.operands += containedXStsAction.transformAction
		}
		return andExpression
	}
	
	protected def dispatch Expression transformAction(NonDeterministicAction action) {
		val xorExpression = createXorExpression
		for (containedXStsAction : action.actions) {
			xorExpression.operands += containedXStsAction.transformAction
		}
		return xorExpression
	}
	
	// Clone
	
	private def <T extends EObject> T clone(T element) {
		/* A new copier should be used every time, otherwise anomalies happen
		 (references are changed without asking) */
		val copier = new Copier(true, true)
		val clone = copier.copy(element) as T;
		copier.copyReferences();
		return clone;
	}
	
}