package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.ProcedureDeclaration
import hu.bme.mit.gamma.action.model.TypeReferenceExpression
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.CompositeTypeDefinition
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FieldDeclaration
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression
import hu.bme.mit.gamma.expression.model.LambdaDeclaration
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.SelectExpression
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDefinition
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.ArrayList
import java.util.HashMap
import java.util.LinkedList
import java.util.List
import java.util.Map
import java.util.stream.Collectors

import static extension com.google.common.collect.Iterables.getOnlyElement

class ExpressionPreconditionTransformer {
	// Auxiliary object
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Trace 
	protected final Trace trace
	// The related transformers
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ActionTransformer actionTransformer
	// Transformation parameters
	protected final String assertionVariableName
	protected final boolean functionInlining
	protected final int maxRecursionDepth
	protected Map<FunctionDeclaration, Integer> currentRecursionDepth = new HashMap
	
	new(Trace trace, ExpressionTransformer expressionTransformer, ActionTransformer actionTransformer, String assertionVariableName, boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
		this.expressionTransformer = expressionTransformer
		this.actionTransformer = actionTransformer
		this.assertionVariableName = assertionVariableName
		this.functionInlining = functionInlining
		this.maxRecursionDepth = maxRecursionDepth
	}
	
	protected def dispatch List<Action> transformPrecondition(Expression expression) {
		return new LinkedList<Action>
	}
	
	protected def dispatch List<Action> transformPrecondition(SelectExpression expression) {
		val result = new LinkedList<Action>
		// get the possible values (enumerate & transform)
		val innerExpression = expression.operand
		// 'temporary' variable(s)
		val List<VariableDeclaration> tempVariableDeclarations = newArrayList
		val List<VariableDeclarationStatement> tempVariables = newArrayList 
		// set temporary variable(s)
		if (innerExpression instanceof TypeReferenceExpression) {
			var originalType = innerExpression.declaration.type.findTypeDefinitionOfType
			if (originalType instanceof EnumerationTypeDefinition) {
				// pseudo-high-level type reference needed to transform the type declaration too (if not yet transformed)
				val otr = createTypeReference => [
					it.reference = innerExpression.declaration
				]
				tempVariableDeclarations += createVariableDeclaration => [
					it.name = new NameProvider(expression).name
					it.type = otr.transformType
				]
				trace.put(expression, tempVariableDeclarations)
				tempVariables += tempVariableDeclarations.stream.map([decl | createVariableDeclarationStatement => [it.variableDeclaration = decl]]).collect(Collectors.toList())				
			} else {
				throw new IllegalArgumentException("Cannot select from expression of type: " + originalType)
			}
		}
		else if (innerExpression instanceof ReferenceExpression) {
			// get variable type
			var originalType = innerExpression.referredValues.onlyElement.type.typeDefinitionFromType
			var accessList = innerExpression.collectAccessList
			
			var currentType = originalType	//TODO extract this (~with other sameAccessTree code blocks)
			var currentList = accessList
			while (currentList.size > 0) {
				var currentElem = currentList.remove(0)
				// if record access
				if (currentElem instanceof String && currentType instanceof RecordTypeDefinition) {
					var fieldDeclarations = (currentType as RecordTypeDefinition).fieldDeclarations
					for (field : fieldDeclarations) {
						if (field.name == currentElem) {
							currentType = field.type.typeDefinitionFromType
						}
					}
				}
				// if array access
				else if (currentElem instanceof Expression && currentType instanceof ArrayTypeDefinition) {
					currentType = (currentType as ArrayTypeDefinition).elementType.typeDefinitionFromType
				}
				else {
					throw new IllegalArgumentException("Access list and type hierarchy do not match!")
				}
			}
			// check if select-able
			var TypeDefinition tempVariableOriginalType = null
			if (currentType instanceof ArrayTypeDefinition) {
				tempVariableOriginalType = currentType.elementType.typeDefinitionFromType
			} else {
				throw new IllegalArgumentException("Cannot select from expression of type: " + tempVariableOriginalType)
			}
			
			// set temporary variables
			val tempVariableOriginalTypeConst = tempVariableOriginalType		// const to be used inside a lambda
			
			if (!(tempVariableOriginalType instanceof CompositeTypeDefinition)) {	//TODO simplify this and the following 2 branches
				val tempVariable = createVariableDeclaration => [
					it.name = new NameProvider(expression).name
					it.type = tempVariableOriginalTypeConst.transformType
				]
				tempVariableDeclarations += tempVariable
				trace.put(expression, tempVariableDeclarations)
				tempVariables += createVariableDeclarationStatement => [
					it.variableDeclaration = tempVariable
				]
			} else {
				tempVariableDeclarations += tempVariableOriginalType.createVariablesFromType(new NameProvider(expression))
				trace.put(expression, tempVariableDeclarations)
				tempVariables += tempVariableDeclarations.stream.map([decl | createVariableDeclarationStatement => [it.variableDeclaration = decl]]).collect(Collectors.toList())				
			}		
		} 
		else if (innerExpression instanceof IntegerRangeLiteralExpression) {
			tempVariableDeclarations += createIntegerTypeDefinition.createVariablesFromType(new NameProvider(expression))
			trace.put(expression, tempVariableDeclarations)
			tempVariables += tempVariableDeclarations.stream.map([decl | createVariableDeclarationStatement => [it.variableDeclaration = decl]]).collect(Collectors.toList())				
		}
		else {
			//TODO integer range literal (maybe array literal / enum type?)
			throw new IllegalArgumentException("Cannot select from expression: " + innerExpression)
		}
		result += tempVariables
		// get the possible values
		val possibleValues = innerExpression.enumerateExpression
		
		val List<Expression> possibleLowLevelValues = newArrayList
		for(vali : possibleValues){
			possibleLowLevelValues += vali.transformExpression
		}
		// create choice statement
		var chs = createChoiceStatement => [
			for (var i = 0; i < possibleLowLevelValues.size / tempVariables.size; i++) {
				val iConst = i
				it.branches += createBranch => [
					it.guard = createTrueExpression
					it.action = createBlock => [
						for (var j = 0; j < tempVariableDeclarations.size; j++) {
							val jConst = j
							var act = createAssignmentStatement => [
								it.lhs = createDirectReferenceExpression => [
									it.declaration = tempVariableDeclarations.get(jConst)
								]
								it.rhs = possibleLowLevelValues.get(iConst * tempVariables.size + jConst)
							]
							it.actions += act//.transformAction(newLinkedList)
						}		
					]
				]
			}
		]
		result += chs
		return result
	}
	
