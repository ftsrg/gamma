package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import java.util.List
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import java.util.HashMap
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import java.util.ArrayList
import hu.bme.mit.gamma.expression.util.ExpressionUtil

class ArrayHandler {
	// Singleton
	public static final ArrayHandler INSTANCE = new ArrayHandler
	protected new() {}
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	
	protected HashMap<String, HashMap<Integer, IndexHierarchy>> arrays = newHashMap
	
	def addArray(ArrayTypeDefinition typeDefinition, String name) {
		var dimensions = newArrayList
		for (definitions : ecoreUtil.getAllContentsOfType(typeDefinition, ArrayTypeDefinition)) {
			dimensions += definitions.size.evaluateInteger 
		}
		dimensions.add(0, typeDefinition.size.evaluateInteger)
		// Promela - XSTS indices
		var indices = newHashMap
		dimensions.calcluateIndices(0, newArrayList, indices)
		arrays.put(name, indices)
	}
	
	protected def void calcluateIndices(List<Integer> arrayDimensions, Integer acc, List<Integer> acc2, HashMap<Integer, IndexHierarchy> map) {
        if (arrayDimensions.size() == 1) {
            for (var i = 0; i < arrayDimensions.get(0); i++) {
                var IndexHierarchy newAcc = new IndexHierarchy(acc2)
                newAcc.add(i);
                map.put(acc + i, newAcc);
            }
        } else {
            var temp = 1;
            for (var i = 1; i < arrayDimensions.size(); i++) {
                temp *= arrayDimensions.get(i);
            }
            for (var j = 0; j < arrayDimensions.get(0); j++) {
                var ArrayList<Integer> newAcc = newArrayList(acc2);
                newAcc.add(j);
                calcluateIndices(arrayDimensions.subList(1, arrayDimensions.size()), acc + temp * j, newAcc, map);
            }
        }
    }
	
	def Integer getArraySize(ArrayTypeDefinition typeDefinition) {
		var elementType = typeDefinition.elementType
		val size = typeDefinition.size.evaluateInteger
		if (elementType instanceof ArrayTypeDefinition) {
			return size * elementType.getArraySize
		}
		return size
	}
	
	def List<Expression> getAllArrayLiteral(ArrayLiteralExpression literalExpression) {
		var literals = newArrayList
		for (operand : literalExpression.operands) {
			if (operand instanceof ArrayLiteralExpression) {
				literals += operand.allArrayLiteral
			}
			else {
				literals += operand
			}
		}
		return literals
	}
	
	def getPromelaIndex(ArrayAccessExpression expression) {
		val list = expression.getDimensions
		val name = expression.declaration.name
		val indices = arrays.get(name)
		for (index : indices.entrySet) {
			if (index.value.indexes.equals(list)) {
				return index.key
			}
		}
	}
	
	def getPromelaArrayAccess(ArrayAccessExpression expression) {
		var list = newArrayList
		list += expression
		for (arrayAccessExp : ecoreUtil.getAllContentsOfType(expression, ArrayAccessExpression)) {
			list += arrayAccessExp
		}
		return list.last.operand
	}
	
	def getIndices(ArrayAccessExpression expression) {
		var promelaIndices = newArrayList
		val list = expression.getDimensions
		val name = expression.declaration.name
		val indices = arrays.get(name)
		for (index : indices.entrySet) {
			if (index.value.indexes.subList(0, list.size).equals(list)) {
				promelaIndices += index.key
			}
		}
		return promelaIndices
	}
	
	
	//number of dimensions
	
	def getDimensions(ArrayAccessExpression expression) {
		var listOfDimensions = newArrayList
		for (arrayAccessExp : ecoreUtil.getAllContentsOfType(expression, ArrayAccessExpression)) {
			listOfDimensions.add(0, arrayAccessExp.index.evaluateInteger)
		}
		listOfDimensions += expression.index.evaluateInteger
		return listOfDimensions
	}
	
	def getDimensions(ArrayTypeDefinition typeDefinition) {
		var listOfDimensions = newArrayList
		listOfDimensions += typeDefinition
		for (definition : ecoreUtil.getAllContentsOfType(typeDefinition, ArrayTypeDefinition)) {
			listOfDimensions += definition
		}
		return listOfDimensions
	}
}