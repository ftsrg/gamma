package hu.bme.mit.gamma.trace.testgeneration.c.util

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.impl.ArrayLiteralExpressionImpl
import hu.bme.mit.gamma.trace.testgeneration.c.TypeSerializer
import org.eclipse.emf.ecore.EObject

class TestGeneratorUtil {
	
	static val TypeSerializer typeSerializer = new TypeSerializer
	
	static def String getArrayType(EObject expression) {
		if (expression instanceof ArrayLiteralExpressionImpl)
			return expression.operands.head.arrayType
		return '''«typeSerializer.serialize(expression as Expression, "")»'''
	}
	
	static def String getArraySize(EObject array) {
		if (array instanceof ArrayLiteralExpressionImpl)
			return '''[«array.operands.size»]«array.operands.head.arraySize»'''
		return ''''''
	}
		
}