	protected def dispatch List<Action> transformPrecondition(FunctionAccessExpression expression) {
		val result = new LinkedList<Action>
		if (functionInlining) {
			// increase recursion depth
			val FunctionDeclaration function = (expression.operand as DirectReferenceExpression).declaration as FunctionDeclaration
			if (currentRecursionDepth.containsKey(function)) {
				currentRecursionDepth.replace(function, currentRecursionDepth.get(function) + 1)
			} else {
				currentRecursionDepth.put(function, 1);
			}
			// check recursion depth
			if (currentRecursionDepth.get(function) > maxRecursionDepth) {
				//throw new IllegalArgumentException("Cannot inline function access: max recursion depth reached!")
				// Terminate recursion transformation and fail assertion (if possible)
				if (trace.isAssertionVariableMapped(assertionVariableName)) {
					result += createAssignmentStatement => [
						it.lhs = createDirectReferenceExpression => [
							it.declaration = trace.getAssertionVariable(assertionVariableName)
						]
						it.rhs = createTrueExpression
					]
				}
				return result
			}
			// create parameter variables
			if (function.parameterDeclarations.size > 0) {
				val precondition = new LinkedList<Action>
				val List<VariableDeclarationStatement> parameterVariables = newLinkedList
				for (i : 0 .. function.parameterDeclarations.size - 1) {
					var parameterVariableDeclarations = function.parameterDeclarations.get(i).transformValue
					parameterVariables += parameterVariableDeclarations.map[vari | createVariableDeclarationStatement => [
						it.variableDeclaration = vari
					]]
					var arguments = expression.arguments.get(i).transformExpression
					if(arguments.size != parameterVariableDeclarations.size) {
						throw new IllegalArgumentException("Argument and parameter numbers do not match!")
					}
					for(j : 0 .. arguments.size - 1) {	//TODO is assignment based on ordering correct?
						parameterVariableDeclarations.get(i).expression = arguments.get(i)
					}
					
				}
				result.addAll(precondition)
				result.addAll(parameterVariables)
			}
			// create return variable(s) if needed
			val List<VariableDeclarationStatement> returnVariables = newArrayList
			val List<VariableDeclaration> returnVariableDeclarations = newArrayList
			var functionType = function.type.typeDefinitionFromType
			if (!(functionType instanceof VoidTypeDefinition)) {
				// create variable declarations
				if (!(functionType instanceof CompositeTypeDefinition)) {
					val returnVariable = createVariableDeclaration => [
						it.name = new NameProvider(expression).name
						it.type = function.type
					]
					returnVariableDeclarations += returnVariable
					trace.put(expression, returnVariableDeclarations)
					returnVariables += createVariableDeclarationStatement => [
						it.variableDeclaration = returnVariable
					]
				} 
				else {
					returnVariableDeclarations += functionType.createVariablesFromType(new NameProvider(expression))
					trace.put(expression, returnVariableDeclarations)
					returnVariables += returnVariableDeclarations.stream.map([decl | createVariableDeclarationStatement => [it.variableDeclaration = decl]]).collect(Collectors.toList())				
				}
				// add to stack and result
				returnStack.push(returnVariableDeclarations)
				result += returnVariables
			}
			// transform the actions according to the type of the function
			if (function instanceof LambdaDeclaration) {
				//transform the expression (TODO is this needed? per def cannot have side effects)
				result.addAll(function.expression.transformPrecondition)
				if (!returnVariables.empty) {
					val transformedExpression = function.expression.transformExpression
					for (var i = 0; i < returnVariableDeclarations.size; i++) {
						val index = i
						val assignment = createAssignmentStatement => [
							it.rhs = transformedExpression.get(index)	//FIXME now the expression transformation and variable order have to match (also the sizes!)
							it.lhs = createDirectReferenceExpression => [
								it.declaration = returnVariableDeclarations.get(index)
							]
						]
						result += assignment
					}
				}
			} 
			else if (function instanceof ProcedureDeclaration) {
				result.addAll(function.body.transformAction(new LinkedList<Action>))
				actionTransformer.returnStack.pop()	//TODO pop in case of lambdas too?
				
			} 
			else {
				throw new IllegalArgumentException("Unknown function type: " + function.class)
			}
			// decrease recursion depth
			currentRecursionDepth.replace(function, currentRecursionDepth.get(function) - 1)
			//actionTransformer.currentReturnVariable = null
		}
		return result
	}
	
