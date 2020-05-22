package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.xsts.model.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.model.SequentialAction
import java.util.Collection

class ReadWrittenVariableLocator {
	
	extension ExpressionUtil expressionUtil = new ExpressionUtil
	
	// Read variables in actions
	
	def dispatch Collection<VariableDeclaration> getReadVariables(AssumeAction action) {
		return action.assumption.referredVariables
	}
	
	def dispatch Collection<VariableDeclaration> getReadVariables(AssignmentAction action) {
		return action.rhs.referredVariables
	}
	
	def dispatch Collection<VariableDeclaration> getReadVariables(EmptyAction action) {
		return #{}
	}
	
	def dispatch Collection<VariableDeclaration> getReadVariables(NonDeterministicAction action) {
		val variableList = newHashSet
		for (containedAction : action.actions) {
			variableList += containedAction.readVariables
		}
		return variableList
	}
	
	def dispatch Collection<VariableDeclaration> getReadVariables(ParallelAction action) {
		val variableList = newHashSet
		for (containedAction : action.actions) {
			variableList += containedAction.readVariables
		}
		return variableList
	}
	
	def dispatch Collection<VariableDeclaration> getReadVariables(SequentialAction action) {
		val variableList = newHashSet
		for (containedAction : action.actions) {
			variableList += containedAction.readVariables
		}
		return variableList
	}
	
	// Written variables in actions
	
	def dispatch Collection<VariableDeclaration> getWrittenVariables(AssumeAction action) {
		return #{}
	}
	
	def dispatch Collection<VariableDeclaration> getWrittenVariables(AssignmentAction action) {
		return action.lhs.referredVariables
	}
	
	def dispatch Collection<VariableDeclaration> getWrittenVariables(EmptyAction action) {
		return #{}
	}
	
	def dispatch Collection<VariableDeclaration> getWrittenVariables(NonDeterministicAction action) {
		val variableList = newHashSet
		for (containedAction : action.actions) {
			variableList += containedAction.writtenVariables
		}
		return variableList
	}
	
	def dispatch Collection<VariableDeclaration> getWrittenVariables(ParallelAction action) {
		val variableList = newHashSet
		for (containedAction : action.actions) {
			variableList += containedAction.writtenVariables
		}
		return variableList
	}
	
	def dispatch Collection<VariableDeclaration> getWrittenVariables(SequentialAction action) {
		val variableList = newHashSet
		for (containedAction : action.actions) {
			variableList += containedAction.writtenVariables
		}
		return variableList
	}
	
}