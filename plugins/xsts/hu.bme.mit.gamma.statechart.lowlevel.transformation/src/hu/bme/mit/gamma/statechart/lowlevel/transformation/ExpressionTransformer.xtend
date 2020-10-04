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

import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.DefaultExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.xsts.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeDefinition
import java.util.List
import java.util.ArrayList
import hu.bme.mit.gamma.expression.model.FieldDeclaration
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression

class ExpressionTransformer {
	// Auxiliary object
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	// Expression factory
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	protected final boolean functionInlining
	
	new(Trace trace, boolean functionInlining) {
		this.trace = trace
		this.functionInlining = functionInlining
	}
	
	def dispatch Expression transformExpression(NullaryExpression expression) {
		return expression.clone(true, true)
	}
	
	def dispatch Expression transformExpression(DefaultExpression expression) {
		return createTrueExpression
	}
	
	def dispatch Expression transformExpression(FunctionAccessExpression expression) {
		if (functionInlining) {
			return createDirectReferenceExpression => [
				it.declaration = trace.get(expression)
			]
		} else {
			//TODO
			throw new IllegalArgumentException("No function inlining is currently not possible")
		}
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
	def dispatch Expression transformExpression(DirectReferenceExpression expression) {
		val declaration = expression.declaration
		if (declaration instanceof ConstantDeclaration) {
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
		checkState(declaration instanceof VariableDeclaration || 
			declaration instanceof ParameterDeclaration, declaration)
		val referenceExpression = createDirectReferenceExpression
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
	def dispatch Expression transformExpression(EnumerationLiteralExpression expression) {
		val gammaEnumLiteral = expression.reference
		val index = gammaEnumLiteral.index
		val gammaEnumTypeDeclaration = gammaEnumLiteral.getContainerOfType(TypeDeclaration)
		checkState(trace.isMapped(gammaEnumTypeDeclaration))
		val lowlevelEnumTypeDeclaration = trace.get(gammaEnumTypeDeclaration)
		val lowlevelEnumTypeDefinition = lowlevelEnumTypeDeclaration.type as EnumerationTypeDefinition
		return createEnumerationLiteralExpression => [
			it.reference = lowlevelEnumTypeDefinition.literals.get(index)
		]
	}
	
	// Key method
	def dispatch Expression transformExpression(EventParameterReferenceExpression expression) {
		val port = expression.port
		val event = expression.event
		val parameter = expression.parameter
		return createDirectReferenceExpression => [
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
		return type.clone(true, true)
	}

	protected def dispatch Type transformType(IntegerTypeDefinition type) {
		return type.clone(true, true)
	}

	protected def dispatch Type transformType(DecimalTypeDefinition type) {
		return type.clone(true, true)
	}
	
	protected def dispatch Type transformType(RationalTypeDefinition type) {
		return type.clone(true, true)
	}
	
	protected def dispatch Type transformType(EnumerationTypeDefinition type) {
		return type.clone(true, true)
	}
	
	//TODO maybe?
	protected def dispatch Type transformType(ArrayTypeDefinition type) {
		return type.clone(true, true)
	}
	
	protected def dispatch Type transformType(TypeReference type) {
		val typeDeclaration = type.reference
		val typeDefinition = typeDeclaration.type
		// Inlining primitive types
		if (typeDefinition.isPrimitive) {
			return typeDefinition.transformType
		}
		val lowlevelTypeDeclaration = if (trace.isMapped(typeDeclaration)) {
			trace.get(typeDeclaration)
		}
		else {
			// Transforming type declaration
			val transformedTypeDeclaration = typeDeclaration.transformTypeDeclaration
			val lowlevelPackage = trace.lowlevelPackage
			lowlevelPackage.typeDeclarations += transformedTypeDeclaration
			transformedTypeDeclaration
		}
		return createTypeReference => [
			it.reference = lowlevelTypeDeclaration
		]
	}
	
	protected def transformTypeDeclaration(TypeDeclaration typeDeclaration) {
		val newTypeDeclaration = constraintFactory.create(typeDeclaration.eClass) as TypeDeclaration => [
			it.name = getName(typeDeclaration)
			it.type = typeDeclaration.type.transformType
		]
		trace.put(typeDeclaration, newTypeDeclaration)
		return newTypeDeclaration
	}
	
	protected def List<VariableDeclaration> transformVariable(VariableDeclaration variable) {
		var List<VariableDeclaration> transformed = new ArrayList<VariableDeclaration>()
		var TypeDefinition variableType = getTypeDefinitionFromType(variable.type)
		// Records are broken up into separate variables
		if (variableType instanceof RecordTypeDefinition) {
			var RecordTypeDefinition typeDef = getTypeDefinitionFromType(variable.type) as RecordTypeDefinition
			for (field : typeDef.fieldDeclarations) {
				var innerField = new ArrayList<FieldDeclaration>
				innerField.add(field)
				transformed.addAll(transformVariableField(variable, innerField, new ArrayList<ArrayTypeDefinition>))
			}
			return transformed
		} else if (variableType instanceof ArrayTypeDefinition) {
			var arrayStack = new ArrayList<ArrayTypeDefinition>
			arrayStack.add(variableType)
			transformed.addAll(transformVariableArray(variable, variableType, arrayStack))
			return transformed
		} else {	//Simple variables and arrays of simple types are simply transformed
			transformed.add(createVariableDeclaration => [
				it.name = variable.name
				it.type = variable.type.transformType
				it.expression = variable.expression?.transformExpression
			])
			trace.put(variable, transformed.head)
			return transformed
		}
	}
	
	private def List<VariableDeclaration> transformVariableField(VariableDeclaration variable, List<FieldDeclaration> currentField, List<ArrayTypeDefinition> arrayStack) {
		var List<VariableDeclaration> transformed = new ArrayList()
		
		if (getTypeDefinitionFromType(currentField.last.type) instanceof RecordTypeDefinition
		) {			// if another record
			var RecordTypeDefinition typeDef = getTypeDefinitionFromType(currentField.last.type) as RecordTypeDefinition
			for (field : typeDef.fieldDeclarations) {
				var innerField = new ArrayList<FieldDeclaration>
				innerField.addAll(currentField)
				innerField.add(field)
				var innerStack = new ArrayList<ArrayTypeDefinition>
				innerStack.addAll(arrayStack)
				transformed.addAll(transformVariableField(variable, innerField, innerStack))
			}
		} else {	//if simple type
			var transformedField = createVariableDeclaration => [
				it.name = variable.name + "_" + currentField.last.name
				
				it.type = createTransformedRecordType(arrayStack, currentField.last.type)
				if (variable.expression !== null) {
					var Expression initial = variable.expression
					if (initial instanceof RecordLiteralExpression) {
						it.expression = getExpressionFromRecordLiteral(initial, currentField).transformExpression
					} else if (initial instanceof ArrayLiteralExpression) {
						it.expression = constraintFactory.createArrayLiteralExpression
						for (op : initial.operands) {
							if (op instanceof RecordLiteralExpression) {
								(it.expression as ArrayLiteralExpression).operands.add(getExpressionFromRecordLiteral(op, currentField).transformExpression)
							}
						}
					}
				}
			]
			transformed.add(transformedField)
			trace.put(new Pair<VariableDeclaration, List<FieldDeclaration>>(variable,currentField), transformedField)
		}
		
		return transformed
	}
	
	private def List<VariableDeclaration> transformVariableArray(VariableDeclaration variable, ArrayTypeDefinition currentType, List<ArrayTypeDefinition> arrayStack) {
		var List<VariableDeclaration> transformed = new ArrayList<VariableDeclaration>()
		
		var TypeDefinition innerType = getTypeDefinitionFromType(currentType.elementType)
		if (innerType instanceof ArrayTypeDefinition) {
			var innerStack = new ArrayList<ArrayTypeDefinition>
			innerStack.addAll(arrayStack)
			innerStack.add(innerType)
			transformed.addAll(transformVariableArray(variable, innerType, innerStack))
		} else if (innerType instanceof RecordTypeDefinition) {
			for (field : innerType.fieldDeclarations) {
				var innerField = new ArrayList<FieldDeclaration>
				innerField.add(field)
				var innerStack = new ArrayList<ArrayTypeDefinition>
				innerStack.addAll(arrayStack)
				transformed.addAll(transformVariableField(variable, innerField, innerStack))
			}
			return transformed
		} else {	// Simple
			transformed.add(createVariableDeclaration => [
				it.name = variable.name
				it.type = variable.type.transformType
				it.expression = variable.expression?.transformExpression
			])
			trace.put(variable, transformed.head)
		}
		
		return transformed
	}
	
	private def Expression getExpressionFromRecordLiteral(RecordLiteralExpression initial, List<FieldDeclaration> currentField) {
		for (assignment : initial.fieldAssignments) {
			if (currentField.head.name == assignment.reference) {
				if (currentField.size == 1) {
					return assignment.value
				} else {
					if (assignment.value instanceof RecordLiteralExpression) {
						//System.out.println("CURRFIELD: " + currentField.size )
						var innerField = new ArrayList<FieldDeclaration>
						innerField.addAll(currentField.subList(1, currentField.size))
						return getExpressionFromRecordLiteral(assignment.value as RecordLiteralExpression, innerField)
					} else {
						throw new IllegalArgumentException("Invalid expression!")
					}
				}
			}
		}
	}
	
	private def Type createTransformedRecordType(List<ArrayTypeDefinition> arrayStack, Type innerType) {
		if(arrayStack.size > 0) {
			var stackCopy = new ArrayList<ArrayTypeDefinition>
			stackCopy.addAll(arrayStack)
			var stackTop = stackCopy.remove(0)
			var arrayTypeDef = constraintFactory.createArrayTypeDefinition
			arrayTypeDef.size = stackTop.size
			arrayTypeDef.elementType = createTransformedRecordType(stackCopy, innerType)
			return arrayTypeDef
		} else {
			return innerType.transformType
		}
	}
	
		
	private def TypeDefinition getTypeDefinitionFromType(Type type) {
		// Resolve type reference (may be chain) or return type definition
		if (type instanceof TypeReference) {
			var innerType = (type as TypeReference).reference.type
			return getTypeDefinitionFromType(innerType)
		} else {
			return type as TypeDefinition
		}
	}
	
	
}