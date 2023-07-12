/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssertAction
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.AtomicAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.PrimedVariable
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List
import java.util.Map

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class StaticSingleAssignmentTransformer {
	
	protected final XSTS xSts
	protected final SsaType ssaType
	
	protected Map<VariableDeclaration, PrimedVariable> primedVariables = newLinkedHashMap
	protected String context = ""
	
	// Auxiliary objects
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	// Model factories
	protected final extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintModelFactory = ExpressionModelFactory.eINSTANCE
	//
	
	new(XSTS xSts) {
		this(xSts, SsaType.BASIC)
	}
	
	new(XSTS xSts, SsaType ssaType) {
		this.xSts = xSts
		this.ssaType = ssaType
	}
	
	def execute() {
		createStaticSingleAssignmentForm
	}
	
	// SSE first pass
	
	protected def createStaticSingleAssignmentForm() {
		
		context = "_init"
		
		xSts.variableInitializingTransition.action.primeAction
		xSts.variableInitializingTransition.action.commonizePrimedVariablesAlongBranches // Unnecessary though, no branches
		xSts.configurationInitializingTransition.action.primeAction
		xSts.configurationInitializingTransition.action.commonizePrimedVariablesAlongBranches
		xSts.entryEventTransition.action.primeAction
		xSts.entryEventTransition.action.commonizePrimedVariablesAlongBranches
		primedVariables.clear
		//
		
		context = "_inout"
		
		if (ssaType !== SsaType.OUT_TRANS) {
			xSts.inEventTransition.action.primeAction
			xSts.inEventTransition.action.commonizePrimedVariablesAlongBranches
		}
		else {
			xSts.inEventTransition.action = createEmptyAction // Not needed, in variables are nondeterministic in e.g., SMV
		}
		xSts.outEventTransition.action.primeAction
		xSts.outEventTransition.action.commonizePrimedVariablesAlongBranches // Unnecessary though, no branches
		if (ssaType !== SsaType.OUT_TRANS) {
			primedVariables.clear // Because we want to connect this to trans
		}
		//
		val primeVariableSave = newLinkedHashMap
		primeVariableSave += primedVariables
		
		val xStsTransitions = xSts.transitions
		for (xStsTransition : xStsTransitions) {
			context = "_tran_" + xStsTransitions.indexOf(xStsTransition) + "_num"
			primedVariables += primeVariableSave
			
			val xStsAction = xStsTransition.action
			xStsAction.primeAction
			xStsAction.commonizePrimedVariablesAlongBranches
			primedVariables.clear
		}
		
		// Not all primed variables are used
		removeUnusedPrimedVariables
	}
	
	//
	
	protected def dispatch void primeAction(SequentialAction action) {
		val subactions = action.actions
		
		for (subaction : subactions) {
			subaction.primeAction
		}
	}
	
	protected def dispatch void primeAction(NonDeterministicAction action) {
		val subactions = action.actions
		
		for (subaction : subactions) {
			// Save priming
			val savedPrimedVariables = newLinkedHashMap
			savedPrimedVariables += primedVariables
			//
			
			subaction.primeAction
			
			// Restore priming
			primedVariables.clear
			primedVariables += savedPrimedVariables
			//
		}
	}
	
	protected def dispatch void primeAction(IfAction action) {
		val condition = action.condition
		val then = action.then
		val elze = action.^else
		
		condition.primeExpression
		
		// Save priming
		val savedPrimedVariables = newLinkedHashMap
		savedPrimedVariables += primedVariables
		//
		
		then.primeAction
		
		// Restore priming
		primedVariables.clear
		primedVariables += savedPrimedVariables
		//
		
		elze.primeAction
		
		// Restore priming
		primedVariables.clear
		primedVariables += savedPrimedVariables
		//
	}
	
	//
	
	protected def dispatch void primeAction(EmptyAction action) {
		// No op
	}
	
	protected def dispatch void primeAction(AssertAction action) {
		val assertion = action.assertion
		assertion.primeExpression
	}
	
	protected def dispatch void primeAction(HavocAction action) {
		val lhs = action.lhs
		lhs.primeLhs
	}
	
	protected def dispatch void primeAction(AssignmentAction action) {
		val rhs = action.rhs
		rhs.primeExpression
		
		val lhs = action.lhs
		lhs.primeLhs
	}
	
	protected def dispatch void primeAction(VariableDeclarationAction action) {
		val declaration = action.variableDeclaration
		val rhs = declaration.expression
		rhs?.primeExpression
	}
	
	protected def dispatch void primeAction(AssumeAction action) {
		val condition = action.assumption
		condition.primeExpression
	}
	
	//
	
	protected def void primeLhs(ReferenceExpression lhs) {
		val declaration = lhs.declaration as VariableDeclaration
		checkState (declaration.native || declaration.array)
		declaration.primeVariable // The loop below will cover the lhs priming
		
		lhs.primeExpression
	}
	
	protected def primeVariable(VariableDeclaration originalVariable) {
		val previousVariable = primedVariables.containsKey(originalVariable) ?
				primedVariables.get(originalVariable) : originalVariable
		val index = previousVariable.primeCount + 1
		
		val primedVariable = createPrimedVariable => [
			it.type = originalVariable.type.clone
			it.name = originalVariable.name + context + "_" + index // Extract?
			it.primedVariable = previousVariable
		]
		primedVariable.addTransientAnnotation // To also indicate that it is not needed in stable states
		
		xSts.variableDeclarations += primedVariable
		
		primedVariables += originalVariable -> primedVariable
		
		return primedVariable
	}
	
	protected def void primeExpression(Expression expression) {
		val references = expression.getSelfAndAllContentsOfType(DirectReferenceExpression)
		
		for (reference : references) {
			val declaration = reference.declaration
			
			if (primedVariables.containsKey(declaration)) {
				val primedVariable = primedVariables.get(declaration)
				reference.declaration = primedVariable
			}
		}
	}
	
	// SSE second pass (optimization)
	
	protected def dispatch void commonizePrimedVariablesAlongBranches(SequentialAction action) {
		val subactions = action.actions
		
		for (subaction : subactions) {
			subaction.commonizePrimedVariablesAlongBranches
		}
	}
	
	protected def dispatch void commonizePrimedVariablesAlongBranches(NonDeterministicAction action) {
		val subactions = action.actions
		
		subactions.commonizeBranches
	}
	
	protected def dispatch void commonizePrimedVariablesAlongBranches(IfAction action) {
		if (action.^else === null) {
			action.^else = createEmptyAction
		}
		
		val branches = newArrayList
		
		branches += action.then
		branches += action.^else
		
		branches.commonizeBranches
	}
	
	protected def dispatch void commonizePrimedVariablesAlongBranches(AtomicAction action) {
		// No op
	}
	
	//
	
	protected def void commonizeBranches(List<Action> branches) {
		val branchAssignments = newLinkedHashMap
		
		for (subaction : branches) {
			subaction.commonizePrimedVariablesAlongBranches // Recursion
			
			branchAssignments += subaction -> subaction.getSelfAndAllContentsOfType(AbstractAssignmentAction)
		}
		// Commonizing
		val writtenOriginalVariables = branchAssignments.values.flatten
				.map[it.lhs.declaration.originalVariable].toSet
				
		for (writtenOriginalVariable : writtenOriginalVariables) {
			var Action maxVariableAssignmentBranch = null
			var maxBranchAssignmentToOriginalVariableCount = -1
			var branchPrimedVariables = newLinkedHashMap
			
			for (subaction : branches) {
				val branchAssignmentList = branchAssignments.get(subaction)
				
				val branchAssignmentToOriginalVariable = branchAssignmentList
						.filter[it.lhs.declaration.originalVariable === writtenOriginalVariable]
				val branchPrimedVariablesToOriginalVariable = newLinkedHashSet // Can be duplications after recursion
				branchPrimedVariablesToOriginalVariable += branchAssignmentToOriginalVariable
						.map[it.lhs.declaration]
				val branchAssignmentToOriginalVariableCount = branchPrimedVariablesToOriginalVariable.size
				
				branchPrimedVariables += subaction -> branchPrimedVariablesToOriginalVariable.toList
				
				if (branchAssignmentToOriginalVariableCount > maxBranchAssignmentToOriginalVariableCount) {
					maxVariableAssignmentBranch = subaction
					maxBranchAssignmentToOriginalVariableCount = branchAssignmentToOriginalVariableCount
				}
			}
			
			// maxVariableAssignmentBranch has the most assignments to writtenOriginalVariable
			if (maxVariableAssignmentBranch !== null) {
				val commonizableBranches = newArrayList
				commonizableBranches += branches
				commonizableBranches -= maxVariableAssignmentBranch
				
				val longestPrimedVariableSequence = branchPrimedVariables.get(maxVariableAssignmentBranch)
				val firstPrimedVariableInLongestSequence = longestPrimedVariableSequence.head
				val variableBeforeBranching = firstPrimedVariableInLongestSequence instanceof PrimedVariable ?
					firstPrimedVariableInLongestSequence.primedVariable : firstPrimedVariableInLongestSequence as VariableDeclaration
				
				val reverseLongestPrimedVariableSequence = longestPrimedVariableSequence.reverseView
				val lastPrimedVariableInLongestSequence = reverseLongestPrimedVariableSequence.head as VariableDeclaration
				
				for (commonizableBranch : commonizableBranches) {
					val branchPrimedVariableSequence = branchPrimedVariables.get(commonizableBranch) //
					if (branchPrimedVariableSequence.empty) {
						// No assignment to this variable along this branch, but commonizing is still needed
						val commonizingAction = lastPrimedVariableInLongestSequence.createAssignmentAction(variableBeforeBranching)
						commonizableBranch.appendToAction(commonizingAction)
					}
					else {
						val reverseBranchPrimedVariableSequence = branchPrimedVariableSequence.reverseView
						
						// Going backwards, so the final assignment will be to the highest primed variable
						for (var i = 0; i < reverseBranchPrimedVariableSequence.size; i++) {
							val reversedPrimedVariableFromLongestSequence = reverseLongestPrimedVariableSequence.get(i)
							val reversedPrimedVariableFromBranch = reverseBranchPrimedVariableSequence.get(i)
							
							// Changing reference to the primed variable
							reversedPrimedVariableFromLongestSequence.change(
									reversedPrimedVariableFromBranch, commonizableBranch)
						}
					}
				}
			}
		}
	}
	
	//
	
	protected def removeUnusedPrimedVariables() {
		val abstractAssignments = xSts.getAllContentsOfType(AbstractAssignmentAction)
		val referencedVariables = abstractAssignments.map[it.lhs.declaration].toSet
		
		val unusedPrimedVariables = <Declaration>newArrayList
		unusedPrimedVariables += xSts.variableDeclarations.filter(PrimedVariable)
		unusedPrimedVariables -= referencedVariables
		
		unusedPrimedVariables.removeAll
	}
	
	//
	
	enum SsaType { BASIC, OUT_TRANS}
	
}