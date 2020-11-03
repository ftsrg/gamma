/** 
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * SPDX-License-Identifier: EPL-1.0
 */
package hu.bme.mit.gamma.transformation.util.annotations

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.property.model.CommentableStateFormula
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.property.model.PropertyModelFactory
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.property.util.PropertyUtil
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.transformation.util.annotations.GammaStatechartAnnotator.InteractionAnnotations
import hu.bme.mit.gamma.transformation.util.annotations.GammaStatechartAnnotator.TransitionAnnotations
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.List
import java.util.Set
import org.eclipse.emf.ecore.EObject

class PropertyGenerator {
	// Single component reference or the whole chain is needed
	// That is, we reference the model AFTER or BEFORE the unfolding 
	protected boolean isSimpleComponentReference
	//
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE
	protected final PropertyModelFactory factory = PropertyModelFactory.eINSTANCE
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE

	new(boolean isSimpleComponentReference) {
		this.isSimpleComponentReference = isSimpleComponentReference
	}

	def PropertyPackage initializePackage(Component component) {
		val PropertyPackage propertyPackage = factory.createPropertyPackage()
		val Package _package = StatechartModelDerivedFeatures.getContainingPackage(component)
		propertyPackage.getImport() += _package
		propertyPackage.setComponent(component)
		return propertyPackage
	}

	def List<CommentableStateFormula> createStateReachability(Collection<SynchronousComponentInstance> instances) {
		val List<CommentableStateFormula> formulas = newArrayList
		for (SynchronousComponentInstance instance : instances) {
			val Component type = instance.type
			if (type instanceof StatechartDefinition) {
				for (state : StatechartModelDerivedFeatures.getAllStates(type)) {
					val stateReference = factory.createComponentInstanceStateConfigurationReference
					val parentRegion = StatechartModelDerivedFeatures.getParentRegion(state)
					stateReference.setInstance(createInstanceReference(instance))
					stateReference.setRegion(parentRegion)
					stateReference.setState(state)
					val stateFormula = propertyUtil.createEF(propertyUtil.createAtomicFormula(stateReference))
					val commentableStateFormula = propertyUtil.
						createCommentableStateFormula('''«instance.name».«parentRegion.name».«state.name»''',
							stateFormula)
					formulas += commentableStateFormula
				}
			}
		}
		return formulas
	}

