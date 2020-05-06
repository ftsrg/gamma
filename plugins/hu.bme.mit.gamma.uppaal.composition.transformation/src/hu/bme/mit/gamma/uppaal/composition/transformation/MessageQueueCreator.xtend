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
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.MessageQueue
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.EventsIntoMessageQueues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InstanceMessageQueues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopMessageQueues
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.NTA
import uppaal.UppaalPackage
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.DeclarationsPackage
import uppaal.declarations.ExpressionInitializer
import uppaal.declarations.Function
import uppaal.declarations.FunctionDeclaration
import uppaal.declarations.Parameter
import uppaal.declarations.ValueIndex
import uppaal.declarations.Variable
import uppaal.declarations.system.SystemPackage
import uppaal.expressions.ArithmeticExpression
import uppaal.expressions.ArithmeticOperator
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.CompareExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.IncrementDecrementExpression
import uppaal.expressions.IncrementDecrementOperator
import uppaal.expressions.LiteralExpression
import uppaal.expressions.ScopedIdentifierExpression
import uppaal.statements.Block
import uppaal.statements.ExpressionStatement
import uppaal.statements.ForLoop
import uppaal.statements.IfStatement
import uppaal.statements.ReturnStatement
import uppaal.statements.StatementsPackage
import uppaal.templates.TemplatesPackage
import uppaal.types.DeclaredType
import uppaal.types.TypeReference
import uppaal.types.TypesPackage

