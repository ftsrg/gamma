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
package hu.bme.mit.gamma.property.concretization;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.viatra.query.runtime.api.IPatternMatch;

import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReflectiveElementReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class FormulaConcretizer {
	// Singleton
	public static final FormulaConcretizer INSTANCE = new FormulaConcretizer();
	protected FormulaConcretizer() {}
	//
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected final CompositeModelFactory factory = CompositeModelFactory.eINSTANCE;
	//
	public List<CommentableStateFormula> concretize(
			CommentableStateFormula formula, Collection<? extends IPatternMatch> matches) {
		List<CommentableStateFormula> concretizedFormulas = new ArrayList<CommentableStateFormula>();

		for (IPatternMatch match : matches) {
			CommentableStateFormula concretizedFormula = ecoreUtil.clone(formula);

			List<ComponentInstanceReflectiveElementReferenceExpression> references = ecoreUtil.getAllContentsOfType(
					concretizedFormula, ComponentInstanceReflectiveElementReferenceExpression.class);

			for (ComponentInstanceReflectiveElementReferenceExpression reference : references) {
				ComponentInstanceReferenceExpression clonedInstance = ecoreUtil.clone(
						reference.getInstance());
				ComponentInstance lastInstance = StatechartModelDerivedFeatures.getLastInstance(clonedInstance);
				Component type = StatechartModelDerivedFeatures.getDerivedType(lastInstance);
				
				List<String> identifiers = reference.getIdentifier();
				
				List<EObject> elements = new ArrayList<EObject>();
				for (String identifier : identifiers) {
					EObject element = (EObject) match.get(identifier);
					elements.add(element);
				}
			
				EObject firstElement = elements.get(0);
				if (ecoreUtil.containsTransitively(type, firstElement)) {
					ComponentInstanceElementReferenceExpression newReference =
							createInstanceElementReferenceExpression(elements);
					newReference.setInstance(clonedInstance); // Setting instance
					
					ecoreUtil.replace(newReference, reference);
				}
			}
			
			// Add only if the parameters could be removed
			if (!ecoreUtil.containsTypeTransitively(concretizedFormula,
					ComponentInstanceReflectiveElementReferenceExpression.class)) {
				concretizedFormulas.add(concretizedFormula);
			}
		}
		
		ecoreUtil.removeEqualElements(concretizedFormulas);
		
		return concretizedFormulas;
	}

	protected ComponentInstanceElementReferenceExpression createInstanceElementReferenceExpression(
			List<EObject> elements) {
		EObject lastElement = elements.get(elements.size() - 1);
		
		if (lastElement instanceof State state) {
			ComponentInstanceStateReferenceExpression stateReference =
					factory.createComponentInstanceStateReferenceExpression();
			
			stateReference.setRegion(
					StatechartModelDerivedFeatures.getParentRegion(state));
			stateReference.setState(state);
			
			return stateReference;
		}
		else if (lastElement instanceof VariableDeclaration variable) {
			ComponentInstanceVariableReferenceExpression variableReference =
					factory.createComponentInstanceVariableReferenceExpression();
			
			variableReference.setVariableDeclaration(variable);
			
			return variableReference;
		} 
		else if (lastElement instanceof Event event) {
			ComponentInstanceEventReferenceExpression eventReference =
					factory.createComponentInstanceEventReferenceExpression();
			
			Port port = (Port) elements.get(0);
			
			eventReference.setPort(port);
			eventReference.setEvent(event);
			
			return eventReference;
		}
		else if (lastElement instanceof ParameterDeclaration parameterDeclaration) {
			ComponentInstanceEventParameterReferenceExpression eventParameterReference =
					factory.createComponentInstanceEventParameterReferenceExpression();
			
			Port port = (Port) elements.get(0);
			Event event = (Event) elements.get(1);
			
			eventParameterReference.setPort(port);
			eventParameterReference.setEvent(event);
			eventParameterReference.setParameterDeclaration(parameterDeclaration);
			
			return eventParameterReference;
		}
		else if (lastElement instanceof Transition transition) {
			String id = StatechartModelDerivedFeatures.getId(transition);
			if (id == null) {
				throw new IllegalArgumentException("No id for " + transition);
			}
			
			StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(transition);
			List<VariableDeclaration> variableDeclarations = statechart.getVariableDeclarations();
			
			// See hu.bme.mit.gamma.transformation.util.annotations.AnnotationNamings.getVariableName(transition)
			Optional<VariableDeclaration> optionalVariable = variableDeclarations.stream()
					.filter(it -> it.getName().equals(id)).findFirst();
			if (optionalVariable.isEmpty()) {
				throw new IllegalArgumentException("No variable named " + id);
			}
			
			VariableDeclaration transitionVariable = optionalVariable.get();
			
			ComponentInstanceVariableReferenceExpression variableReference =
					factory.createComponentInstanceVariableReferenceExpression();
			variableReference.setVariableDeclaration(transitionVariable);
			
			return variableReference;
		}
		else {
			throw new IllegalArgumentException("Not known element: " + lastElement);
		}
	}

}
