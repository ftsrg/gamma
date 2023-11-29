package hu.bme.mit.gamma.trace.testgeneration.c.util

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.impl.ArrayLiteralExpressionImpl
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.trace.testgeneration.c.TypeSerializer
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.emf.ecore.util.EcoreUtil
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import java.util.List
import hu.bme.mit.gamma.trace.model.Act
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression

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
		return ""
	}
	
	static def int getArraySizeSum(EObject object) {
		if (!(object instanceof ArrayLiteralExpressionImpl))
			return 1;
		val array = object as ArrayLiteralExpressionImpl
		return array.operands.size * array.operands.head.arraySizeSum
	}
	
	static def boolean containsElapse(List<Act> actions) {
		return actions.stream.anyMatch[it instanceof TimeElapse]
	}
	
	static def String getRealization(Port port) {
		switch(port.interfaceRealization.realizationMode) {
		case PROVIDED:
			return 'Out'
		case REQUIRED:
			return 'In'
		default:
			return 'In'
		}
	}
	
	static def boolean isNecessary(Expression expression) {
		if (EcoreUtil2.getAllContentsOfType(expression, ComponentInstanceVariableReferenceExpression).size > 0)
			return false
		return true
	}
	
	static def boolean containsArray(Expression expression) {
		return EcoreUtil2.getAllContentsOfType(expression, ArrayLiteralExpressionImpl).size > 0
	}
	
	static def String getTestMethod(Expression expression) {
		if (expression.containsArray)
			return "TEST_ASSERT_EQUAL_INT_ARRAY"
		return "TEST_ASSERT_TRUE"
	}
	
	static def String getTestParameter(Expression expression) {
		if (expression.containsArray)
			return ''', «expression.arraySizeSum»'''
		return ''''''
	}
	
	static def boolean isComplexArray(Expression expression) {
		return expression.eContainer instanceof ArrayLiteralExpression
	}
		
}