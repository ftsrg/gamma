/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.UnremovableVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.VariableGroupRetriever
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.XstsOptimizer
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.logging.Level
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
	protected final extension GammaEcoreUtil expressionUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE
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
			xStsDeletableAssignmentAction.remove // To speed up the process
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
		clonedXSts.deleteUnusedAndWrittenOnlyVariables
		
		val xStsDeletedInputEventVariables = xStsInputEventVariables
				.filter[it.containingXsts === null]
		
		for (xStsDeletedInputEventVariable : xStsDeletedInputEventVariables) {
			val name = xStsDeletedInputEventVariable.name
			val xStsInputVariable = xSts.getVariable(name) // Tracing
			logger.log(Level.INFO, "Deleting input variable " + name)
			
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
			Collection<? extends VariableDeclaration> keepableVariables) { // Unfolded Gamma variables
		val keepableXStsVariables = xSts.nonInternalOutputVariables
		
		xSts.deleteTrivialCodomainVariables(keepableVariables, keepableXStsVariables)
	}
	
	def void deleteTrivialCodomainVariables(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables, // Unfolded Gamma variables
			Collection<? extends VariableDeclaration> keepableXStsVariables) { // XSTS variables
		val mapper = new ReferenceToXstsVariableMapper(xSts)
		
		val xStsKeepableVariables = newArrayList
		xStsKeepableVariables += keepableXStsVariables
		for (keepableVariable : keepableVariables) {
			xStsKeepableVariables += mapper.getVariableVariables(keepableVariable)
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
			Collection<VariableDeclaration> xStsDeleteableVariables) {
		val xStsDeletableAssignments = xStsDeleteableVariables.getAssignments(xSts)
		for (xStsDeletableAssignmentAction : xStsDeletableAssignments) {
			createEmptyAction.replace(
				xStsDeletableAssignmentAction) // To avoid nullptrs
		}
		
		// Note that only writes are handled - reads are not, so the following can cause
		// nullptr exceptions if the method call (parameters) is not correct
		for (xStsDeletableVariable : xStsDeleteableVariables) {
			xStsDeletableVariable.deleteDeclaration // Delete needed due to e.g., transientVariables list
			logger.log(Level.INFO, "Deleting XSTS variable " + xStsDeletableVariable.name)
		}
	}
	
	//
	
	def void deleteUnusedEnumLiteralsExceptOne(XSTS xSts,
			Collection<? extends EnumerationLiteralDefinition> keepableLiterals) { // Unfolded Gamma variables
		val xStsLiterals = xSts.getAllContentsOfType(EnumerationLiteralDefinition)
		
		val xStsLiteralReferences = xSts.getAllContentsOfType(EnumerationLiteralExpression)
		val xStsReferencedLiterals = xStsLiteralReferences.map[it.reference].toSet
		
		val xStsKeepableLiterals = keepableLiterals // customizeName? - remains the same
									.map[val name = it.name
										val typeDeclarationName = it.getContainerOfType(TypeDeclaration).name
										xStsLiterals
											.filter[it.getContainerOfType(TypeDeclaration).name == typeDeclarationName &&
													it.name === name]].flatten.toSet
		
		val xStsDeletableLiterals = newHashSet
		xStsDeletableLiterals += xStsLiterals
		xStsDeletableLiterals -= xStsReferencedLiterals
		xStsDeletableLiterals -= xStsKeepableLiterals
		
		// Keeping the lowest literal for the "else" branch
		val xStsElseBranchedEnums = newHashSet
		for (xStsDeletableLiteral : xStsDeletableLiterals.toList) {
			val xStsContainingEnum = xStsDeletableLiteral.getContainerOfType(EnumerationTypeDefinition)
			if (!xStsElseBranchedEnums.contains(xStsContainingEnum)) {
				xStsDeletableLiterals -= xStsDeletableLiteral // No else branch for this enum yet, the literal cannot be removed
				xStsElseBranchedEnums += xStsContainingEnum
			}
		}
		//
		
		for (xStsDeletableLiteral : xStsDeletableLiterals) {
//			val xStsEnumerationType = xStsDeletableLiteral.getContainerOfType(EnumerationTypeDefinition)
			logger.log(Level.INFO, "Deleting XSTS enum literal " + xStsDeletableLiteral.name)
			xStsDeletableLiteral.remove
			// Enum types cannot be deleted as there must remain an else literal for each of them
//			if (xStsEnumerationType.literals.empty) {
//				xStsEnumerationType.delete
//			}
		}
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
							eventReference.remove
							logger.log(Level.INFO, '''Removing unused «storedPort.name» reference from «queue.name»''')
						}
					}
				}
			}
			
			// Always empty queues are removed
			if (queue.eventPassings.empty) {
				logger.log(Level.INFO, '''Removing always empty «queue.name»''')
				queue.remove
			}
		}
	}
	
}