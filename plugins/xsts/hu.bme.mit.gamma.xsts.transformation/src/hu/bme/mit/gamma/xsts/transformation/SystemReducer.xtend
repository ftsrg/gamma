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
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.EquivalenceExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.PredicateExpression
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.UnremovableVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.XstsOptimizer
import hu.bme.mit.gamma.property.derivedfeatures.PropertyModelDerivedFeatures
import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.CommentableStateFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.Map
import java.util.logging.Logger

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class SystemReducer {
	// Singleton
	public static final SystemReducer INSTANCE =  new SystemReducer
	protected new() {}
	// Auxiliary objects
	protected final extension XstsOptimizer xStsOptimizer = XstsOptimizer.INSTANCE
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE
	protected final extension CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	// Logger
	protected final Logger logger = Logger.getLogger("GammaLogger")
	// TODO Introduce EventReferenceToXstsVariableMapper
	
	def void deleteUnusedPorts(XSTS xSts, CompositeComponent component) {
		// In theory, only AssignmentAction would be enough, still we use AbstractAssignmentAction to be sure
		val xStsAssignmentActions = xSts.getAllContentsOfType(AbstractAssignmentAction) // Caching
		val xStsDefaultableVariables = newHashSet
		val xStsDeletableVariables = newHashSet
		val xStsDeletableAssignmentActions = newHashSet
		for (instance : component.derivedComponents) {
			for (instancePort : instance.unusedPorts) {
				// In events on required port
				for (inputEvent : instancePort.inputEvents) {
					val inEventName = inputEvent.customizeInputName(instancePort, instance)
					val xStsInEventVariable = xSts.getVariable(inEventName)
					if (xStsInEventVariable !== null) {
						xStsDefaultableVariables += xStsInEventVariable
						xStsDeletableVariables += xStsInEventVariable
						xStsDeletableAssignmentActions += xStsInEventVariable.getAssignments(xStsAssignmentActions)
						// In-parameters
						for (parameter : inputEvent.parameterDeclarations) {
							val inParamaterNames = parameter.customizeInNames(instancePort, instance)
							val xStsInParameterVariables = xSts.getVariables(inParamaterNames)
							if (!xStsInParameterVariables.nullOrEmpty) {
								xStsDefaultableVariables += xStsInParameterVariables
								xStsDeletableVariables += xStsInParameterVariables
								xStsDeletableAssignmentActions += xStsInParameterVariables
										.getAssignments(xStsAssignmentActions)
							}
						}
					}
				}
				for (outputEvent : instancePort.outputEvents) {
					val outEventName = outputEvent.customizeOutputName(instancePort, instance)
					val xStsOutEventVariable = xSts.getVariable(outEventName)
					if (xStsOutEventVariable !== null) {
						xStsDeletableVariables += xStsOutEventVariable
						xStsDeletableAssignmentActions += xStsOutEventVariable.getAssignments(xStsAssignmentActions)
						// Out-parameters
						for (parameter : outputEvent.parameterDeclarations) {
							val outParamaterNames = parameter.customizeOutNames(instancePort, instance)
							val xStsOutParameterVariables = xSts.getVariables(outParamaterNames)
							if (!xStsOutParameterVariables.nullOrEmpty) {
								xStsDeletableVariables += xStsOutParameterVariables
								xStsDeletableAssignmentActions += xStsOutParameterVariables.getAssignments(xStsAssignmentActions)
							}
						}
					}
				}
			}
		}
		// Assignment removal is before falsification, as ReferenceExpressions
		// can be placed inside assignment actions, and the other way around,
		// cast exceptions are thrown!
		for (xStsDeletableAssignmentAction : xStsDeletableAssignmentActions) {
			createEmptyAction.replace(
				xStsDeletableAssignmentAction) // To avoid nullptrs
		}
		// Deleting references to the input event variables in guards
		// before variable removal as references must be present here
		val xStsDirectReferenceExpressions = xSts.getAllContentsOfType(DirectReferenceExpression)
		for (xStsDefaultableVariable : xStsDefaultableVariables) {
			val references = xStsDirectReferenceExpressions
					.filter[it.declaration === xStsDefaultableVariable]
			for (reference : references) {
				val defaultExpression = xStsDefaultableVariable.defaultExpression
				defaultExpression.replace(reference)
			}
		}
		for (xStsDeletableVariable : xStsDeletableVariables) {
			xStsDeletableVariable.delete // Delete needed due to e.g., transientVariables list
		}
	}
	
	//
	
	def void deleteUnnecessaryStates(XSTS xSts, CommentableStateFormula formula,
			Map<State, Collection<State>> reachableStates) {
		val stateFormula = formula.formula
		xSts.deleteUnnecessaryStates(stateFormula, reachableStates)
	}
	
	def void deleteUnnecessaryStates(XSTS xSts, StateFormula formula,
			Map<State, Collection<State>> reachableStates) {
		if (PropertyModelDerivedFeatures.isInvariant(formula)) {
			val checkableStateReferences = newArrayList // Only individual state coverage, i.e., not supported: EF (a.State1 || b.State2)
			
			val atomicFormulas = ecoreUtil.getSelfAndAllContentsOfType(formula, AtomicFormula)
			// Individual state coverage
			val stateReferences = ecoreUtil.getSelfAndAllContentsOfType(atomicFormulas,
					ComponentInstanceStateReferenceExpression)
			if (stateReferences.size == 1) {
				checkableStateReferences += stateReferences
			}
			else {
				// Variable-related coverage
				val variableReferences = ecoreUtil.getSelfAndAllContentsOfType(atomicFormulas,
						ComponentInstanceVariableReferenceExpression)
				var ComponentInstanceReferenceExpression instanceReference
				val assignmentsToVariables = newArrayList
				if (variableReferences.size == 1) {
					val variableReference = variableReferences.head
					val variable = variableReference.variableDeclaration
					instanceReference = variableReference.instance
					val statechart = variable.containingStatechart
					val assignments = statechart.getContentsOfType(AssignmentStatement)
					
					assignmentsToVariables += assignments.filter[it.lhs.declaration === variable]
				}
				else if (variableReferences.size == 2) {
					val variableReferenceLhs = variableReferences.head
					val variableLhs = variableReferenceLhs.variableDeclaration
					val variableReferenceRhs = variableReferences.last
					val variableRhs = variableReferenceRhs.variableDeclaration
					
					val statechart = variableLhs.containingStatechart
					if (statechart === variableRhs.containingStatechart) {
						instanceReference = variableReferenceLhs.instance
						val assignments = statechart.getContentsOfType(AssignmentStatement)
						
						assignmentsToVariables += assignments.filter[
								it.lhs.declaration === variableLhs || it.lhs.declaration === variableRhs]
					}
				}
				if (instanceReference !== null) { // We found 
					var StateNode stateNode = null
					//
					if (assignmentsToVariables.size == 1) { // Transition-coverage
						val assignmentsToVariable = assignmentsToVariables.head
						stateNode = assignmentsToVariable.containingOrSourceStateNode
					}
					else if (assignmentsToVariables.size == 2) {
						val containingOrSourceStateNodes = assignmentsToVariables.map[it.containingOrSourceStateNode].toSet
						if (containingOrSourceStateNodes.size == 1) {
							stateNode = containingOrSourceStateNodes.head
						}
						else {
							val containingStates = assignmentsToVariables.map[it.getContainerOfType(State)]
							val containingTransitions = assignmentsToVariables.map[it.getContainerOfType(Transition)]
							if (containingTransitions.size == 2) {
								val transitionLhs = containingTransitions.head
								val transitionRhs = containingTransitions.last
								val connectingNode = transitionLhs.getConnectingStateNode(transitionRhs)
								
								if (connectingNode !== null) {
									stateNode = connectingNode
								}
							}
							else if (containingStates.size == 1 && containingTransitions.size == 1) {
								val state = containingStates.head
								val transition = containingTransitions.head
								
								if (state.areConnected(transition)) {
									stateNode = state
								}
							}
						}
					}
					// Did we find a single state (stateNode non-null)?
					if (stateNode instanceof State) {
						val stateReference = createComponentInstanceStateReferenceExpression
						stateReference.instance = instanceReference.clone
						stateReference.region = stateNode.parentRegion
						stateReference.state = stateNode
						
						checkableStateReferences += stateReference
					}
				}
			}
			//
			
			for (stateReference : checkableStateReferences) {
				val instance = stateReference.instance
				val state = stateReference.state
				val topRegion = state.topRegion
				val allStates = topRegion.allStates
				
				val unreachableFromStates = newHashSet
				for (aState : allStates) {
					val reachableStatesFromAState = reachableStates.get(aState)
					if (!reachableStatesFromAState.contains(state)) {
						unreachableFromStates += aState
					}
				}
				logger.info("State " + state.name + " is unreachable from states: " + unreachableFromStates.map[it.name].join(", "))
				
				val xStsLiteralPredicates = newArrayList
				val xStsLiteralAssignments = newArrayList
				
				if (!unreachableFromStates.empty) {
					xStsLiteralPredicates += xSts.getAllContentsOfType(EnumerationLiteralExpression)
							.map[it.eContainer].filter(EquivalenceExpression).filter(BinaryExpression)
					xStsLiteralAssignments += xSts.getAllContentsOfType(AssignmentAction)
							.filter[it.rhs instanceof EnumerationLiteralExpression]
				}
				
				for (unreachableState : unreachableFromStates) {
					val region = StatechartModelDerivedFeatures.getParentRegion(unreachableState)
					
					val xStsVariableName = region.customizeName(instance)
					val xStsLiteralName = unreachableState.customizeName
					
					val xStsVariable = xSts.getVariable(xStsVariableName)
					
					// Setting the predicates to false
					for (xStsLiteralPredicate : xStsLiteralPredicates) {
						val lhs = xStsLiteralPredicate.leftOperand
						val rhs = xStsLiteralPredicate.rightOperand
						
						var remove = false
						
						if (lhs instanceof EnumerationLiteralExpression) {
							if (lhs.reference.name == xStsLiteralName) {
								remove = true
							}
						}
						else if (rhs instanceof EnumerationLiteralExpression) {
							if (rhs.reference.name == xStsLiteralName) {
								remove = true
							}
						}
						
						if (remove) {
							createFalseExpression.replace(xStsLiteralPredicate)
						}
					}
					// Delete unreachable transitions in XSTS
					for (xStsLiteralAssignment : xStsLiteralAssignments) {
						val lhs = xStsLiteralAssignment.lhs
						val declaration = lhs.declaration
						if (declaration === xStsVariable) {
							val rhs = xStsLiteralAssignment.rhs as EnumerationLiteralExpression
							val literal = rhs.reference
							if (literal.name == xStsLiteralName) {
								createFalseExpression.createAssumeAction.replace(xStsLiteralAssignment)
							}
						}
					}
				}
			}
		}
	}
	
	//
	
	def void deleteUnusedAndWrittenOnlyVariablesExceptOutEvents(XSTS xSts) {
		xSts.deleteUnusedAndWrittenOnlyVariablesExceptOutEvents(#[])
	}
	
	def void deleteUnusedAndWrittenOnlyVariablesExceptOutEvents(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables) { // Unfolded Gamma variables
		val keepableXStsVariables = xSts.nonInternalOutputVariables
		
		xSts.deleteUnusedAndWrittenOnlyVariables(keepableVariables, keepableXStsVariables)
	}
	
	def void deleteUnusedInputEventVariables(XSTS xSts) {
		xSts.deleteUnusedInputEventVariables(#[])
	}
	
	def void deleteUnusedInputEventVariables(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables) { // Unfolded Gamma variables
		val clonedXSts = xSts.clone
		clonedXSts.inEventTransition.action = createEmptyAction // Must not consider in event actions
		clonedXSts.outEventTransition.action = createEmptyAction // Must not consider out event actions
//		clonedXSts.entryEventTransition.action = createEmptyAction
		// TODO Handle init action: There can be event transmission e.g., in state entry actions
		
		val xStsInputEventVariables = clonedXSts.inputVariables
		logger.info("Transforming cloned XSTS to check the cone of influence of input events")
		clonedXSts.deleteUnusedAndWrittenOnlyVariables
		logger.info("Finished transforming the cloned XSTS")
		
		val xStsDeletedInputEventVariables = xStsInputEventVariables
				.filter[it.containingXsts === null]
		
		if (!xStsDeletedInputEventVariables.empty) {
			logger.info("Deleting input variables " + xStsDeletedInputEventVariables.map[it.name].join(", "))
		}
		for (xStsDeletedInputEventVariable : xStsDeletedInputEventVariables) {
			val name = xStsDeletedInputEventVariable.name
			val xStsInputVariable = xSts.getVariable(name) // Tracing
			
			for (reference : xSts.getAllContentsOfType(DirectReferenceExpression)) {
				if (reference.declaration === xStsDeletedInputEventVariable) {
					val xStsDefaultValue = xStsInputVariable.defaultExpression // Input: default value
					xStsDefaultValue.replace(reference)
				}
			}
			// These references cannot be rhs-s in assignments if the above algorithms are correct
		}
		
		// Optimization only if needed
		if (!xStsDeletedInputEventVariables.empty) {
			// Value propagation - inline: XstsOptimizer has this and many other techniques
			xSts.optimizeXSts
			// Another deletion of unused variables
			xSts.deleteUnusedAndWrittenOnlyVariablesExceptOutEvents(keepableVariables)
		}
	}
	
	def void deleteUnusedAndWrittenOnlyVariables(XSTS xSts) {
		xSts.deleteUnusedAndWrittenOnlyVariables(#[], #[])
	}
	
	def void deleteUnusedAndWrittenOnlyVariables(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables) { // Unfolded Gamma variables
		xSts.deleteUnusedAndWrittenOnlyVariables(keepableVariables, #[])
	}
	
	def void deleteUnusedAndWrittenOnlyVariables(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables, // Unfolded Gamma variables
			Collection<? extends VariableDeclaration> keepableXStsVariables) { // XSTS variables
		val mapper = new ReferenceToXstsVariableMapper(xSts)
		
		val xStsKeepableVariables = newArrayList
		xStsKeepableVariables += keepableXStsVariables
		for (keepableVariable : keepableVariables) {
			xStsKeepableVariables += mapper.getVariableVariables(keepableVariable)
		}
		
		var size = 0
		val xStsVariables = xSts.variableDeclarations
		while (size != xStsVariables.size) { // Until a fix point is reached
			size = xStsVariables.size
			
			val xStsDeleteableVariables = newLinkedHashSet
			
			xStsDeleteableVariables += xStsVariables
			// To check and remove 'a := a - 1' like deletable variables
			xStsDeleteableVariables -= xSts.externallyReadVariables
			xStsDeleteableVariables -= xStsKeepableVariables
			xStsDeleteableVariables.removeIf[it.hasAnnotation(UnremovableVariableDeclarationAnnotation)]
			
			xSts.deleteVariablesAndAssignments(xStsDeleteableVariables)
		}
	}
	
	def void deleteTrivialCodomainVariablesExceptOutEvents(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables, // Unfolded Gamma variables
			Collection<? extends State> keepableStates) {
		val keepableXStsVariables = xSts.nonInternalOutputVariables
		
		xSts.deleteTrivialCodomainVariables(keepableVariables, keepableStates, keepableXStsVariables)
	}
	
	def void deleteTrivialCodomainVariables(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables, // Unfolded Gamma variables
			Collection<? extends State> keepableStates,
			Collection<? extends VariableDeclaration> keepableXStsVariables) { // XSTS variables
		val mapper = new ReferenceToXstsVariableMapper(xSts)
		
		val xStsKeepableVariables = newArrayList
		xStsKeepableVariables += keepableXStsVariables
		for (keepableVariable : keepableVariables) {
			xStsKeepableVariables += mapper.getVariableVariables(keepableVariable)
		}
		for (keepableState : keepableStates) {
			xStsKeepableVariables += mapper.getRegionVariable(keepableState.parentRegion)
		}
		
		val oneValueXStsVariableCodomains = xSts.oneValueVariableCodomains
		val oneValueXStsVariables = oneValueXStsVariableCodomains.keySet
		for (xStsVariable : oneValueXStsVariables) {
			val xStsTrivialCodomain = oneValueXStsVariableCodomains.get(xStsVariable)
			
			for (reference : xSts.getAllContentsOfType(DirectReferenceExpression)
					.filter[!it.isLhs && it.declaration === xStsVariable]) {
				// No lhs references, so assignment actions can be deleted later 
				val xStsLiteral = xStsTrivialCodomain.clone
				xStsLiteral.replace(reference)
			}
		}
		
		val xStsDeletableVariables = newHashSet
		xStsDeletableVariables += oneValueXStsVariables
		xStsDeletableVariables -= xStsKeepableVariables
		xStsDeletableVariables.removeIf[it.hasAnnotation(UnremovableVariableDeclarationAnnotation)]
		
		xSts.deleteVariablesAndAssignments(xStsDeletableVariables)
	}
	
	def void deleteUnnecessaryInputVariablesExceptOutEvents(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables) { // Unfolded Gamma variables
		val keepableXStsVariables = xSts.nonInternalOutputVariables
		
		xSts.deleteUnnecessaryInputVariables(keepableVariables, keepableXStsVariables)
	}
	
	def void deleteUnnecessaryInputVariables(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables, // Unfolded Gamma variables
			Collection<? extends VariableDeclaration> keepableXStsVariables) { // XSTS variables
		val mapper = new ReferenceToXstsVariableMapper(xSts)
		
		val xStsKeepableVariables = newArrayList
		xStsKeepableVariables += keepableXStsVariables
		for (keepableVariable : keepableVariables) {
			xStsKeepableVariables += mapper.getVariableVariables(keepableVariable)
		}
		
		val xStsDeletableVariables = newHashSet
		
		val xStsInputVariables = xSts.inputVariables
		val xStsVariablesReferencedFromConditions = (xSts.variablesReferencedFromConditions
				+ xStsKeepableVariables).toSet
				
		for (xStsInputVariable : xStsInputVariables) {
			val allReaderXStsVariables = xStsInputVariable.allReaderVariables
			if (xStsVariablesReferencedFromConditions.containsNone(allReaderXStsVariables)) {
				xStsDeletableVariables += allReaderXStsVariables
				if (!xStsVariablesReferencedFromConditions.contains(xStsInputVariable)) {
					xStsDeletableVariables += xStsInputVariable
				}
			}
		}
	
		xStsDeletableVariables -= xStsKeepableVariables
		
		xSts.deleteVariablesAndAssignments(xStsDeletableVariables)
	}
	//
	
	protected def void deleteVariablesAndAssignments(XSTS xSts,
			Collection<VariableDeclaration> xStsDeletableVariables) {
		val xStsDeletableAssignments = xStsDeletableVariables.getAssignments(xSts)
		for (xStsDeletableAssignmentAction : xStsDeletableAssignments) {
			createEmptyAction.replace(
				xStsDeletableAssignmentAction) // To avoid nullptrs
		}
		
		// Note that only writes are handled - reads are not, so the following can cause
		// nullptr exceptions if the method call (parameters) is not correct
		if (!xStsDeletableVariables.empty) {
			logger.info("Deleting XSTS variables " + xStsDeletableVariables.map[it.name].join(", "))
		}
		for (xStsDeletableVariable : xStsDeletableVariables) {
			xStsDeletableVariable.deleteDeclaration // Delete needed due to e.g., transientVariables list
		}
	}
	
	//
	
	def void deleteUnusedEnumLiteralsExceptOne(XSTS xSts,
			Collection<? extends EnumerationLiteralDefinition> keepableLiterals) { // Unfolded Gamma variables
		val xStsDeletableLiterals = xSts.getUnusedEnumLiteralsExceptOne(keepableLiterals)
		
		// Enum types cannot be deleted as there must remain an else literal for each of them
		if (!xStsDeletableLiterals.empty) {
			logger.info("Deleting XSTS enum literals: " + xStsDeletableLiterals.map[it.name].join(", "))
		}
		for (xStsDeletableLiteral : xStsDeletableLiterals) {
			xStsDeletableLiteral.remove
		}
	}
	
	def void renameUnusedEnumLiteralsExceptOne(XSTS xSts,
			Collection<? extends EnumerationLiteralDefinition> keepableLiterals) { // Unfolded Gamma variables
		val xStsDeletableLiterals = xSts.getUnusedEnumLiteralsExceptOne(keepableLiterals)
		
		logger.info("Renaming XSTS enum literals to " + unusedEnumerationLiteralName + ": " + xStsDeletableLiterals.map[it.name].join(", "))
		for (xStsDeletableLiteral : xStsDeletableLiterals) {
			val unusedLiteralName = unusedEnumerationLiteralName
			xStsDeletableLiteral.name = unusedLiteralName
		}
	}
	
	protected def getUnusedEnumLiteralsExceptOne(XSTS xSts,
			Collection<? extends EnumerationLiteralDefinition> keepableLiterals) {
		val xStsEnums = xSts.typeDeclarations.map[it.typeDefinition]
				.filter(EnumerationTypeDefinition).toList
		val xStsLiterals = xStsEnums.map[it.literals].flatten.toList
		
		val xStsLiteralReferences = xSts.getAllContentsOfType(EnumerationLiteralExpression)
		
		val xStsLiteralReferenced = newLinkedHashSet
		xStsLiteralReferenced += xStsLiteralReferences.map[it.reference]
		
		val xStsLiteralReferencedByPredicate = xStsLiteralReferences
				.filter[it.isDirectlyContainedBy(PredicateExpression)].map[it.reference].toSet
		
//		val xStsLiteralUnreferenced = newArrayList
//		xStsLiteralUnreferenced += xStsLiterals
//		xStsLiteralUnreferenced -= xStsLiteralReferenced
		
		// Could make progress here if we knew what literals are referenced in a 'positive' or 'negative' way
		
		val xStsKeepableLiterals = keepableLiterals // customizeName? - remains the same
									.map[val name = it.name
										val typeDeclarationName = it.getContainerOfType(TypeDeclaration).name
										xStsLiterals
											.filter[it.getContainerOfType(TypeDeclaration).name == typeDeclarationName &&
													it.name === name]].flatten.toSet
		
		val xStsDeletableLiterals = newArrayList
		xStsDeletableLiterals += xStsLiterals
		xStsDeletableLiterals -= xStsLiteralReferenced
		xStsDeletableLiterals -= xStsKeepableLiterals
		
		for (xStsEnum : xStsEnums) {
			val xStsEnumLiterals = xStsEnum.literals
			val xStsDeletableEnumLiterals = newArrayList
			xStsDeletableEnumLiterals += xStsEnumLiterals
			xStsDeletableEnumLiterals.retainAll(xStsDeletableLiterals)
			val xStsKeepableEnumLiterals = newArrayList
			xStsKeepableEnumLiterals += xStsEnumLiterals
			xStsKeepableEnumLiterals -= xStsDeletableEnumLiterals
			
			val needElseLiteral = xStsEnumLiterals.size == xStsDeletableEnumLiterals || (// If we want to delete all literals
					!xStsDeletableEnumLiterals.empty && // Or, if we want to delete literals
					xStsLiteralReferenced.containsAll(xStsKeepableLiterals) && // And the keepable is not already an else literal (otherwise it already serves as one)
					xStsLiteralReferencedByPredicate.containsAll(xStsKeepableEnumLiterals))  // And every keepable literal is referenced from a predicate (and not only from an assignment action which can serve as an else literal)
			if (needElseLiteral) { 
				val xStsElseEnumLiteral = xStsDeletableEnumLiterals.head // Keeping the lowest literal for the "else" branch
				xStsDeletableLiterals -= xStsElseEnumLiteral
			}
		}
		
		return xStsDeletableLiterals
	}
	
	//
	
	protected def getInputVariables(XSTS xSts) {
		val xStsInputVariables = newArrayList
		
		val systemInEventVariableGroup = xSts.systemInEventVariableGroup
		val xStsInEventVariables = systemInEventVariableGroup.variables
		val systemInEventParameterVariableGroup = xSts.systemInEventParameterVariableGroup
		val xStsInEventParameterVariables = systemInEventParameterVariableGroup.variables
		
		xStsInputVariables += xStsInEventVariables
		xStsInputVariables += xStsInEventParameterVariables
		
		// Also the system message queues
		
		val masterQueueVariableGroup = xSts.systemMasterMessageQueueGroup
		val xStsMasterQueueVariables = masterQueueVariableGroup.variables
		val slaveQueueVariableGroup = xSts.systemSlaveMessageQueueGroup
		val xStsSlaveQueueVariables = slaveQueueVariableGroup.variables
		
		xStsInputVariables += xStsMasterQueueVariables
		xStsInputVariables += xStsSlaveQueueVariables
		
		return xStsInputVariables
	}
	
	protected def getOutputVariables(XSTS xSts) {
		val xStsOutputVariables = newArrayList
		
		val systemOutEventVariableGroup = xSts.systemOutEventVariableGroup
		val xStsOutEventVariables = systemOutEventVariableGroup.variables
		val systemOutEventParameterVariableGroup = xSts.systemOutEventParameterVariableGroup
		val xStsOutEventParameterVariables = systemOutEventParameterVariableGroup.variables
		
		xStsOutputVariables += xStsOutEventVariables
		xStsOutputVariables += xStsOutEventParameterVariables
		
		return xStsOutputVariables
	}
	
	protected def getNonInternalOutputVariables(XSTS xSts) {
		val xStsOutputVariables = xSts.outputVariables
		val xStsReadVariables = xSts.readVariables
		
		val xStsDeletableInternalOutputVariables = newHashSet
		// Internal output parameter variables that are not read (not read in channels)
		xStsDeletableInternalOutputVariables += xStsOutputVariables.filter[it.internal]
		xStsDeletableInternalOutputVariables -= xStsReadVariables
		//
		
		xStsOutputVariables -= xStsDeletableInternalOutputVariables
		
		return xStsOutputVariables
	}
	
	//
	
	def void deleteUnusedPortReferencesInQueues(AsynchronousComponentInstance adapterInstance) {
		val adapterComponentType = adapterInstance.derivedType as AsynchronousAdapter
		
		val unusedPorts = adapterInstance.unusedPorts
		for (queue : adapterComponentType.messageQueues.toSet) {
			val storedPorts = queue.storedPorts
			for (storedPort : storedPorts) {
				if (unusedPorts.contains(storedPort)) {
					for (eventReference : queue.sourceEventReferences.toSet) {
						if (storedPort === eventReference.eventSource) {
							val eventPassing = eventReference.eContainer
							eventPassing.remove
							logger.info('''Removing unused «storedPort.name» reference from «queue.name»''')
						}
					}
				}
			}
			
			// Always empty queues are removed
			if (queue.eventPassings.empty) {
				logger.info('''Removing always empty «queue.name»''')
				queue.remove
			}
		}
	}
	
}