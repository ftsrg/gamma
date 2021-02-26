/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.TypeReferenceExpression
import hu.bme.mit.gamma.expression.model.AccessExpression
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DefaultExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FieldDeclaration
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RecordAccessExpression
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.SelectExpression
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.ArrayList
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension com.google.common.collect.Iterables.getOnlyElement
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class ExpressionTransformer {
	// Auxiliary object
	protected final extension TypeTransformer typeTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	// Expression factory
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	protected final boolean functionInlining
	
	new(Trace trace) {
		this(trace, true)
	}
	
	new(Trace trace, boolean functionInlining) {
		this.trace = trace
		this.functionInlining = functionInlining
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	protected def transformAnnotation(VariableDeclarationAnnotation annotation) {
		return annotation.clone
	}
	
	def dispatch List<Expression> transformExpression(NullaryExpression expression) {
		val result = <Expression>newArrayList
		result += expression.clone
		return result
	}
	
	def dispatch List<Expression> transformExpression(DefaultExpression expression) {
		val result = <Expression>newArrayList
		result += createTrueExpression
		return result
	}
	
	def dispatch List<Expression> transformExpression(FunctionAccessExpression expression) {
		val result = <Expression>newArrayList
		if (functionInlining) {
			if (trace.isMapped(expression)) {
				for (elem : trace.get(expression)) {
					result += createDirectReferenceExpression => [
						it.declaration = elem
					]
				}
			}
			else {
				throw new IllegalArgumentException(
					"Error transforming function access expression: element not found in trace!")
			}
		}
		else {
			//TODO no inlining
			throw new IllegalArgumentException("Currently only function inlining is possible!")
		}
		return result
	}
	
	def dispatch List<Expression> transformExpression(SelectExpression expression) {
		val result = <Expression>newArrayList
		if (trace.isMapped(expression)) {
			for (elem : trace.get(expression)) {
				result += createDirectReferenceExpression => [
					it.declaration = elem
				]
			}
		}
		else {
			throw new IllegalArgumentException("Error transforming select expression: element not found in trace!")
		}
		return result
	}
	
	def dispatch List<Expression> transformExpression(RecordAccessExpression expression) {
		val result = <Expression>newArrayList
		
		var originalDeclaration = expression.findDeclarationOfReferenceExpression
		if (originalDeclaration instanceof ValueDeclaration) {
			val originalLhsVariables = exploreComplexType(originalDeclaration,
				getTypeDefinitionFromType(originalDeclaration.type), newArrayList)
			val accessList = expression.collectAccessList
			val List<DirectReferenceExpression> recordAccessList =
				accessList.filter(DirectReferenceExpression).toList
	
			for (elem : originalLhsVariables) {	
				if (isSameAccessTree(elem.value, recordAccessList)) {	//filter according to the access list
					// Create references
					result += createDirectReferenceExpression => [
						it.declaration = trace.get(elem)
					]
				}
			}
		}
		// Function return variables do not exist on the high-level
		else if (originalDeclaration instanceof FunctionDeclaration) {
			var currentAccess = expression.operand as AccessExpression
			while (!(currentAccess instanceof FunctionAccessExpression)) {
				currentAccess = currentAccess.operand as AccessExpression
			}
			var functionAccess = currentAccess as FunctionAccessExpression
			var functionReturnVariables = if (trace.isMapped(functionAccess)) {
				trace.get(functionAccess)
			}
			else {
				newArrayList
			}
			// FIXME is this correct? it is a variable declaration, whereas the rhs is a field declaration
			val returnVariable = functionReturnVariables.filter[
					it == expression.fieldReference.fieldDeclaration].onlyElement
			result += createDirectReferenceExpression => [
				it.declaration = returnVariable
			]
		}
		return result		
	}
	
	def dispatch List<Expression> transformExpression(ArrayAccessExpression expression) {
		val result = <Expression>newArrayList
		
		// find original declaration and get the keys of the transformation
		var originalDeclaration = expression.findDeclarationOfReferenceExpression
		var originalLhsVariables = if (originalDeclaration instanceof ValueDeclaration) {
			exploreComplexType(originalDeclaration as ValueDeclaration,
				getTypeDefinitionFromType(originalDeclaration.type), newArrayList)
		}
		else {
			throw new IllegalArgumentException("Not an accessible value type: " + originalDeclaration)
		}
		// explore the chain of access expressions
		var accessList = expression.collectAccessList
		var List<DirectReferenceExpression> recordAccessList = accessList
			.filter(DirectReferenceExpression).toList
		var List<Expression> arrayAccessList = accessList.filter(Expression).toList
		
		// if 'simple' array
		if (recordAccessList.empty) {
			var transformedOperands = expression.operand.transformExpression
			for (op : transformedOperands) {
				result += createArrayAccessExpression => [
					it.operand = op
					it.arguments += expression.arguments.onlyElement.transformExpression.onlyElement
				]
			}	
		} 
		else {
			// else filter based on the corresponding subtree
			for (elem : originalLhsVariables) {	
				if (isSameAccessTree(elem.value, recordAccessList)) { //filter according to the access list
					// Create references
					var ReferenceExpression current = createDirectReferenceExpression => [
						it.declaration = trace.get(elem)
					]
					for (argument : arrayAccessList) {
						val currentConst = current
						val argumentConst = argument
						current = createArrayAccessExpression => [
							it.operand = currentConst
							it.arguments += argumentConst
						]
					}
					result += current
				}
			}
		}
		return result		
	}
	
	def dispatch List<Expression> transformExpression(UnaryExpression expression) {
		val result = <Expression>newArrayList
		result += create(expression.eClass) as UnaryExpression => [
			it.operand = expression.operand.transformExpression.getOnlyElement
		]
		return result
	}
	
	def dispatch List<Expression> transformExpression(StateReferenceExpression expression) {
		val result = <Expression>newArrayList
		val gammaRegion = expression.region
		val gammaState = expression.state
		result += statechartModelFactory.createStateReferenceExpression => [
			it.region = trace.get(gammaRegion)
			it.state = trace.get(gammaState)
		]
		return result
	}
	
	def dispatch List<Expression> transformExpression(IfThenElseExpression expression) {
		val result = <Expression>newArrayList
		result += createIfThenElseExpression => [
			it.condition = expression.condition.transformExpression.getOnlyElement
			it.then = expression.then.transformExpression.getOnlyElement
			it.^else = expression.^else.transformExpression.getOnlyElement
		]
		return result
	}

	def dispatch List<Expression> transformExpression(DirectReferenceExpression expression) {
		val result = <Expression>newArrayList
		val declaration = expression.declaration
		if (declaration instanceof ConstantDeclaration) {
			// Constant type declarations have to be transformed as their right hand side is inlined
			if (!trace.isMapped(declaration)) {
				// Constant type declarations have to be transformed as their right hand side is inlined
				val constantType = declaration.type
				if (constantType instanceof TypeReference) {
					val constantTypeDeclaration = constantType.reference
					val typeDefinition = constantTypeDeclaration.type
					if (!typeDefinition.isPrimitive) {
						if (!trace.isMapped(constantTypeDeclaration)) {
							val transformedTypeDeclaration = constantTypeDeclaration.transformTypeDeclaration
							val lowlevelPackage = trace.lowlevelPackage
							lowlevelPackage.typeDeclarations += transformedTypeDeclaration
						}
					}
				}
				return declaration.expression.transformExpression
			}
			/*val constantType = declaration.type
			if (constantType instanceof TypeReference) {
				val constantTypeDeclaration = constantType.reference
				val typeDefinition = constantTypeDeclaration.type
				if (!typeDefinition.isPrimitive && !(typeDefinition instanceof CompositeTypeDefinition)) {	//TODO handle composite?
					if (!trace.isMapped(constantTypeDeclaration)) {
						val transformedTypeDeclaration = constantTypeDeclaration.transformTypeDeclaration
						val lowlevelPackage = trace.lowlevelPackage
						lowlevelPackage.typeDeclarations += transformedTypeDeclaration
					}
				}
			}
			// Inlining the referred constant
			result += declaration.expression.transformExpression*/
			//////Uncomment up to this point and delete after if inlining is chosen
			//TODO complex types
			checkState(trace.isMapped(declaration), declaration)
			result += createDirectReferenceExpression => [
				it.declaration = trace.get(declaration)
			]
		}
		else {
			checkState(declaration instanceof VariableDeclaration || 
				declaration instanceof ParameterDeclaration, declaration)
			if (declaration instanceof VariableDeclaration) {
				if (trace.isMapped(declaration)) {	//if mapped as simple
					result += createDirectReferenceExpression => [
						it.declaration = trace.get(declaration)
					]	
				}
				else {							//if not as simple, try as complex
					var mapKeys = exploreComplexType(declaration,
						declaration.typeDefinitionFromType, newArrayList)
					for (key : mapKeys) {
						result += createDirectReferenceExpression => [
							it.declaration = trace.get(key)
						]
					}
				}
			}
			else if (declaration instanceof ParameterDeclaration) {
				//TODO complex types
				//checkState(trace.isMapped(declaration), declaration)
				if (trace.isMapped(declaration)) {	//TODO clean up and comment, same as the previous branch
					result += createDirectReferenceExpression => [
						it.declaration = trace.get(declaration)
					]
				}
				else {
					var mapKeys = exploreComplexType(declaration, declaration.typeDefinitionFromType, newArrayList)
					for (key : mapKeys) {
						result += createDirectReferenceExpression => [
							it.declaration = trace.get(key)
						]
					}
				}
			}
		}
		return result
	}
	
	def dispatch List<Expression> transformExpression(EnumerationLiteralExpression expression) {
		val result = <Expression>newArrayList
		val gammaEnumLiteral = expression.reference
		val index = gammaEnumLiteral.index
		val gammaEnumTypeDeclaration = gammaEnumLiteral.getContainerOfType(TypeDeclaration)
		checkState(trace.isMapped(gammaEnumTypeDeclaration))
		val lowlevelEnumTypeDeclaration = trace.get(gammaEnumTypeDeclaration)
		val lowlevelEnumTypeDefinition = lowlevelEnumTypeDeclaration.type as EnumerationTypeDefinition
		result += createEnumerationLiteralExpression => [
			it.reference = lowlevelEnumTypeDefinition.literals.get(index)
		]
		return result
	}
	
	def dispatch List<Expression> transformExpression(RecordLiteralExpression expression) {
		//TODO currently the field assignment position has to match the field declaration position
		val result = <Expression>newArrayList
		for (assignment : expression.fieldAssignments) {
			result += assignment.value.transformExpression
		}
		return result
	}
	
	def dispatch List<Expression> transformExpression(EventParameterReferenceExpression expression) {
		val result = <Expression>newArrayList
		val port = expression.port
		val event = expression.event
		val parameter = expression.parameter
		result +=  createDirectReferenceExpression => [
			it.declaration = trace.get(port, event, parameter).get(EventDirection.IN)
		]
		return result
	}
	
	def dispatch List<Expression> transformExpression(BinaryExpression expression) {
		val result = <Expression>newArrayList
		result += create(expression.eClass) as BinaryExpression => [
			it.leftOperand = expression.leftOperand.transformExpression.getOnlyElement
			it.rightOperand = expression.rightOperand.transformExpression.getOnlyElement
		]
		return result
	}
	
	def dispatch List<Expression> transformExpression(MultiaryExpression expression) {
		val result = <Expression>newArrayList
		val newExpression = create(expression.eClass) as MultiaryExpression
		for (containedExpression : expression.operands) {
			newExpression.operands += containedExpression.transformExpression.getOnlyElement
		}
		result += newExpression
		return result
	}
	
	protected def Type createTransformedRecordType(List<ArrayTypeDefinition> arrayStack, Type innerType) {
		if (arrayStack.size > 0) {
			val stackCopy = newArrayList
			stackCopy += arrayStack
			val stackTop = stackCopy.remove(0)
			val arrayTypeDef = constraintFactory.createArrayTypeDefinition
			arrayTypeDef.size = stackTop.size.transformExpression.getOnlyElement as IntegerLiteralExpression
			arrayTypeDef.elementType = createTransformedRecordType(stackCopy, innerType)
			return arrayTypeDef
		}
		else {
			return innerType.transformType
		}
	}
	
	protected def TypeDefinition getTypeDefinitionFromType(Declaration declaration) {
		return declaration.getTypeDefinition
	}
	
	protected def TypeDefinition getTypeDefinitionFromType(Type type) {
		return type.getTypeDefinition
	}
	
	protected def List<Pair<ValueDeclaration, List<FieldDeclaration>>> exploreComplexType(
			ValueDeclaration original, TypeDefinition type, List<FieldDeclaration> currentField) {
		// Returns each possible valid(!) variable_field(_field...) combinations: the resulting decomposed variables
		// e.g. rec_r1_rr1, rec_r1_rr2, rec_r2 (so rec_r1 not returned, as it is not the end of the list)
		var List<Pair<ValueDeclaration, List<FieldDeclaration>>> result = newArrayList
		
		if (type instanceof RecordTypeDefinition) {
			// In case of records go into each field
			for (field : type.fieldDeclarations) {
				// Get current field by extending the previous (~current) with the one to explore
				val newCurrent = newArrayList
				newCurrent += currentField
				newCurrent += field
				//Explore
				result += exploreComplexType(original, getTypeDefinitionFromType(field.type), newCurrent)
			}
		}
		else if (type instanceof ArrayTypeDefinition) {
			// In case of arrays jump to the inner type
			result += exploreComplexType(original, getTypeDefinitionFromType(type.elementType), currentField)
		}
		else {	//Simple
			// In case of simple types create a result element
			result += new Pair<ValueDeclaration, List<FieldDeclaration>>(original, currentField)
		}
		
		return result
	}
	
	protected def List<List<FieldDeclaration>> exploreComplexType2(
			TypeDefinition type, List<FieldDeclaration> currentField) {
		// Experimental
		val List<List<FieldDeclaration>> result = newArrayList
		
		if (type instanceof RecordTypeDefinition) {
			// In case of records go into each field
			for (field : type.fieldDeclarations) {
				// Get current field by extending the previous (~current) with the one to explore
				val newCurrent = newArrayList
				newCurrent += currentField
				newCurrent += field
				//Explore
				result += exploreComplexType2(getTypeDefinitionFromType(field.type), newCurrent)
			}
		}
		else if (type instanceof ArrayTypeDefinition) {
			// In case of arrays jump to the inner type
			result += exploreComplexType2(getTypeDefinitionFromType(type.elementType), currentField)
		}
		else {	//Simple
			// In case of simple types create a result element
			result += currentField
		}
		
		return result
	}
	
	protected def List<Expression> collectAccessList(ReferenceExpression exp) {
		// Returns the operands of (chained) access expression(s)
		// e.g. a.r1[2].r2 returns [r1, 2, r2]
		val result = newArrayList
		if (exp instanceof ArrayAccessExpression) {
			// if possible, add inner
			val inner = exp.operand
			if (inner instanceof ReferenceExpression) {
				result += collectAccessList(inner)
			}
			// add own
			result += exp.arguments.getOnlyElement
		}
		else if (exp instanceof RecordAccessExpression) {
			// if possible, add inner
			val inner = exp.operand
			if (inner instanceof ReferenceExpression) {
				result += collectAccessList(inner)
			}
			// add own
			result += exp.fieldReference
		}
		else if (exp instanceof SelectExpression){
			// if possible, jump over (as it returns a value with the same access list)
			val inner = exp.operand
			if (inner instanceof ReferenceExpression) {
				result += collectAccessList(inner)
			}
		}
		else {
			// function access and direct reference signal the end of the chain: let return with empty
		}
		return result
	}
	
	protected def findDeclarationOfReferenceExpression(Expression expression) {
		return expression.declaration
	}
	
	protected def boolean isSameAccessTree(List<FieldDeclaration> fieldsList,
			List<DirectReferenceExpression> currentAccessList) {
		if (fieldsList.size < currentAccessList.size) {
			return false
		}
		for (var i = 0; i < currentAccessList.size; i++) {
			val access = currentAccessList.get(i).declaration
			val field = fieldsList.get(i)
			if (access === field) {
				return false
			}
		}
		return true
	}
	
	protected def dispatch List<Expression> enumerateExpression(Expression expression) {
		//DOES NOT TRANSFORM
		throw new IllegalArgumentException("Cannot enumerate expression: " + expression)
	}
	
	protected def dispatch List<Expression> enumerateExpression(DirectReferenceExpression expression) {
		//DOES NOT TRANSFORM
		val List<Expression> result = newArrayList
		val type = expression.declaration.type
		// Only array reference enumeration is supported
		if (type instanceof ArrayTypeDefinition) {
			// Create an access expression for each of the array elements (based on its size)
			for (var i = 0; i < type.size.value.intValue; i++) {
				val temp = i	//(constant to use inside a lambda)
				result += createArrayAccessExpression => [
					it.operand = createDirectReferenceExpression => [
						it.declaration = expression.declaration
					]
					it.arguments += createIntegerLiteralExpression => [
						it.value = BigInteger.valueOf(temp)
					]
				]
			}
		}
		else {
			throw new IllegalArgumentException("Cannot enumerate expression: " + expression)
		}
		return result
	}
	
	protected def dispatch List<Expression> enumerateExpression(AccessExpression expression) {
		// array-in-array, array-in-record, (array-from-function, array-from-select TODO) DOES NOT TRANSFORM
		val List<Expression> result = newArrayList
		
		val referredDeclaration = expression.referredValues.getOnlyElement
		val typeToAssign = referredDeclaration.typeDefinitionFromType
		var originalLhsFields = exploreComplexType(referredDeclaration, typeToAssign, newArrayList)			
	
		// if array type
		var randomElem = originalLhsFields.get(0) //equals a random accessible element
		var randomElemKey = randomElem.key	//equals referredDeclaration
		var int i = 0	// number of the array elements 
		// if mapped as complex and is an array
		if (trace.isMapped(randomElem)) {
			val element = trace.get(randomElem)
			val type = element.typeDefinitionFromType
			if (type instanceof ArrayTypeDefinition) {
				i = type.size.value.intValue
			}
		} 
		// if mapped as simple variable and is an array
		if (trace.isMapped(randomElemKey)) {
			val lowlevelDeclaration = trace.get(randomElemKey)
			val typeDefinition = lowlevelDeclaration.typeDefinitionFromType
			if (typeDefinition instanceof ArrayTypeDefinition) {
				i = typeDefinition.size.value.intValue
			}
		}
		
		for (var j = 0; j < i; j++) {	// running variable for the array indices
			val temp = j	//to use inside a lambda
			result += createArrayAccessExpression => [
				it.operand = expression.clone	//DOES NOT TRANSFORM
				it.arguments += createIntegerLiteralExpression => [
					it.value = BigInteger.valueOf(temp)
				]
			]
		}

		return result	
	}
	
	protected def dispatch List<Expression> enumerateExpression(ArrayLiteralExpression expression) {
		return new ArrayList<Expression>(expression.operands)
	}
	
	protected def dispatch List<Expression> enumerateExpression(IntegerRangeLiteralExpression expression) {
		val result = <Expression>newArrayList
		val leftOperand = expression.leftOperand
		val rightOperand = expression.rightOperand
		
		if (!(leftOperand instanceof IntegerLiteralExpression &&
				rightOperand instanceof IntegerLiteralExpression)) {
			throw new IllegalArgumentException(
				"For statements over non-literal ranges are currently not supported!: " + expression)
		}
		
		// evaluate if possible
		val left = leftOperand as IntegerLiteralExpression
		val start = expression.leftInclusive ? left.value.intValue : left.value.intValue + 1
		val right = rightOperand as IntegerLiteralExpression
		val end = expression.rightInclusive ? right.value.intValue : right.value.intValue - 1
		for (var i = start; i <= end; i++) {
			val newLiteral = createIntegerLiteralExpression
			newLiteral.value = BigInteger.valueOf(i)
			result += newLiteral
		}
		
		return result
	}

	protected def dispatch List<Expression> enumerateExpression(TypeReferenceExpression expression) {
		val result = <Expression>newArrayList
		
		// only enums are enumerable
		val typeDefinition = expression.declaration.typeDefinitionFromType
		if (!(typeDefinition instanceof EnumerationTypeDefinition)) {
			throw new IllegalArgumentException("Referred type is not enumerable: " + typeDefinition)
		}
		// enumerate
		val enumeration = typeDefinition as EnumerationTypeDefinition
		for (literalDefinition : enumeration.literals) {
			result += createEnumerationLiteralExpression => [
				it.reference = literalDefinition
			]
		}
		
		return result
	}	
	
}