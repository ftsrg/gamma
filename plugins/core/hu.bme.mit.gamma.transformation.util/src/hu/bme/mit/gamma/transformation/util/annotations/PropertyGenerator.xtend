/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.annotations

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.property.model.BinaryLogicalOperator
import hu.bme.mit.gamma.property.model.CommentableStateFormula
import hu.bme.mit.gamma.property.model.PropertyModelFactory
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.property.util.PropertyUtil
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.Collections
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class PropertyGenerator {
	// Single component reference or the whole chain is needed
	// That is, we reference the model AFTER or BEFORE the unfolding 
	protected boolean isSimpleComponentReference
	protected final boolean optimizePropertyOrder = true
	//
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE
	protected final PropertyModelFactory factory = PropertyModelFactory.eINSTANCE
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE

	new(boolean isSimpleComponentReference) {
		this.isSimpleComponentReference = isSimpleComponentReference
	}

	def PropertyPackage initializePackage(Component component) {
		val propertyPackage = factory.createPropertyPackage
		val _package = component.containingPackage
		
		propertyPackage.imports += _package
		propertyPackage.component = component
		
		return propertyPackage
	}

	def List<CommentableStateFormula> createStateReachability(Iterable<? extends SynchronousComponentInstance> instances) {
		var List<CommentableStateFormula> formulas = newArrayList
		for (SynchronousComponentInstance instance : instances) {
			val type = instance.type
			if (type instanceof StatechartDefinition) {
				val states = type.allStates
				formulas += states.createStateReachabilityFormulas
			}
		}
		// Order optimization - "further" nodes are put earlier in the list
		if (optimizePropertyOrder) {
			val nodeDistances = newLinkedHashMap
			for (statechart : instances.map[it.derivedType].filter(StatechartDefinition)) {
				nodeDistances += statechart.containedStateNodeDistances
			}
			formulas = formulas.sortBy[nodeDistances.getOrDefault(it
					.getAllContentsOfType(ComponentInstanceStateReferenceExpression)
					.onlyElement
					.state, 0 /* Default 0 for unreachable nodes? */)]
					.reverse
		}
		//
		return formulas
	}
	
	def List<CommentableStateFormula> createStateReachabilityFormulas(Iterable<? extends State> states) {
		val formulas = newArrayList
		for (state : states) {
			val instance = state.containingComponent.referencingComponentInstance
			val stateReference = compositeFactory.createComponentInstanceStateReferenceExpression
			val parentRegion = StatechartModelDerivedFeatures.getParentRegion(state)
			stateReference.setInstance(instance.createInstanceReference)
			stateReference.setRegion(parentRegion)
			stateReference.setState(state)
			val stateFormula = propertyUtil.createEF(propertyUtil.createAtomicFormula(stateReference))
			val commentableStateFormula = propertyUtil.createCommentableStateFormula(
					'''«instance.name».«parentRegion.name».«state.name»''', stateFormula)
			formulas += commentableStateFormula
		}
		
		return formulas
	}
	
	def List<CommentableStateFormula> createUnstableStateInvariance(Iterable<? extends State> states) {
		val formulas = newArrayList
		for (state : states) { // A G(state -> (X !(state)))
			val instance = state.containingComponent.referencingComponentInstance
			val stateReference = compositeFactory.createComponentInstanceStateReferenceExpression
			val parentRegion = StatechartModelDerivedFeatures.getParentRegion(state)
			stateReference.setInstance(instance.createInstanceReference)
			stateReference.setRegion(parentRegion)
			stateReference.setState(state)
			val stateReferenceFormula = propertyUtil.createAtomicFormula(stateReference)
			val notStateReferenceFormula = stateReferenceFormula.clone => [
				it.expression = propertyUtil.createNotExpression(it.expression)
			]
			
			val implication = factory.createBinaryOperandLogicalPathFormula => [
				it.leftOperand = stateReferenceFormula
				it.operator = BinaryLogicalOperator.IMPLY
				it.rightOperand = propertyUtil.createX(notStateReferenceFormula)
			] // state -> (X !(state))
			
			val stateFormula = propertyUtil.createAG(implication) // A G(state -> (X !(state)))
			
			val commentableStateFormula = propertyUtil.createCommentableStateFormula(
					'''Is «instance.name».«parentRegion.name».«state.name» an unstable state?''', stateFormula)
			formulas += commentableStateFormula
		}
		
		return formulas
	}
	
	def List<CommentableStateFormula> createTrapStateInvariance(Iterable<? extends State> states) {
		val formulas = newArrayList
		for (state : states) { // A G(state -> (G state)) - note that 'loop transitions' can still fire!
			val instance = state.containingComponent.referencingComponentInstance
			val stateReference = compositeFactory.createComponentInstanceStateReferenceExpression
			val parentRegion = StatechartModelDerivedFeatures.getParentRegion(state)
			stateReference.setInstance(instance.createInstanceReference)
			stateReference.setRegion(parentRegion)
			stateReference.setState(state)
			val stateReferenceFormula = propertyUtil.createAtomicFormula(stateReference)
			val stateReferenceFormula2 = stateReferenceFormula.clone
			
			val implication = factory.createBinaryOperandLogicalPathFormula => [
				it.leftOperand = stateReferenceFormula
				it.operator = BinaryLogicalOperator.IMPLY
				it.rightOperand = propertyUtil.createG(stateReferenceFormula2)
			] // state -> G (state)
			
			val stateFormula = propertyUtil.createAG(implication) // A G(state -> G (state))
			
			val commentableStateFormula = propertyUtil.createCommentableStateFormula(
					'''Is «instance.name».«parentRegion.name».«state.name» a trap state?''', stateFormula)
			formulas += commentableStateFormula
		}
		
		return formulas
	}
	
	def List<CommentableStateFormula> createDeadlockInvariance(TransitionAnnotations transitionAnnotations) {
		val formulas = newArrayList
		
		val transitions = transitionAnnotations.transitions
		val leafStates = transitions.map[it.sourceState].filter(State).filter[!it.composite].toSet
		for (leafState : leafStates) {
			val consideredStates = leafState.ancestorsAndSelf
			val allOutgoingTransitions = transitions.filter[consideredStates.contains(it.sourceState)].toSet
			val variables = allOutgoingTransitions.map[transitionAnnotations.getVariable(it)].toSet
			
			if (!variables.empty) {  // A G(state -> (G (!outgoingTransitionFireable1 && .. && !outgoingTransitionFireableN))
				val unfireableTransitionsExpression = propertyUtil.wrapIntoAndExpression( // (!outgoingTransitionFireable1 && .. && !outgoingTransitionFireableN)
						variables.map[it.createVariableReference.createNotExpression].toList)
				
				val stateReference = compositeFactory.createComponentInstanceStateReferenceExpression
				val instance = leafState.containingComponent.referencingComponentInstance
				val parentRegion = StatechartModelDerivedFeatures.getParentRegion(leafState)
				stateReference.setInstance(instance.createInstanceReference)
				stateReference.setRegion(parentRegion)
				stateReference.setState(leafState)
				val stateReferenceFormula = propertyUtil.createAtomicFormula(stateReference)
				val unfireableTransitionsFormula = propertyUtil.createAtomicFormula(unfireableTransitionsExpression)
				
				val implication = factory.createBinaryOperandLogicalPathFormula => [
					it.leftOperand = stateReferenceFormula
					it.operator = BinaryLogicalOperator.IMPLY
					it.rightOperand = propertyUtil.createG(unfireableTransitionsFormula)
				] // state -> G (!outgoingTransitionFireable1 && .. && !outgoingTransitionFireableN)
				
				val stateFormula = propertyUtil.createAG(implication) // A G(state -> (G (!outgoingTransitionFireable1 && .. && !outgoingTransitionFireableN))
				
				val commentableStateFormula = propertyUtil.createCommentableStateFormula(
						'''Is «instance.name».«parentRegion.name».«leafState.name» a deadlock state?''', stateFormula)
				formulas += commentableStateFormula
			}
		}
		
		return formulas
	}
	
	def List<CommentableStateFormula> createOutEventReachability(Iterable<? extends Port> ports) {
		val List<CommentableStateFormula> formulas = newArrayList
		for (notNecessarilySimplePort : ports) {
			for (port : notNecessarilySimplePort.allBoundSimplePorts) {
				val instance = port.containingComponentInstance
				for (outEvent : StatechartModelDerivedFeatures.getOutputEvents(port)) {
					val parameters = outEvent.parameterDeclarations
					if (parameters.empty) {
						val eventReference = propertyUtil.createEventReference(
								createInstanceReference(instance), port, outEvent)
						val stateFormula = propertyUtil.createEF(
								propertyUtil.createAtomicFormula(eventReference))
						val commentableStateFormula = propertyUtil.createCommentableStateFormula(
								'''«instance.name».«port.name».«outEvent.name»''', stateFormula)
						formulas += commentableStateFormula
					}
					else {
						for (parameter : parameters) {
							val parameterValues = getValues(parameter)
							// Only bool and enum
							if (parameterValues.empty) {
								// E.g., integers - plain event
								val eventReference = propertyUtil.createEventReference(
										createInstanceReference(instance), port, outEvent)
								val stateFormula = propertyUtil.createEF(
										propertyUtil.createAtomicFormula(eventReference))
								val commentableStateFormula = propertyUtil.createCommentableStateFormula(
										'''«instance.name».«port.name».«outEvent.name»''', stateFormula)
								formulas += commentableStateFormula
							}
							else {
								for (value : parameterValues) {
									val eventReference = propertyUtil.createEventReference(
											createInstanceReference(instance), port, outEvent)
									val parameterReference = propertyUtil.createParameterReference(
											createInstanceReference(instance), port, outEvent, parameter)
									val equalityExpression = parameterReference.createEqualityExpression(value)
									val and = expressionFactory.createAndExpression
									and.operands += eventReference
									and.operands += equalityExpression
									val stateFormula = propertyUtil.createEF(
											propertyUtil.createAtomicFormula(and))
									val commentableStateFormula = propertyUtil.createCommentableStateFormula(
										'''«instance.name».«port.name».«outEvent.name».«parameter.name» == «expressionSerializer.serialize(value)»''',
											stateFormula)
									formulas += commentableStateFormula
								}
							}
						}
					}
				}
			}
		}
		return formulas
	}

	def protected Set<Expression> getValues(ParameterDeclaration parameter) {
		val typeDefinition = StatechartModelDerivedFeatures.getTypeDefinition(parameter.type)
		if (typeDefinition instanceof BooleanTypeDefinition) {
			return Set.of(expressionFactory.createTrueExpression, expressionFactory.createFalseExpression)
		}
		else if (typeDefinition instanceof EnumerationTypeDefinition) {
			val Set<Expression> literals = newHashSet
			for (literal : typeDefinition.literals) {
				val expression = literal.createEnumerationLiteralExpression
				literals += expression
			}
			return literals
		}
		return Collections.emptySet
	}

	def List<CommentableStateFormula> createTransitionReachability(TransitionAnnotations transitionAnnotations) {
		val List<CommentableStateFormula> formulas = newArrayList
		if (transitionAnnotations.empty) {
			return formulas
		}
		// Order optimization - "further" transitions are put earlier in the list - makes sense if there is no slicing
		var List<Transition> transitions = newArrayList
		transitions += transitionAnnotations.transitions
		if (optimizePropertyOrder) {
			val transitionDistances = newLinkedHashMap
			for (statechart : transitions.map[it.containingStatechart].toSet) {
				transitionDistances += statechart.containedTransitionDistances
			}
			transitions = transitions.sortBy[transitionDistances.getOrDefault(it,
					0 /* Default 0 for unreachable transitions? */)]
					.reverse
		}
		//
		for (transition : transitions) {
			val variable = transitionAnnotations.getVariable(transition)
			val reference = createVariableReference(variable)
			val stateFormula = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(reference))
			// Comment
			val commentableStateFormula = propertyUtil.createCommentableStateFormula(
					getId(transition), stateFormula)
			formulas += commentableStateFormula
		}
		return formulas
	}

	def protected ComponentInstanceVariableReferenceExpression createVariableReference(
			VariableDeclaration variable) {
		val statechart = StatechartModelDerivedFeatures.getContainingStatechart(variable)
		val instance = StatechartModelDerivedFeatures.getReferencingComponentInstance(statechart)
		val reference = propertyUtil.createVariableReference(
				createInstanceReference(instance), variable)
		return reference
	}

	def List<CommentableStateFormula> createTransitionPairReachability(
			List<? extends TransitionPairAnnotation> transitionPairAnnotations) {
		val List<CommentableStateFormula> formulas = newArrayList
		if (transitionPairAnnotations.empty) {
			return formulas
		}
		for (transitionPairAnnotation : transitionPairAnnotations) {
			val incomingAnnotation = transitionPairAnnotation.incomingAnnotation
			val outgoingAnnotation = transitionPairAnnotation.outgoingAnnotation
			
			val firstTransition = incomingAnnotation.transition
			val secondTransition = outgoingAnnotation.transition
			val firstVariable = incomingAnnotation.transitionVariable
			val secondVariable = outgoingAnnotation.transitionVariable
			val firstId = incomingAnnotation.transitionId
			val secondId = outgoingAnnotation.transitionId
			
			// In-out transition pair
			val and = expressionFactory.createAndExpression => [
				it.operands += firstVariable.createEqualityExpression(firstId)
				it.operands += secondVariable.createEqualityExpression(secondId)
			]
			val stateFormula = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(and))
			// Comment
			var String comment = '''«getId(firstTransition)» -p- «getId(secondTransition)»'''
			val commentableStateFormula = propertyUtil.createCommentableStateFormula(comment, stateFormula)
			formulas += commentableStateFormula
		}
		return formulas
	}

	def List<CommentableStateFormula> createInteractionReachability(InteractionAnnotations interactionAnnotations) {
		val List<CommentableStateFormula> formulas = newArrayList
		val sameIdExpressions = newHashMap
		if (interactionAnnotations.empty) {
			return formulas
		}
		for (interaction : interactionAnnotations.uniqueInteractions) {
			val sender = interaction.sender
			val receiver = interaction.receiver
			val variablePair = interaction.variablePair
			val senderVariable = variablePair.first
			val senderId = interaction.senderId
			val receiverVariable = variablePair.second
			val receiverId = interaction.receiverId
			//
			val senderComment = sender.id
			var receiverComment = "<any>"
			var Expression finalExpression = null
			// Sender
			val senderEqualityExpression = senderVariable.createEqualityExpression(senderId)
			finalExpression = senderEqualityExpression
			// Receiver
			if (variablePair.hasSecond) {
				val receiverEqualityExpression = receiverVariable.createEqualityExpression(receiverId)
				finalExpression = expressionFactory.createAndExpression => [
					it.operands += senderEqualityExpression
					it.operands += receiverEqualityExpression
				]
				receiverComment = receiver.id
			}
			else {
				// Saving the expression to the id: in this case same identifiers have to be handled together
				// Needed when: RECEIVER_CONSIDERATION is false and there are complex triggers 
				val sameIdList = sameIdExpressions.getOrCreateList(senderId)
				sameIdList += finalExpression
			}
			//
			val stateFormula = propertyUtil.createEF(
						propertyUtil.createAtomicFormula(finalExpression))
			// Comment
			val commentableStateFormula = propertyUtil.createCommentableStateFormula(
					'''«senderComment» -i- «receiverComment»''', stateFormula)
			formulas += commentableStateFormula
		}
		
		// Post-processing same id expressions if necessary
		for (id : sameIdExpressions.keySet) {
			val expressions = sameIdExpressions.get(id)
			val expression = expressions.get(0)
			for (var i = 1; i < expressions.size; i++) {
				val duplicatedExpression = expressions.get(i)
				
				val containerFormula = duplicatedExpression.getContainerOfType(CommentableStateFormula)
				formulas -= containerFormula // Removing the formula form the list
				
				expression.replaceAndWrapIntoMultiaryExpression(duplicatedExpression, expressionFactory.createAndExpression)
			}
		}
		
		return formulas
	}
	
	def List<CommentableStateFormula> createDataflowReachability(
			Map<DefReferenceId, Set<UseVariable>> defUses, DataflowCoverageCriterion criterion) {
		val List<CommentableStateFormula> formulas = newArrayList
		if (defUses.empty) {
			return formulas
		}
		for (id : defUses.keySet) {
			val defId = id.defId
			val defReference = id.defReference
			val defComment = defReference.id
			val uses = defUses.get(id)
			if (criterion == DataflowCoverageCriterion.ALL_DEF) {
				val expressions = <Expression>newArrayList
				val useReferences = newArrayList
				for (use : uses) {
					val useVariable = use.useVariable
					expressions += useVariable.createEqualityExpression(defId)
					useReferences += use.useReference
				}
				val orExpression = expressions.wrapIntoMultiaryExpression(
						expressionFactory.createOrExpression)
				val useComment = useReferences.ids
				val stateFormula = propertyUtil.createEF(
						propertyUtil.createAtomicFormula(orExpression))
				formulas += propertyUtil.createCommentableStateFormula(
						'''«defComment» -d-u- «useComment»''', stateFormula)
			}
			else {
				for (use : uses) {
					val useVariable = use.useVariable
					val useComment = use.useReference.id
					val idEquality = useVariable.createEqualityExpression(defId)
					val stateFormula = propertyUtil.createEF(
							propertyUtil.createAtomicFormula(idEquality))
					formulas += propertyUtil.createCommentableStateFormula(
							'''«defComment» -d-u- «useComment»''', stateFormula)
				}
			}
		}
		return formulas
	}
	
	def List<CommentableStateFormula> createInteractionDataflowReachability(
			Map<DefReferenceId, Set<UseVariable>> defUses, DataflowCoverageCriterion criterion) {
		return defUses.createDataflowReachability(criterion)
	}
	
	def protected createEqualityExpression(VariableDeclaration variable, Long id) {
		val reference = variable.createVariableReference
		val literal = id.toIntegerLiteral
		return reference.createEqualityExpression(literal)
	}
	
	
	def protected ComponentInstanceReferenceExpression createInstanceReference(ComponentInstance instance) {
		if (isSimpleComponentReference) {
			return statechartUtil.createInstanceReference(instance)
		}
		else {
			return statechartUtil.createInstanceReferenceChain(instance)
		}
	}

	// Comments
	
	def protected String getInstanceId(EObject object) {
		val statechart = StatechartModelDerivedFeatures.getContainingStatechart(object)
		try {
			val instance = StatechartModelDerivedFeatures.getReferencingComponentInstance(statechart)
			return instance.name
		} catch (IllegalArgumentException e) {
			return ""
		}
	}

	def dispatch protected String getId(RaiseEventAction action) {
		val transition = ecoreUtil.getContainerOfType(action, Transition)
		if (transition === null) {
			val state = ecoreUtil.getContainerOfType(action, State)
			if (state === null) {
				throw new IllegalArgumentException('''Not known raise event: «action»''')
			}
			val containmentFeatureName = action.eContainmentFeature.name
			return '''«getId(state)»-«containmentFeatureName»'''
		}
		return getId(transition)
	}

	def dispatch protected String getId(StateNode state) {
		return '''«getInstanceId(state)».«state.parentRegion.name».«state.name»'''
	}

	def dispatch protected String getId(Transition transition) {
		return '''«transition.sourceState.id» --> «transition.targetState.id»'''
	}
	
	def dispatch protected String getId(DirectReferenceExpression reference) {
		val transitionOrState = reference.containingTransitionOrState
		val variable = reference.declaration
		return '''«transitionOrState.id»::«variable.name»'''
	}
	
	def dispatch protected String getId(EventParameterReferenceExpression reference) {
		val transitionOrState = reference.containingTransitionOrState
		val port = reference.port
		val event = reference.event
		val parameter = reference.parameter
		return '''«transitionOrState.id»::«port.name».«event.name»::«parameter.name»'''
	}
	
	def protected String getIds(Iterable<? extends Expression> references) {
		return '''«FOR reference : references SEPARATOR ' | '»«reference.id»«ENDFOR»'''
	}
	
}