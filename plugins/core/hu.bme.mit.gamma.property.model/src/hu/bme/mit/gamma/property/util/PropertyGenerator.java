package hu.bme.mit.gamma.property.util;

import java.math.BigInteger;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Optional;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.property.model.PropertyModelFactory;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Transition;

public class PropertyGenerator {
	// Singleton
	public static final PropertyGenerator INSTANCE = new PropertyGenerator();
	protected PropertyGenerator() {}
	//
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	protected ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected PropertyModelFactory factory = PropertyModelFactory.eINSTANCE;
	
	protected PropertyPackage initializePackage(EObject object) {
		PropertyPackage propertyPackage = factory.createPropertyPackage();
		
		Package _package = StatechartModelDerivedFeatures.getContainingPackage(object);
		Component firstComponent = _package.getComponents().get(0);
		
		propertyPackage.getImport().add(_package);
		propertyPackage.setComponent(firstComponent);
		
		return propertyPackage;
	}
	
	protected PropertyPackage createBooleanReachability(
			Map<Transition, VariableDeclaration> transitionVariables) {
		if (transitionVariables.isEmpty()) {
			throw new IllegalArgumentException("Empty map: " + transitionVariables);
		}
		
		Optional<Transition> transition = transitionVariables.keySet().stream().findAny();
		PropertyPackage propertyPackage = initializePackage(transition.get());
		
		for (Entry<Transition, VariableDeclaration> entry : transitionVariables.entrySet()) {
			VariableDeclaration variable = entry.getValue();
			ReferenceExpression reference = expressionFactory.createReferenceExpression();
			reference.setDeclaration(variable);
			StateFormula stateFormula = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(reference));
			propertyPackage.getFormulas().add(stateFormula);
		}
		
		return propertyPackage;
	}
	
	protected PropertyPackage createIntegerReachability(
			Map<Entry<RaiseEventAction, Transition>, Entry<VariableDeclaration, Integer>> interactions) {
		if (interactions.isEmpty()) {
			throw new IllegalArgumentException("Empty map: " + interactions);
		}
		
		Optional<Entry<RaiseEventAction, Transition>> interaction = interactions.keySet().stream().findAny();
		PropertyPackage propertyPackage = initializePackage(interaction.get().getValue());
		
		for (Entry<Entry<RaiseEventAction, Transition>, Entry<VariableDeclaration, Integer>> entry :
				interactions.entrySet()) {
			Entry<VariableDeclaration, Integer> value = entry.getValue();
			VariableDeclaration variable = value.getKey();
			Integer id = value.getValue();
			
			EqualityExpression equalityExpression = expressionFactory.createEqualityExpression();
			ReferenceExpression reference = expressionFactory.createReferenceExpression();
			reference.setDeclaration(variable);
			IntegerLiteralExpression literal = expressionFactory.createIntegerLiteralExpression();
			literal.setValue(BigInteger.valueOf(id));
			equalityExpression.setLeftOperand(reference);
			equalityExpression.setRightOperand(literal);
			
			StateFormula stateFormula = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(equalityExpression));
			propertyPackage.getFormulas().add(stateFormula);
		}
		
		return propertyPackage;
	}
	
}