	def List<CommentableStateFormula> createOutEventReachability(Component component,
			Collection<SynchronousComponentInstance> instances) {
		val Collection<Port> simplePorts = StatechartModelDerivedFeatures.getAllConnectedSimplePorts(component)
		val List<CommentableStateFormula> formulas = newArrayList
		for (instance : instances) {
			val Component type = instance.type
			val List<Port> ports = new ArrayList<Port>(type.ports)
			ports.retainAll(simplePorts)
			// Only that are led out to the system port
			for (port : ports) {
				for (outEvent : StatechartModelDerivedFeatures.getOutputEvents(port)) {
					val parameters = outEvent.parameterDeclarations
					if (parameters.empty) {
						val eventReference = propertyUtil.createEventReference(
							createInstanceReference(instance), port, outEvent)
						val stateFormula = propertyUtil.createEF(propertyUtil.createAtomicFormula(eventReference))
						val commentableStateFormula = propertyUtil.
							createCommentableStateFormula('''«instance.name».«port.name».«outEvent.name»''',
								stateFormula)
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
								val stateFormula = propertyUtil.createEF(propertyUtil.createAtomicFormula(eventReference))
								val commentableStateFormula = propertyUtil.
									createCommentableStateFormula('''«instance.name».«port.name».«outEvent.name»''',
										stateFormula)
								formulas += commentableStateFormula
							}
							else {
								for (value : parameterValues) {
									val eventReference = propertyUtil.
										createEventReference(createInstanceReference(instance), port, outEvent)
									val parameterReference = propertyUtil.
										createParameterReference(createInstanceReference(instance), port, outEvent,
											parameter)
									val equalityExpression = expressionFactory.createEqualityExpression
									equalityExpression.setLeftOperand(parameterReference)
									equalityExpression.setRightOperand(value)
									val and = expressionFactory.createAndExpression
									and.operands += eventReference
									and.operands += equalityExpression
									val stateFormula = propertyUtil.createEF(propertyUtil.createAtomicFormula(and))
									val commentableStateFormula = propertyUtil.
										createCommentableStateFormula('''«instance.name».«port.name».«outEvent.name».«parameter.name» == «expressionSerializer.serialize(value)»''',
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
				val expression = expressionFactory.createEnumerationLiteralExpression
				expression.setReference(literal)
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
		for (transition : transitionAnnotations.transitions) {
			val variable = transitionAnnotations.getVariable(transition)
			val reference = createVariableReference(variable)
			val stateFormula = propertyUtil.createEF(propertyUtil.createAtomicFormula(reference))
			// Comment
			val commentableStateFormula = propertyUtil.
				createCommentableStateFormula(getId(transition), stateFormula)
			formulas += commentableStateFormula
		}
		return formulas
	}

	def protected ComponentInstanceVariableReference createVariableReference(VariableDeclaration variable) {
		val statechart = StatechartModelDerivedFeatures.getContainingStatechart(variable)
		val instance = StatechartModelDerivedFeatures.getReferencingComponentInstance(statechart)
		val reference = propertyUtil.createVariableReference(
			createInstanceReference(instance), variable)
		return reference
	}

	def List<CommentableStateFormula> createTransitionPairReachability(TransitionAnnotations transitionAnnotations) {
		val List<CommentableStateFormula> formulas = newArrayList
		if (transitionAnnotations.empty) {
			return formulas
		}
		val transitions = transitionAnnotations.transitions.toList
		val size = transitions.size
		for (var int i = 0; i < size - 1; i++) {
			val lhsTransition = transitions.get(i)
			for (var int j = i; /* This way loop edges are checked too */ j < size; j++) {
				val rhsTransition = transitions.get(j)
				val lhsSource = lhsTransition.sourceState
				val lhsTarget = lhsTransition.targetState
				val rhsSource = rhsTransition.sourceState
				val rhsTarget = rhsTransition.targetState
				if (lhsTarget === rhsSource || rhsTarget === lhsSource) {
					var Transition firstTransition
					var Transition secondTransition
					// Order
					if (lhsTarget === rhsSource) {
						firstTransition = lhsTransition
						secondTransition = rhsTransition
					}
					else {
						firstTransition = rhsTransition
						secondTransition = lhsTransition
					}
					val firstVariable = transitionAnnotations.getVariable(firstTransition)
					val secondVariable = transitionAnnotations.getVariable(secondTransition)
					// In-out transition pair
					val and = expressionFactory.createAndExpression
					and.operands += createVariableReference(firstVariable)
					and.operands += createVariableReference(secondVariable)
					val stateFormula = propertyUtil.createEF(propertyUtil.createAtomicFormula(and))
					// Comment
					var String comment = '''«getId(firstTransition)» -p- «getId(secondTransition)»'''
					val commentableStateFormula = propertyUtil.createCommentableStateFormula(comment, stateFormula)
					formulas += commentableStateFormula
				}
			}
		}
		return formulas
	}

	def List<CommentableStateFormula> createInteractionReachability(InteractionAnnotations interactionAnnotations) {
		val List<CommentableStateFormula> formulas = newArrayList
		if (interactionAnnotations.empty) {
			return formulas
		}
		for (interaction : interactionAnnotations.interactions) {
			val senderVariable = interaction.senderVariable
			val senderId = interaction.senderId
			val receiverVariable = interaction.receiverVariable
			val receiverId = interaction.receiverId
			// Sender - note that the sender statechart and instance are the same as the receiving one,
			// the senderVariable and receiverVariable are stored in the same statechart (receiverStatechart)
			// Duplicated this part to make it more resilient (if the variables in the future are stored somewhere else)
			val senderEqualityExpression = expressionFactory.createEqualityExpression
			val senderReference = createVariableReference(senderVariable)
			val senderLiteral = expressionFactory.createIntegerLiteralExpression
			senderLiteral.setValue(BigInteger.valueOf(senderId))
			senderEqualityExpression.setLeftOperand(senderReference)
			senderEqualityExpression.setRightOperand(senderLiteral)
			// Receiver
			val receiverEqualityExpression = expressionFactory.createEqualityExpression
			val receiverReference = createVariableReference(receiverVariable)
			val receiverLiteral = expressionFactory.createIntegerLiteralExpression
			receiverLiteral.setValue(BigInteger.valueOf(receiverId))
			receiverEqualityExpression.setLeftOperand(receiverReference)
			receiverEqualityExpression.setRightOperand(receiverLiteral)
			val andExpression = expressionFactory.createAndExpression
			andExpression.operands += senderEqualityExpression
			andExpression.operands += receiverEqualityExpression
			val stateFormula = propertyUtil.createEF(propertyUtil.createAtomicFormula(andExpression))
			// Comment
			val source = interaction.sender
			val target = interaction.receiver
			val commentableStateFormula = propertyUtil.
				createCommentableStateFormula('''«getId(source)» -i- «getId(target)»''', stateFormula)
			formulas += commentableStateFormula
		}
		return formulas
	}

	def protected ComponentInstanceReference createInstanceReference(ComponentInstance instance) {
		if (isSimpleComponentReference) {
			val reference = compositeFactory.createComponentInstanceReference
			reference.componentInstanceHierarchy += instance
			return reference
		} else {
			return statechartUtil.createInstanceReference(instance)
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

	def protected String getId(RaiseEventAction action) {
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

	def protected String getId(State state) {
		return '''«getInstanceId(state)».«StatechartModelDerivedFeatures.getParentRegion(state).name».«state.name»'''
	}

	def protected String getId(Transition transition) {
		return '''«getInstanceId(transition)».«transition.sourceState.name» --> «getInstanceId(transition)».«transition.targetState.name»'''
	}
}
