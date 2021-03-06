package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.SelectExpression
import hu.bme.mit.gamma.expression.util.ExpressionUtil

class NameProvider {
	
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	
	String name = ""
	
	new(FunctionAccessExpression obj) {
		// myFunc_12341
		name = ((obj.operand as DirectReferenceExpression).declaration as FunctionDeclaration).name + "_" + obj.hashCode
	}
	
	new(SelectExpression obj) {
		//selectVariable_1234
		name = "selectVariable" + "_" + obj.hashCode
	}
	
	def String getName() {
		return name
	}
	
}