	//TODO rename variable to sth relevant
	protected def List<VariableDeclaration> createVariablesFromType(Type variable, NameProvider nameProvider) {
		var List<VariableDeclaration> transformed = new ArrayList<VariableDeclaration>()
		var TypeDefinition variableType = getTypeDefinitionFromType(variable)
		// Records are broken up into separate variables
		if (variableType instanceof RecordTypeDefinition) {
			var RecordTypeDefinition typeDef = variableType as RecordTypeDefinition
			for (field : typeDef.fieldDeclarations) {
				var innerField = new ArrayList<FieldDeclaration>
				innerField.add(field)
				transformed.addAll(createFunctionReturnField(variable, nameProvider, innerField, new ArrayList<ArrayTypeDefinition>))//TODO new name provider
			}
			return transformed
		} else if (variableType instanceof ArrayTypeDefinition) {
			var arrayStack = new ArrayList<ArrayTypeDefinition>
			arrayStack.add(variableType)
			transformed.addAll(createFunctionReturnArray(variable, nameProvider, variableType, arrayStack))//TODO new name provider
			return transformed
		} else {	//Simple variables and arrays of simple types are simply transformed
			transformed.add(createVariableDeclaration => [
				it.name = nameProvider.name						
				it.type = variable.transformType
			])
			return transformed
		}
	}
	
	private def List<VariableDeclaration> createFunctionReturnField(Type variable, NameProvider nameProvider, List<FieldDeclaration> currentField, List<ArrayTypeDefinition> arrayStack) {
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
				transformed.addAll(createFunctionReturnField(variable, nameProvider, innerField, innerStack))//TODO new name provider
			}
		} else {	//if simple type
			var transformedField = createVariableDeclaration => [
				it.name = nameProvider.name + "_" + currentField.last.name		//TODO name provider all-in-one
				it.type = expressionTransformer.createTransformedRecordType(arrayStack, currentField.last.type)
			]
			transformed.add(transformedField)
		}
		return transformed
	}
	
	private def List<VariableDeclaration> createFunctionReturnArray(Type variable, NameProvider nameProvider, ArrayTypeDefinition currentType, List<ArrayTypeDefinition> arrayStack) {
		var List<VariableDeclaration> transformed = new ArrayList<VariableDeclaration>()
		
		var TypeDefinition innerType = getTypeDefinitionFromType(currentType.elementType)
		if (innerType instanceof ArrayTypeDefinition) {
			var innerStack = new ArrayList<ArrayTypeDefinition>
			innerStack.addAll(arrayStack)
			innerStack.add(innerType)
			transformed.addAll(createFunctionReturnArray(variable, nameProvider, innerType, innerStack))//TODO new name provider
		} else if (innerType instanceof RecordTypeDefinition) {
			for (field : innerType.fieldDeclarations) {
				var innerField = new ArrayList<FieldDeclaration>
				innerField.add(field)
				var innerStack = new ArrayList<ArrayTypeDefinition>
				innerStack.addAll(arrayStack)
				transformed.addAll(createFunctionReturnField(variable, nameProvider, innerField, innerStack))//TODO new name provider
			}
			return transformed
		} else {	// Simple
			transformed.add(createVariableDeclaration => [
				it.name = nameProvider.name					
				it.type = type.transformType
			])
		}
		
		return transformed
	}
	

}