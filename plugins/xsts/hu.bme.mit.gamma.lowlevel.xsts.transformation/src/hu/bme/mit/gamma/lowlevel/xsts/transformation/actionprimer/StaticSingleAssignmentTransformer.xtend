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
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssertAction
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.PrimedVariable
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.transformation.util.XstsNamings
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List
import java.util.Map

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class StaticSingleAssignmentTransformer {
	
	protected final XSTS xSts
	protected final SsaType ssaType
	
	protected final Map<Declaration, String> localVariableNames = newHashMap
	protected Map<VariableDeclaration, PrimedVariable> primedVariables = newLinkedHashMap
	
	protected String context = ""
	protected int transitionIndex = -1
	
	// Auxiliary objects
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	// Model factories
	protected final extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	//
	
	new(XSTS xSts) {
		this(xSts, SsaType.BASIC)
	}
	
	new(XSTS xSts, SsaType ssaType) {
		this.xSts = xSts
		this.ssaType = ssaType
	}
	
	def execute() {
		preprocessArrayAssignments
		createStaticSingleAssignmentForm
	}
	
	// Needed to support array assignments in SSA form (see 'primeLhs(ReferenceExpression lhs)')
	
	protected def preprocessArrayAssignments() {
		val arrayAssignments = xSts.getSelfAndAllContentsOfType(AssignmentAction)
				.filter[it.lhs.declaration.array].toList
		var AssignmentAction previousAction = null
		for (arrayAssignment : arrayAssignments) {
			if (arrayAssignment.first ||
					arrayAssignment.previous !== previousAction) {
				val array = arrayAssignment.lhs.declaration as VariableDeclaration
				val arraySaveAction = array.createAssignmentAction(array)
				
				arraySaveAction.prependToAction(arrayAssignment)
			}
		
			previousAction = arrayAssignment
		}
	}
	
	// SSE first pass
	
	protected def createStaticSingleAssignmentForm() {
		localVariableNames.clear
		xSts.customizeLocalVariableNames
		//
		context = "_init"
		
		xSts.variableInitializingTransition.action.primeAction
		xSts.configurationInitializingTransition.action.primeAction
		xSts.entryEventTransition.action.primeAction
		primedVariables.clear
		//
		
		context = "_inout"
		
		xSts.inEventTransition.action.primeAction
		xSts.outEventTransition.action.primeAction
		if (ssaType !== SsaType.OUT_TRANS) {
			primedVariables.clear // Because we want to connect this to trans
		}
		//
		val primeVariableSave = newLinkedHashMap
		primeVariableSave += primedVariables
		
		val xStsTransitions = xSts.transitions
		for (xStsTransition : xStsTransitions) {
			transitionIndex = xStsTransitions.indexOf(xStsTransition)
			context = "_tran_" + transitionIndex + "_num"
			primedVariables += primeVariableSave
			//
			val xStsAction = xStsTransition.action
			xStsAction.primeAction
			//
			primedVariables.clear
			//
		}
		
		// Not all primed variables are used
		removeUnusedPrimedVariables
		//
//		xSts.restoreLocalVariableNames // Cannot be restored as they have to be globally unique
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
		// Commonizing
		val commonizedPrimedVariables = subactions.commonizeBranches // Highest prime variables
		primedVariables += commonizedPrimedVariables // Addition as some variables may not be present in commonizedPrimedVariables
		//
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
		
		// Commonizing
		val branches = newArrayList(action.then)
		branches += action.^else
		
		val commonizedPrimedVariables = branches.commonizeBranches // Highest prime variables
		primedVariables += commonizedPrimedVariables // Addition as some variables may not be present in commonizedPrimedVariables
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
		// Note that here there is a semantic deficiency in the conversion:
		// E.g., 'a[1][2] := 10' maps to 'a2[1][2] := 10' but here we cannot express that
		// we want to keep the remaining values from 'a' (i.e., a[0][0] = a2[0][0] & a[0][1] = a2[0][1]...)
		// This deficiency has to be handled by the subsequent transformations
		// with the corresponding array WRITE function
		lhs.primeExpression
	}
	
	protected def primeVariable(VariableDeclaration originalVariable) {
		val previousVariable = primedVariables.containsKey(originalVariable) ?
				primedVariables.get(originalVariable) : originalVariable
		val index = previousVariable.primeCount + 1
		
		val primedVariable = createPrimedVariable => [
			it.type = originalVariable.type.clone
			it.name = originalVariable.name.customizeName(index) // Needed in nuXmv back-annotation
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
	
	protected def commonizeBranches(List<Action> branches) {
		val originalBranches = newArrayList // Some branches are modified
		originalBranches += branches // (i.e., a single AssumeAction is extended into a SequentialAction),
		// and we use these branches as keys in maps; hence the list copy
		val branchAssignments = newLinkedHashMap
		//
		val commonizedPrimedVariables = <VariableDeclaration, PrimedVariable>newLinkedHashMap // Note that these are the commonized variables
		// If a variable is NOT assigned a new value in the branches, then it is NOT present in the map
		// Thus, this map should be ADDED to the original primed variables map
		
		for (subaction : originalBranches) {
			branchAssignments += subaction -> subaction.getSelfAndAllContentsOfType(AbstractAssignmentAction)
		}
		// Commonizing
		val writtenOriginalVariables = branchAssignments.values.flatten
				.map[it.lhs.declaration.originalVariable].filter(VariableDeclaration).toSet
				
		for (writtenOriginalVariable : writtenOriginalVariables) {
			var Action maxVariableAssignmentBranch = null
			var maxBranchAssignmentToOriginalVariableCount = -1
			var branchPrimedVariables = newLinkedHashMap
			
			for (subaction : originalBranches) {
				val branchAssignmentList = branchAssignments.get(subaction)
				
				val branchAssignmentToOriginalVariable = branchAssignmentList
						.filter[it.lhs.declaration.originalVariable === writtenOriginalVariable]
				val branchPrimedVariablesToOriginalVariable = newLinkedHashSet // Can be duplications after recursion
				branchPrimedVariablesToOriginalVariable += branchAssignmentToOriginalVariable
						.map[it.lhs.declaration].filter(VariableDeclaration).sortBy[it.primeCount] // Crucial to have it sorted
						// Otherwise, the last variable will not be the one with the highest prime
				val branchAssignmentToOriginalVariableCount = branchPrimedVariablesToOriginalVariable.size
				
				branchPrimedVariables += subaction -> branchPrimedVariablesToOriginalVariable.toList
				
				if (branchAssignmentToOriginalVariableCount >= maxBranchAssignmentToOriginalVariableCount) {
					// >= To potentially "override" the former max in case of equality: helps with interpreting the priming indexes (would not necessary though)
					maxVariableAssignmentBranch = subaction
					maxBranchAssignmentToOriginalVariableCount = branchAssignmentToOriginalVariableCount
				}
			}
			
			// maxVariableAssignmentBranch has the most assignments to writtenOriginalVariable
			if (maxVariableAssignmentBranch !== null) {
				val commonizableBranches = newArrayList
				commonizableBranches += originalBranches
				commonizableBranches -= maxVariableAssignmentBranch
				
				val longestPrimedVariableSequence = branchPrimedVariables.get(maxVariableAssignmentBranch)
				val firstPrimedVariableInLongestSequence = longestPrimedVariableSequence.head
				val variableBeforeBranching = firstPrimedVariableInLongestSequence instanceof PrimedVariable ?
					firstPrimedVariableInLongestSequence.primedVariable : firstPrimedVariableInLongestSequence as VariableDeclaration
				
				val reverseLongestPrimedVariableSequence = longestPrimedVariableSequence.reverseView
				val lastPrimedVariableInLongestSequence = reverseLongestPrimedVariableSequence.head as PrimedVariable
				
				commonizedPrimedVariables += writtenOriginalVariable -> lastPrimedVariableInLongestSequence
				
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
		
		return commonizedPrimedVariables // See instructions at the declaration point
	}
	
	//
	
	protected def customizeName(String name, int index) {
		switch (context) {
			case context.startsWith("_init"): {
				return XstsNamings.getPrimedVariableNameInInitTransition(name, index)
			}
			case context.startsWith("_inout"): {
				return XstsNamings.getPrimedVariableNameInInoutTransition(name, index)
			}
			case context.startsWith("_tran_"): {
				return XstsNamings.getPrimedVariableNameInTransition(name, transitionIndex, index)
			}
			default :
				throw new IllegalArgumentException("Not know context: " + context)
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
	
	protected def customizeLocalVariableNames(XSTS xSts) {
		localVariableNames.clear
		for (localVariableAction : xSts.getAllContentsOfType(VariableDeclarationAction)) {
			val localVariable = localVariableAction.variableDeclaration
			val name = localVariable.name
			localVariableNames += localVariable -> name
			
			localVariable.name = localVariable.name + "_" + localVariable.hashCode.toString.replaceAll("-","_")
		}
	}
	
	protected def restoreLocalVariableNames(XSTS xSts) {
		for (localVariable : localVariableNames.keySet) {
			val name = localVariableNames.get(localVariable)
			localVariable.name = name
		}
	}
	
	//
	
	enum SsaType { BASIC, OUT_TRANS}
	
}