import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class MessageQueueCreator {
	// NTA target model
	final NTA target
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	protected final extension IModelManipulations manipulation
	// UPPAAL packages
	protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	protected final extension UppaalPackage upPackage = UppaalPackage.eINSTANCE
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TypesPackage typPackage = TypesPackage.eINSTANCE
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	protected final extension StatementsPackage stmPackage = StatementsPackage.eINSTANCE
	protected final extension SystemPackage sysPackage = SystemPackage.eINSTANCE
	// Viatra engine
	protected final ViatraQueryEngine engine
	// Trace
	protected final extension Trace modelTrace
	// Auxiliary objects
	protected final extension NtaBuilder ntaBuilder
	protected final extension ExpressionTransformer expressionTransformer
	// Message struct types
	protected final DeclaredType messageStructType
	protected final DataVariableDeclaration messageEvent
	protected final DataVariableDeclaration messageValue
	// Rules
	protected BatchTransformationRule<TopMessageQueues.Match, TopMessageQueues.Matcher> topMessageQueuesRule
	protected BatchTransformationRule<InstanceMessageQueues.Match, InstanceMessageQueues.Matcher> instanceMessageQueuesRule
	
	new(NtaBuilder ntaBuilder, IModelManipulations manipulation, ViatraQueryEngine engine,
			ExpressionTransformer expressionTransformer, Trace modelTrace,
			DeclaredType messageStructType, DataVariableDeclaration messageEvent, DataVariableDeclaration messageValue) {
		this.target = ntaBuilder.nta
		this.ntaBuilder = ntaBuilder
		this.manipulation = manipulation
		this.engine = engine
		this.expressionTransformer = expressionTransformer
		this.modelTrace = modelTrace
		this.messageStructType = messageStructType
		this.messageEvent = messageEvent
		this.messageValue = messageValue
	}
	
	def getTopMessageQueuesRule() {
		if (topMessageQueuesRule === null) {
			topMessageQueuesRule = createRule(TopMessageQueues.instance).action [
				val queue = it.queue
				// Creating the size const
				val capacityConst = queue.createCapacityConst(false, null)
				// Creating the capacity var
				val sizeVar = queue.createSizeVar(null)
				// Creating the Message array variable
				val messageArray = queue.createMessageArray(capacityConst, null)
				val messageVariableContainer = messageArray.container as DataVariableDeclaration
				// Creating peek function
				val peekFunction = queue.createPeekFunction(messageArray, null)
				// Creating shift function
				val shiftFunction = queue.createShiftFunction(messageArray, sizeVar, null)
				// Creating the push function
				val pushFunction = queue.createPushFunction(messageArray, sizeVar, capacityConst, null)
				// Creating isFull function
				val isFullFunction = queue.createIsFullFunction(sizeVar, capacityConst, null)
				// The trace cannot be done with "addToTrace", so it is done here
				queue.addQueueTrace(capacityConst, sizeVar, peekFunction, shiftFunction, pushFunction, isFullFunction, messageVariableContainer)
			].build
		}
	}
	
	def getInstanceMessageQueuesRule() {
		if (instanceMessageQueuesRule === null) {
			instanceMessageQueuesRule = createRule(InstanceMessageQueues.instance).action [
				val queue = it.queue
				// Checking whether the message needs regular size
				val hasIncomingQueueMessage = EventsIntoMessageQueues.Matcher.on(engine).hasMatch(null, null, null, it.instance, null, queue)
				// Creating the size const
				val capacityConst = queue.createCapacityConst(hasIncomingQueueMessage, it.instance)
				// Creating the capacity var
				val sizeVar = queue.createSizeVar(it.instance)
				// Creating the Message array variable
				val messageArray = queue.createMessageArray(capacityConst, it.instance)
				val messageVariableContainer = messageArray.container as DataVariableDeclaration
				// Creating peek function
				val peekFunction = queue.createPeekFunction(messageArray, it.instance)
				// Creating shift function
				val shiftFunction = queue.createShiftFunction(messageArray, sizeVar, it.instance)
				// Creating the push function
				val pushFunction = queue.createPushFunction(messageArray, sizeVar, capacityConst, it.instance)
				// Creating isFull function
				val isFullFunction = queue.createIsFullFunction(sizeVar, capacityConst, it.instance)
				// The trace cannot be done with "addToTrace", so it is done here
				queue.addQueueTrace(capacityConst, sizeVar, peekFunction, shiftFunction, pushFunction, isFullFunction, messageVariableContainer)
				addToTrace(instance, #{queue, capacityConst, sizeVar, peekFunction, shiftFunction, pushFunction, isFullFunction, messageVariableContainer}, instanceTrace)
			].build
		}
	}
	
	private def createCapacityConst(MessageQueue queue, boolean hasEventsFromOtherComponents, ComponentInstance owner) {
		val sizeConst = createVariable(target.globalDeclarations, DataVariablePrefix.CONST, target.int,
			queue.name.toUpperCase + "_CAPACITY" + owner.postfix)
		if (hasEventsFromOtherComponents) {
			// Normal size
			sizeConst.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
				it.transform(expressionInitializer_Expression, queue.capacity)
			]
		}
		else {
			// For control queues size is 1
			sizeConst.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
				it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
		   			it.text = "1"
		   		]
			]
		}
		return sizeConst
	}
	
	private def createSizeVar(MessageQueue queue, ComponentInstance owner) {
		val capacityVar = createVariable(target.globalDeclarations, DataVariablePrefix.NONE, target.int,
			queue.name + "Size" + owner.postfix)
		capacityVar.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
			it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
		   		it.text = "0"
		   	]
		]
		return capacityVar
	}
	
	private def createMessageArray(MessageQueue queue, DataVariableDeclaration sizeConst, ComponentInstance owner) {
		val messageVariableContainer = target.globalDeclarations.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
			it.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
				it.referredType = messageStructType // Only one variable is expected
			]			
		]
		val messageArray = messageVariableContainer.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
			it.container = messageVariableContainer
			it.name = queue.name + owner.postfix
			// Creating the array size
			it.createChild(variable_Index, valueIndex) as ValueIndex => [
				it.createChild(valueIndex_SizeExpression, identifierExpression) as IdentifierExpression => [
					it.identifier = sizeConst.variable.head // Only one variable is expected
				]
			]
		]
		return messageArray
	}
	
	private def createPeekFunction(MessageQueue queue, Variable messageArray, ComponentInstance owner) {
		val peekFunction = target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = messageStructType
				]
				it.name = "peek" + queue.name + owner.postfix
				it.createChild(function_Block, stmPackage.block) as Block => [
					it.createChild(block_Statement, stmPackage.returnStatement) as ReturnStatement => [
						it.createChild(returnStatement_ReturnExpression, identifierExpression) as IdentifierExpression => [							
							it.identifier = messageArray
							it.createChild(identifierExpression_Index, literalExpression) as LiteralExpression => [
								it.text = "0"
							]
						]
					]
				]			
			]	
		]
		return peekFunction	
	}
	
	private def createShiftFunction(MessageQueue queue, Variable messageArray, DataVariableDeclaration capacityVar, ComponentInstance owner) {
		val shiftFunction = target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = target.void
				]
				it.name = "shift" + queue.name + owner.postfix
				it.createChild(function_Block, stmPackage.block) as Block => [					
					// The declaration is a unique object, it has to be initialized
					it.createChild(block_Declarations, localDeclarations)
					// Message emptyMessage;
					val emptyMessageVar = it.declarations.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
						it.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
							it.referredType = messageStructType // Only one variable is expected
						]
					]
					emptyMessageVar.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
						it.container = emptyMessageVar
						it.name = "emptyMessage"
					]
					// int i
					val i = it.declarations.createVariable(DataVariablePrefix.NONE, target.int, "i")
					// if (..capacity == 0)
					it.createChild(block_Statement, ifStatement) as IfStatement => [
						it.createChild(ifStatement_IfExpression, compareExpression) as CompareExpression => [
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = capacityVar.variable.head
							]
							it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
								it.text = "0"
							] 	
						]
						// return;
						it.createChild(ifStatement_ThenStatement, returnStatement) as ReturnStatement
					]
					
					// for (i = 0; i < executionMessagesSize - 1; i++) {
					it.createChild(block_Statement, forLoop) as ForLoop => [
						// i = 0
						it.createChild(forLoop_Initialization, assignmentExpression) as AssignmentExpression => [							
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = i.variable.head
							]
							it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
								it.text = "0"
							] 					
						]
						// i < executionMessagesSize - 1
						it.createChild(forLoop_Condition, compareExpression) as CompareExpression => [							
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = i.variable.head
							]
							it.operator = CompareOperator.LESS
							it.createChild(binaryExpression_SecondExpr, arithmeticExpression) as ArithmeticExpression => [
								it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
									it.identifier = capacityVar.variable.head
								]
								it.operator = ArithmeticOperator.SUBTRACT
								it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
									it.text = "1"
								] 	
							]			
						]
						// i++ (default values are okay)
						it.createChild(forLoop_Iteration, incrementDecrementExpression) as IncrementDecrementExpression => [							
							it.createChild(incrementDecrementExpression_Expression, identifierExpression) as IdentifierExpression => [
								it.identifier = i.variable.head
							]	
						]
						// executionMessages[i] = executionMessages[i + 1];
						it.createChild(forLoop_Statement, expressionStatement) as ExpressionStatement => [							
							it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
								it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
									it.identifier = messageArray
									it.createChild(identifierExpression_Index, identifierExpression) as IdentifierExpression => [
										it.identifier = i.variable.head
									]
								]
								it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
									it.identifier = messageArray
									it.createChild(identifierExpression_Index, arithmeticExpression) as ArithmeticExpression => [
										it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
											it.identifier = i.variable.head
										]
										it.operator = ArithmeticOperator.ADD
										it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
											it.text = "1"
										] 	
									]		
								]
							]	
						]
					]
					// executionMessages[executionMessagesSize - 1] = emptyMessage;
					it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
						it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = messageArray
								it.createChild(identifierExpression_Index, arithmeticExpression) as ArithmeticExpression => [
									it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = capacityVar.variable.head
									]
									it.operator = ArithmeticOperator.SUBTRACT
									it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
										it.text = "1"
									] 	
								]		
							]
							it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = emptyMessageVar.variable.head
							]
						]
					]
					// ...MessagesCapacity--;
					it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
						it.createChild(expressionStatement_Expression, incrementDecrementExpression) as IncrementDecrementExpression => [	
							it.operator = IncrementDecrementOperator.DECREMENT
							it.createChild(incrementDecrementExpression_Expression, identifierExpression) as IdentifierExpression => [
								it.identifier = capacityVar.variable.head
							]
						]
					]
				]		
			]	
		]
		return shiftFunction	
	}
	
	private def createPushFunction(MessageQueue queue, Variable messageArray, DataVariableDeclaration capacityVar,
		DataVariableDeclaration sizeConst, ComponentInstance owner) {
		val pushFunction = target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = target.void
				]
				it.name = "push" + queue.name + owner.postfix
				val eventParameter = it.createChild(function_Parameter, declPackage.parameter) as Parameter
				val eventVarContainer = eventParameter.createChild(parameter_VariableDeclaration, dataVariableDeclaration) as DataVariableDeclaration
				val eventVar = eventVarContainer.createTypeAndVariable(target.int, "event")
				val valueParameter = it.createChild(function_Parameter, declPackage.parameter) as Parameter
				val valueVarContainer = valueParameter.createChild(parameter_VariableDeclaration, dataVariableDeclaration) as DataVariableDeclaration
				val valueVar = valueVarContainer.createTypeAndVariable(target.int, "value")
				it.createChild(function_Block, stmPackage.block) as Block => [					
					// The declaration is a unique object, it has to be initialized
					it.createChild(block_Declarations, localDeclarations)
					// Message emptyMessage;
					val newMessageVar = it.declarations.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
						it.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
							it.referredType = messageStructType // Only one variable is expected
						]
					]
					val newMessageVariable = newMessageVar.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
						it.container = newMessageVar
						it.name = "message"
					]
					
					// if (...MessagesCapacity < ..._SIZE) {
					it.createChild(block_Statement, ifStatement) as IfStatement => [
						// (...MessagesCapacity < ..._SIZE)
						it.createChild(ifStatement_IfExpression, compareExpression) as CompareExpression => [
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = capacityVar.variable.head
							]
							it.operator = CompareOperator.LESS
							it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = sizeConst.variable.head
							]
						]
						it.createChild(ifStatement_ThenStatement, block) as Block => [
							// message.event = event;
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
									it.createChild(binaryExpression_FirstExpr, scopedIdentifierExpression) as ScopedIdentifierExpression => [
										it.createChild(scopedIdentifierExpression_Scope, identifierExpression) as IdentifierExpression => [
											it.identifier = newMessageVariable
										]
										it.createChild(scopedIdentifierExpression_Identifier, identifierExpression) as IdentifierExpression => [
											it.identifier = messageEvent.variable.head
										]										
									]
									it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = eventVar									
									]
								]
							]
							// message.value = value;
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
									it.createChild(binaryExpression_FirstExpr, scopedIdentifierExpression) as ScopedIdentifierExpression => [
										it.createChild(scopedIdentifierExpression_Scope, identifierExpression) as IdentifierExpression => [
											it.identifier = newMessageVariable
										]
										it.createChild(scopedIdentifierExpression_Identifier, identifierExpression) as IdentifierExpression => [
											it.identifier = messageValue.variable.head
										]										
									]
									it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = valueVar								
									]
								]
							]
							// ...Messages[...MessagesCapacity] = message;
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
									it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = messageArray
										it.createChild(identifierExpression_Index, identifierExpression) as IdentifierExpression => [
											it.identifier = capacityVar.variable.head
										]		
									]
									it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = newMessageVariable
									]
								]
							]
							// ...MessagesCapacity++;
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createChild(expressionStatement_Expression, incrementDecrementExpression) as IncrementDecrementExpression => [	
									it.operator = IncrementDecrementOperator.INCREMENT
									it.createChild(incrementDecrementExpression_Expression, identifierExpression) as IdentifierExpression => [
										it.identifier = capacityVar.variable.head
									]	
								]
							]
						]
					]
				]
			]
		]
		return pushFunction
	}
	
	private def createIsFullFunction(MessageQueue queue, DataVariableDeclaration capacityVar, DataVariableDeclaration sizeConst, ComponentInstance owner) {
		val isFullFunction = target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = target.int
				]
				it.name = "is" + queue.name + "Full" + owner.postfix
				it.createChild(function_Block, stmPackage.block) as Block => [
					it.createChild(block_Statement, stmPackage.returnStatement) as ReturnStatement => [
						// ...SIZE == ...MessagesCapacity;
						it.createChild(returnStatement_ReturnExpression, compareExpression) as CompareExpression => [	
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [							
								it.identifier = sizeConst.variable.head				
							]
							it.operator = CompareOperator.EQUAL
							it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [							
								it.identifier = capacityVar.variable.head				
							]
						]
					]
				]			
			]	
		]
		return isFullFunction
	}
	
}