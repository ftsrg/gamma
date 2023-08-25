/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.promela.transformation.serializer.ExpressionSerializer
import java.util.List

import static hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class ArrayHandler {
	// Singleton
	public static final ArrayHandler INSTANCE = new ArrayHandler
	protected new() {}
	
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	
	def getAllArrayTypeDefinition(List<ArrayTypeDefinition> typeDefinitions) {
		var arrayTypeDefinitions = newArrayList
		for (definitions : typeDefinitions) {
			val type = definitions.getContainerOfType(Declaration).type
			if (!arrayTypeDefinitions.contains(type)) {
				arrayTypeDefinitions += type as ArrayTypeDefinition
			}
		}
		return arrayTypeDefinitions
	}
	
	// Array serialization
	
	def String serializeArrayInit(Declaration declaration, Expression initExpression, ArrayTypeDefinition type) {
		if (initExpression instanceof ArrayLiteralExpression) {
			// Array init with an ArrayLiteralExpression
			val literals = getAllArrayLiteral(initExpression)
			val listOfIndices = getIndices(type)
			return '''
				«FOR i : 0 ..< literals.size»
					«declaration.name»«listOfIndices.get(i).serializeFullIndex» = «literals.get(i).serialize»;
				«ENDFOR»
			'''
		}
		if (initExpression instanceof ArrayAccessExpression) {
			// Array init with an other array 
			val listOfExpIndices = getIndices(initExpression)
			val listOfIndices = getIndices(type)
			return '''
				«FOR i : 0..< listOfIndices.size»
					«declaration.name»«listOfIndices.get(i).serializeFullIndex» = «initExpression.serialize»«listOfExpIndices.get(i).serializePartIndex»;
				«ENDFOR»
			'''
		}
	}
	
	// ArrayAccess serialization
	
	def String serializeFullIndex(IndexHierarchy hierarchy) '''«FOR index : hierarchy.indexes SEPARATOR arrayFieldAccess»[«index»]«ENDFOR»'''
	def String serializePartIndex(IndexHierarchy hierarchy) '''«FOR index : hierarchy.indexes»«arrayFieldAccess»[«index»]«ENDFOR»'''
	
	// Array serialization in Assignments
	
	def String serializeArrayAssignment(Expression lhs, Expression rhs) {
		val lhsType = lhs.declaration.typeDefinition
		if (lhsType instanceof ArrayTypeDefinition) {
			if (lhs instanceof ArrayAccessExpression) {
				// ArrayAccess with ArrayLiteral
				if (rhs instanceof ArrayLiteralExpression) {
					val lhsIndices = getIndices(lhs)
					val literals = getAllArrayLiteral(rhs)
					return '''
						«FOR i : 0 ..< literals.size»
							«lhs.serialize»«lhsIndices.get(i).serializePartIndex» = «literals.get(i).serialize»;
						«ENDFOR»
					'''
				}
				// ArrayAccess with ArrayAccess
				if (rhs instanceof ArrayAccessExpression) {
					if (!(maxDimension(lhs) && maxDimension(rhs))) {
						// lhs or rhs is an array
						val lhsIndices = getIndices(lhs)
						val rhsIndices = getIndices(rhs)
						return '''
							«FOR i : 0 ..< rhsIndices.size»
								«lhs.serialize»«lhsIndices.get(i).serializePartIndex» = «rhs.serialize»«rhsIndices.get(i).serializePartIndex»;
							«ENDFOR»
						'''
					}
				}
				// lhs and rhs is one-one element of an array
				return '''«lhs.serialize» = «rhs.serialize»;'''
			}
			// lhs is a DirectReferenceExpression
			return lhs.declaration.serializeArrayInit(rhs, lhsType)
		}
	}
	
	// get part of indices or full indices
	
	def getIndices(ArrayAccessExpression expression) {
		var indices = newArrayList
		val dim = expression.dimensions
		val typeDefiniton = expression.declaration.typeDefinition as ArrayTypeDefinition
		val allIndices = typeDefiniton.indices
		for (index : allIndices) {
			if (index.indexes.subList(0, dim.size).equals(dim)) {
				indices += new IndexHierarchy(
					index.indexes.subList(dim.size, index.indexes.size))
			}
		}
		return indices
	}
	
	def getIndices(ArrayTypeDefinition typeDefinition) {
		var dimensions = newArrayList
		for (definitions : ecoreUtil.getAllContentsOfType(typeDefinition, ArrayTypeDefinition)) {
			dimensions += definitions.size.evaluateInteger 
		}
		dimensions.add(0, typeDefinition.size.evaluateInteger)
		return dimensions.calcluateIndices(newArrayList)
	}
	
	// calculate the right indices
	
	def List<IndexHierarchy> calcluateIndices(List<Integer> arrayDimensions, List<Integer> acc2) {
		var list = newArrayList
        if (arrayDimensions.size() == 1) {
            for (var i = 0; i < arrayDimensions.get(0); i++) {
                var IndexHierarchy newAcc = new IndexHierarchy(acc2)
                newAcc.add(i)
                list += newAcc
            }
        }
        else {
            var temp = 1
            for (var i = 1; i < arrayDimensions.size(); i++) {
                temp *= arrayDimensions.get(i)
            }
            for (var j = 0; j < arrayDimensions.get(0); j++) {
                val newAcc = <Integer>newArrayList(acc2);
                newAcc += j
                list += arrayDimensions.subList(1, arrayDimensions.size()).calcluateIndices(newAcc);
            }
        }
        return list
    }
    
    // return list of embedded literals
	
	def List<Expression> getAllArrayLiteral(ArrayLiteralExpression literalExpression) {
		val literals = newArrayList
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
	
	// check max dimension
	
	def maxDimension(ArrayAccessExpression expression) {
		val expType = expression.declaration.typeDefinition as ArrayTypeDefinition
		return expression.dimensions.size == expType.dimensions.size
	}
	
	// number of dimensions
	
	def getDimensions(ArrayAccessExpression expression) {
		val listOfDimensions = newArrayList
		for (arrayAccessExp : ecoreUtil.getAllContentsOfType(expression, ArrayAccessExpression)) {
			listOfDimensions.add(0, arrayAccessExp.index.evaluateInteger)
		}
		listOfDimensions += expression.index.evaluateInteger
		return listOfDimensions
	}
	
	def getDimensions(ArrayTypeDefinition typeDefinition) {
		val listOfDimensions = newArrayList
		listOfDimensions += typeDefinition
		for (definition : ecoreUtil.getAllContentsOfType(typeDefinition, ArrayTypeDefinition)) {
			listOfDimensions += definition
		}
		return listOfDimensions
	}
}