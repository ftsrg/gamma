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
package hu.bme.mit.gamma.serializer.commandhandler;

import java.util.Collection;
import java.util.HashSet;
import java.util.List;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.Command;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelFactory;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.statechart.TransitionAnnotation;
import hu.bme.mit.gamma.statechart.statechart.TransitionIdAnnotation;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class TransitionIdAdder extends AbstractHandler {

	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected final ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE;
	protected final StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;
	
	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		try {
			ISelection sel = HandlerUtil.getActiveMenuSelection(event);
			if (sel instanceof IStructuredSelection) {
				IStructuredSelection selection = (IStructuredSelection) sel;
				Object firstElement = selection.getFirstElement();
				if (firstElement != null) {
					if (firstElement instanceof IFile) {
						Command command = event.getCommand();
						String name = command.getId();
						boolean addAnnotations = name.equals("hu.bme.mit.gamma.statechart.transition.id.add");
						
						IFile file = (IFile) firstElement;
						String path = file.getFullPath().toString();
						
						ResourceSet resourceSet = new ResourceSetImpl();
						URI fileUri = URI.createPlatformResourceURI(path, true);
						Resource resource = resourceSet.getResource(fileUri, true);
						
						EObject object = resource.getContents().get(0);
						Package gammaPackage = (Package) object;
						
						List<StatechartDefinition> statecharts = javaUtil.filterIntoList(
								gammaPackage.getComponents(), StatechartDefinition.class);
						for (StatechartDefinition statechart : statecharts) {
							List<Transition> transitions = statechart.getTransitions();
							for (Transition transition : transitions) {
								if (addAnnotations) {
									addAnnotation(transition);
								}
								else {
									removeAnnotation(transition);
								}
							}
						}
						
						ecoreUtil.save(gammaPackage);
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return null;
	}

	protected void addAnnotation(Transition transition) {
		StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(transition);
		// Id
		TransitionIdAnnotation idAnnotation = statechartFactory.createTransitionIdAnnotation();
		
		List<TransitionAnnotation> annotations = transition.getAnnotations();
		// Now we just remove the original transition annotations
		annotations.removeIf(it -> it instanceof TransitionAnnotation);
		//
		annotations.add(idAnnotation);
		
		String id = getTransitionIdName(transition);
		idAnnotation.setName(id);
		
		// Variable
		VariableDeclaration transitionVariable = statechartUtil.createVariableDeclaration(
				expressionFactory.createBooleanTypeDefinition(), id, expressionFactory.createFalseExpression());
		statechartUtil.addResettableAnnotation(transitionVariable);
		statechart.getVariableDeclarations().add(transitionVariable);
		
		// Transition
		AssignmentStatement assignment = statechartUtil.createAssignment(
				transitionVariable, expressionFactory.createTrueExpression());
		
		transition.getEffects().add(assignment);
	}
	
	protected void removeAnnotation(Transition transition) {
		List<TransitionAnnotation> annotations = transition.getAnnotations();
		// Now we just remove the original transition annotations
		annotations.removeIf(it -> it instanceof TransitionAnnotation);
		//
		
		String id = getTransitionIdName(transition);
		
		Collection<Action> effects = new HashSet<Action>(
				transition.getEffects());
		for (Action effect : effects) {
			if (effect instanceof AssignmentStatement assignment) {
				ReferenceExpression lhs = assignment.getLhs();
				Declaration declaration = statechartUtil.getAccessedDeclaration(lhs);
				if (declaration instanceof VariableDeclaration variable) {
					String name = variable.getName();
					if (name.equals(id) && StatechartModelDerivedFeatures.isResettable(variable)) {
						ecoreUtil.remove(effect);
						ecoreUtil.remove(variable);
					}
				}
			}
		}
	}
	
	//
	
	protected String getTransitionIdName(Transition transition) {
		return transition.getSourceState().getName() + "_" +
				transition.getTargetState().getName() + "_" + ecoreUtil.getIndexOrZero(transition);
	}

}
