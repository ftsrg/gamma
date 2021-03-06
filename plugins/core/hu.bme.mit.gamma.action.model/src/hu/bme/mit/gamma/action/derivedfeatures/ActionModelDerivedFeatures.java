package hu.bme.mit.gamma.action.derivedfeatures;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;

public class ActionModelDerivedFeatures extends ExpressionModelDerivedFeatures {
	
	public static List<VariableDeclarationStatement> getVariableDeclarationStatements(
			Block block) {
		EList<Action> subactions = block.getActions();
		List<VariableDeclarationStatement> variableDeclarationStatements =
				new ArrayList<VariableDeclarationStatement>();
		for (Action subaction : subactions) {
			if (subaction instanceof VariableDeclarationStatement) {
				VariableDeclarationStatement statement =
						(VariableDeclarationStatement) subaction;
				variableDeclarationStatements.add(statement);
			}
		}
		return variableDeclarationStatements;
	}
	
	public static List<VariableDeclaration> getVariableDeclarations(Block block) {
		List<VariableDeclarationStatement> variableDeclarationStatements =
				getVariableDeclarationStatements(block);
		List<VariableDeclaration> variableDeclarations = new ArrayList<VariableDeclaration>();
		for (VariableDeclarationStatement variableDeclarationStatement :
				variableDeclarationStatements) {
			variableDeclarations.add(variableDeclarationStatement.getVariableDeclaration());
		}
		return variableDeclarations;
	}
	
	public static List<VariableDeclarationStatement> getPrecedingVariableDeclarationStatements(
			Block block, Action action) {
		EList<Action> subactions = block.getActions();
		int index = subactions.indexOf(action);
		List<VariableDeclarationStatement> localVariableDeclarations =
				new ArrayList<VariableDeclarationStatement>();
		for (int i = 0; i < index; ++i) {
			EObject subaction = subactions.get(i);
			if (subaction instanceof VariableDeclarationStatement) {
				VariableDeclarationStatement statement =
						(VariableDeclarationStatement) subaction;
				localVariableDeclarations.add(statement);
			}
		}
		return localVariableDeclarations;
	}
	
	public static List<VariableDeclaration> getPrecedingVariableDeclarations(
			Block block, Action action) {
		List<VariableDeclarationStatement> precedingVariableDeclarationStatements =
				getPrecedingVariableDeclarationStatements(block, action);
		List<VariableDeclaration> localVariableDeclarations =
				new ArrayList<VariableDeclaration>();
		for (VariableDeclarationStatement precedingVariableDeclarationStatement :
				precedingVariableDeclarationStatements) {
			localVariableDeclarations.add(
					precedingVariableDeclarationStatement.getVariableDeclaration());
		}
		return localVariableDeclarations;
	}
	
}
