package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import java.util.List
import java.util.Map
import org.eclipse.xtend.lib.annotations.Data

class VariableInliner {
	// Singleton
	public static final VariableInliner INSTANCE =  new VariableInliner
	protected new() {}
	//
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE

	def inline(Action action) {
		action.inline(newHashMap)
	}
	
	protected def dispatch void inline(Action action, Map<VariableDeclaration, InlineEntry> values) {
		throw new IllegalArgumentException
	}
	
	protected def dispatch void inline(SequentialAction action, Map<VariableDeclaration, InlineEntry> values) {
		val subactions = newArrayList
		subactions += action.actions
		for (subaction : subactions) {
			subaction.inline(values)
		}
	}
	
	protected def dispatch void inline(NonDeterministicAction action, Map<VariableDeclaration, InlineEntry> values) {
		val branchValueList = newArrayList
		val subactions = newArrayList
		subactions += action.actions
		for (branch : subactions) {
			val branchValues = newHashMap
			branchValues += values
			// Cloned map
			branch.inline(branchValues)
			// Saving the new map
			branchValueList += branchValues
		}
		
		// "Commonizing" the values into a new map, that is,
		// deleting the values that we are not aware of anymore
		val commonizedValues = branchValueList.commonizeMaps
		
		// Setting the map
		values.clear
		values += commonizedValues
	}
	
	protected def dispatch void inline(AssignmentAction action, Map<VariableDeclaration, InlineEntry> values) {
		val rhs = action.rhs
		rhs.inlineVariables(values)
		val lhs = action.lhs
		if (lhs instanceof DirectReferenceExpression) {
			val declaration = lhs.declaration
			if (declaration instanceof VariableDeclaration) {
				val references = rhs.getSelfAndAllContentsOfType(ReferenceExpression)
				if (references.empty) { // So it is evaluable
					if (values.containsKey(declaration)) {
						// Removing old assignment action due to the priming problem
						val oldEntry = values.get(declaration)
						val oldAssignment = oldEntry.getLastValueGivingAction
						oldAssignment.remove
					}
					// Adding this new value
					values += declaration -> new InlineEntry(rhs, action)
				}
			}
		}
	}
	
	protected def dispatch void inline(AssumeAction action, Map<VariableDeclaration, InlineEntry> values) {
		val assumption = action.assumption
		assumption.inlineVariables(values)
	}
	
	// Auxiliary
	
	protected def commonizeMaps(List<? extends Map<VariableDeclaration, InlineEntry>> branchValueList) {
		// Calculating variables present in all branches
		val commonVariables = newHashSet
		for (branchValues : branchValueList) {
			val branchVariables = branchValues.keySet
			if (commonVariables.empty) {
				commonVariables += branchVariables
			}
			else {
				commonVariables.retainAll(branchVariables)
			}
		}
		
		val newBranchValues = newHashMap
		val contradictingVariables = newHashSet
		for (branchValues : branchValueList) {
			for (variable : branchValues.keySet) {
				val entry = branchValues.get(variable)
				val value = entry.value
				if (commonVariables.contains(variable)) {
					if (!newBranchValues.containsKey(variable)) {
						// First entry
						newBranchValues += variable -> entry
					}
					else {
						val newEntry = newBranchValues.get(variable)
						val newValue = newEntry.value
						if (!value.helperEquals(newValue)) {
							// "Contradiction" in different branches
							contradictingVariables += variable
						}
					}
				}
			}
		}
		// Removing variables whose value is unknown
		newBranchValues.keySet.removeAll(contradictingVariables)
		return newBranchValues
	}
	
	protected def inlineVariables(Expression expression, Map<VariableDeclaration, InlineEntry> values) {
		val references = expression.getSelfAndAllContentsOfType(DirectReferenceExpression)
		for (variable : values.keySet) {
			val entry = values.get(variable)
			val value = entry.value
			for (reference : references.filter[it.declaration === variable]) {
				val clonedValue = value.clone // Cloning is important
				clonedValue.replace(reference)
			}
		}
	}
	
	@Data
	static class InlineEntry {
		Expression value
		AssignmentAction lastValueGivingAction
	}
	
}