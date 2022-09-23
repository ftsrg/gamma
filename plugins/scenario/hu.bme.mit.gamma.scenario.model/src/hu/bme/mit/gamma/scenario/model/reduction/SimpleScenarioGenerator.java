/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.model.reduction;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment;
import hu.bme.mit.gamma.scenario.model.Annotation;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.InitialBlock;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.NegPermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.NegStrictAnnotation;
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction;
import hu.bme.mit.gamma.scenario.model.NegatedWaitAnnotation;
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment;
import hu.bme.mit.gamma.scenario.model.ParallelCombinedFragment;
import hu.bme.mit.gamma.scenario.model.PermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.Reset;
import hu.bme.mit.gamma.scenario.model.ScenarioAssignmentStatement;
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.ScenarioModelFactory;
import hu.bme.mit.gamma.scenario.model.Signal;
import hu.bme.mit.gamma.scenario.model.StrictAnnotation;
import hu.bme.mit.gamma.scenario.model.UnorderedCombinedFragment;
import hu.bme.mit.gamma.scenario.model.WaitAnnotation;
import hu.bme.mit.gamma.scenario.model.util.ScenarioModelSwitch;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class SimpleScenarioGenerator extends ScenarioModelSwitch<EObject> {

	private ScenarioDeclaration base = null;
	private ScenarioDeclaration simple = null;
	private ScenarioModelFactory factory = ScenarioModelFactory.eINSTANCE;
	private ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	private boolean transformLoopFragments = false;
	private List<Expression> arguments = null;
	private ScenarioReferenceResolver refResolver = new ScenarioReferenceResolver();

	public SimpleScenarioGenerator(ScenarioDeclaration base, boolean transformLoopFragments) {
		this(base, transformLoopFragments, new LinkedList<Expression>());
	}

	public SimpleScenarioGenerator(ScenarioDeclaration base, boolean transformLoopFragments,
			List<Expression> parameters) {
		this.base = ecoreUtil.clone(base); // cloned so the variables and other objects are not moved from the original
		this.transformLoopFragments = transformLoopFragments;
		this.arguments = parameters;
	}

	// Needs to be saved and reset after handling a new InteractionFragment, needs
	// to be kept for transformation of loop fragment
	private InteractionFragment previousFragment = null;
	private GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	private JavaUtil javaUtil = JavaUtil.INSTANCE;
	private ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;

	public ScenarioDeclaration execute() {
		simple = factory.createScenarioDeclaration();
		simple.setName(base.getName());
		simple.setChart(factory.createChart());
		simple.getChart().setFragment(factory.createInteractionFragment());
		simple.setInitialblock(handleInitBlockCopy());
		refResolver.resolveReferences(base);
		for (Annotation annotation : base.getAnnotation()) {
			simple.getAnnotation().add((Annotation) this.doSwitch(annotation));
		}
		for (VariableDeclaration variable : base.getVariableDeclarations()) {
			simple.getVariableDeclarations().add(ecoreUtil.clone(variable));
		}
		previousFragment = simple.getChart().getFragment();
		for (Interaction interaction : base.getChart().getFragment().getInteractions()) {
			simple.getChart().getFragment().getInteractions().add((Interaction) this.doSwitch(interaction));
		}
		inlineExpressions(simple, base);
		return simple;
	}

	private void inlineExpressions(ScenarioDeclaration simple, ScenarioDeclaration base) {
		List<DirectReferenceExpression> references = ecoreUtil.getAllContentsOfType(simple,
				DirectReferenceExpression.class);
		for (DirectReferenceExpression direct : references) {
			Declaration declaration = direct.getDeclaration();
			if (declaration instanceof ConstantDeclaration) {
				ConstantDeclaration _const = (ConstantDeclaration) declaration;
				Expression cloned = ecoreUtil.clone(_const.getExpression());
				EObject container = direct.eContainer();
				ecoreUtil.change(cloned, direct, container);
				ecoreUtil.replace(cloned, direct);
			}
			if (declaration instanceof ParameterDeclaration) {
				ParameterDeclaration param = (ParameterDeclaration) declaration;
				for (ParameterDeclaration paramD : base.getParameterDeclarations()) {
					if (paramD.getName() == param.getName()) {
						int index = base.getParameterDeclarations().indexOf(paramD);
						Expression _new = arguments.get(index);
						Expression cloned = ecoreUtil.clone(_new);
						ecoreUtil.change(cloned, direct, direct.eContainer());
						ecoreUtil.replace(cloned, direct);
					}
				}
			}
			if (declaration instanceof VariableDeclaration) {
				VariableDeclaration variable = (VariableDeclaration) declaration;
				for (VariableDeclaration newVar : simple.getVariableDeclarations()) {
					if (newVar.getName().equals(variable.getName())) {
						DirectReferenceExpression newRef = ecoreUtil.clone(direct);
						newRef.setDeclaration(newVar);
						ecoreUtil.change(newRef, direct, direct.eContainer());
						ecoreUtil.replace(newRef, direct);
					}
				}
			}
		}
	}

	private InitialBlock handleInitBlockCopy() {
		if (base.getInitialblock() == null) {
			return null;
		}
		InitialBlock initBloc = factory.createInitialBlock();
		for (InteractionDefinition interaction : base.getInitialblock().getInteractions()) {
			initBloc.getInteractions().add((InteractionDefinition) doSwitch(interaction));
		}
		return initBloc;
	}

	@Override
	public EObject caseStrictAnnotation(StrictAnnotation object) {
		return factory.createStrictAnnotation();
	}

	@Override
	public EObject casePermissiveAnnotation(PermissiveAnnotation object) {
		return factory.createPermissiveAnnotation();
	}

	@Override
	public EObject caseNegStrictAnnotation(NegStrictAnnotation object) {
		return factory.createNegStrictAnnotation();
	}

	@Override
	public EObject caseNegPermissiveAnnotation(NegPermissiveAnnotation object) {
		return factory.createNegPermissiveAnnotation();
	}

	@Override
	public EObject caseWaitAnnotation(WaitAnnotation object) {
		WaitAnnotation annotation = factory.createWaitAnnotation();
		annotation.setMaximum(ecoreUtil.clone(object.getMaximum()));
		annotation.setMinimum(ecoreUtil.clone(object.getMinimum()));
		return annotation;
	}

	@Override
	public EObject caseNegatedWaitAnnotation(NegatedWaitAnnotation object) {
		NegatedWaitAnnotation annotation = factory.createNegatedWaitAnnotation();
		annotation.setMaximum(ecoreUtil.clone(object.getMaximum()));
		annotation.setMinimum(ecoreUtil.clone(object.getMinimum()));
		return annotation;
	}

	@Override
	public EObject caseAlternativeCombinedFragment(AlternativeCombinedFragment object) {
		AlternativeCombinedFragment acf = factory.createAlternativeCombinedFragment();
		for (InteractionFragment fragment : object.getFragments()) {
			boolean shouldBeAdded = true;
			Interaction firstInteraction = fragment.getInteractions().get(0);
			if (firstInteraction instanceof ModalInteractionSet) {
				ModalInteractionSet set = (ModalInteractionSet) firstInteraction;
				List<ScenarioCheckExpression> checks= javaUtil.filterIntoList(set.getModalInteractions(), ScenarioCheckExpression.class);
				for (int i = 0; i < checks.size(); i++) {
					ScenarioCheckExpression check = checks.get(i);
					try {
						shouldBeAdded = shouldBeAdded && evaluator.evaluateBoolean(check.getExpression());
					} catch (Exception e) {
						//Empty on purpose
					}
				}
			}
			if (shouldBeAdded) {
				acf.getFragments().add((InteractionFragment) this.doSwitch(fragment));
			}
		}
		return acf;
	}

	@Override
	public EObject caseInteractionFragment(InteractionFragment object) {
		InteractionFragment prev = previousFragment;
		InteractionFragment fragment = factory.createInteractionFragment();
		previousFragment = fragment;
		for (Interaction a : object.getInteractions()) {
			fragment.getInteractions().add((Interaction) this.doSwitch(a));
		}
		previousFragment = prev;
		return fragment;
	}

	@Override
	public EObject caseLoopCombinedFragment(LoopCombinedFragment object) {
		if (!transformLoopFragments) {
			LoopCombinedFragment loop = factory.createLoopCombinedFragment();
			if (object.getMaximum() == null) {
				loop.setMaximum(ecoreUtil.clone(object.getMinimum()));
			} else {
				loop.setMaximum(ecoreUtil.clone(object.getMaximum()));
			}
			loop.setMinimum(ecoreUtil.clone(object.getMinimum()));
			InteractionFragment fragment = factory.createInteractionFragment();
			loop.getFragments().add(fragment);

			for (Interaction interaction : object.getFragments().get(0).getInteractions()) {
				fragment.getInteractions().add((Interaction) this.doSwitch(interaction));
			}

			return loop;
		} else {
			InteractionFragment prev = previousFragment;
			AlternativeCombinedFragment alt = factory.createAlternativeCombinedFragment();
			ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
			Expression minExpression = ecoreUtil.clone(object.getMinimum());
			Expression maxExpression = ecoreUtil.clone(object.getMaximum());
			int min = evaluator.evaluate(minExpression);
			int max = 0;
			if (maxExpression == null) {
				max = min;
			} else {
				max = evaluator.evaluate(maxExpression);
			}
			for (int i = 0; i < min - 1; i++) {
				for (Interaction j : object.getFragments().get(0).getInteractions()) {
					previousFragment.getInteractions().add((Interaction) this.doSwitch(j));
				}
			}
			for (int i = 0; i <= max - min; i++) {
				InteractionFragment frag = factory.createInteractionFragment();
				previousFragment = frag;
				for (int k = 0; k < i + 1; k++)
					for (Interaction j : object.getFragments().get(0).getInteractions()) {
						frag.getInteractions().add((Interaction) this.doSwitch(j));
					}
				alt.getFragments().add(frag);
			}
			previousFragment = prev;
			return alt;
		}
	}

	@Override
	public EObject caseOptionalCombinedFragment(OptionalCombinedFragment object) {
		InteractionFragment prev = previousFragment;
		OptionalCombinedFragment opt = factory.createOptionalCombinedFragment();
		InteractionFragment fragment = factory.createInteractionFragment();
		previousFragment = fragment;
		fragment = (InteractionFragment) this.doSwitch(object.getFragments().get(0));
		opt.getFragments().clear();
		opt.getFragments().add(fragment);
		previousFragment = prev;
		return opt;
	}

	@Override
	public EObject caseUnorderedCombinedFragment(UnorderedCombinedFragment object) {
		InteractionFragment prev = previousFragment;
		AlternativeCombinedFragment alt = factory.createAlternativeCombinedFragment();
		java.util.List<List<Integer>> permutations = new ArrayList<List<Integer>>();
		List<Integer> list = new ArrayList<>();
		for (int i = 0; i < object.getFragments().size(); i++) {
			list.add(i + 1);
		}
		ScenarioReductionUtil.generatePermutation(list.size(), list, permutations);
		for (int i = 0; i < permutations.size(); i++) {
			InteractionFragment iff = factory.createInteractionFragment();
			previousFragment = iff;
			for (int j = 0; j < permutations.get(i).size(); j++) {
				iff.getInteractions().addAll(
						((InteractionFragment) this.doSwitch(object.getFragments().get(permutations.get(i).get(j) - 1)))
								.getInteractions());
			}
			alt.getFragments().add(iff);
		}
		previousFragment = prev;
		return alt;
	}

	@Override
	public EObject caseParallelCombinedFragment(ParallelCombinedFragment object) {
		InteractionFragment prev = previousFragment;
		AlternativeCombinedFragment alt = factory.createAlternativeCombinedFragment();
		List<List<FragmentInteractionPair>> listlist = new ArrayList<List<FragmentInteractionPair>>();
		List<Integer> tmp = new ArrayList<Integer>();
		List<List<Integer>> used = new ArrayList<List<Integer>>();
		List<Integer> maximum = new ArrayList<Integer>();
		for (int i = 0; i < object.getFragments().size(); i++) {
			tmp.add(0);
			maximum.add(object.getFragments().get(i).getInteractions().size());
		}
		listlist.add(new ArrayList<FragmentInteractionPair>());
		used.add(tmp);
		ScenarioReductionUtil.createSequences(listlist, used, maximum);
		for (List<FragmentInteractionPair> l : listlist) {
			InteractionFragment iff = factory.createInteractionFragment();
			previousFragment = iff;
			for (FragmentInteractionPair f : l) {
				EObject i = this
						.doSwitch(object.getFragments().get(f.getFragment()).getInteractions().get(f.getInteraction()));
				if (i instanceof Interaction)
					iff.getInteractions().add((Interaction) i);
				else
					System.out.println(i + ": not interaction");
			}
			alt.getFragments().add(iff);
		}
		previousFragment = prev;
		return alt;
	}

	@Override
	public EObject caseNegatedModalInteraction(NegatedModalInteraction object) {
		NegatedModalInteraction negatedModalInteraction = factory.createNegatedModalInteraction();
		negatedModalInteraction
				.setModalinteraction((InteractionDefinition) this.doSwitch(object.getModalinteraction()));
		return negatedModalInteraction;
	}

	@Override
	public EObject caseReset(Reset object) {
		Reset reset = factory.createReset();
		reset.setModality(object.getModality());
		return reset;
	}

	@Override
	public EObject caseSignal(Signal object) {
		Signal signal = factory.createSignal();
		signal.setDirection(object.getDirection());
		signal.setModality(object.getModality());
		signal.setEvent(object.getEvent());
		signal.setPort(object.getPort());
		for (Expression argument : object.getArguments()) {
			signal.getArguments().add(ecoreUtil.clone(argument));
		}
		return signal;
	}

	@Override
	public EObject caseModalInteractionSet(ModalInteractionSet object) {
		ModalInteractionSet modalInteractionSet = factory.createModalInteractionSet();
		for (InteractionDefinition id : object.getModalInteractions()) {
			modalInteractionSet.getModalInteractions().add((InteractionDefinition) this.doSwitch(id));
		}
		return modalInteractionSet;
	}

	@Override
	public EObject caseScenarioAssignmentStatement(ScenarioAssignmentStatement object) {
		ScenarioAssignmentStatement assignment = factory.createScenarioAssignmentStatement();
		assignment.setLhs(ecoreUtil.clone(object.getLhs()));
		assignment.setRhs(ecoreUtil.clone(object.getRhs()));
		return assignment;
	}

	@Override
	public EObject caseDelay(Delay object) {
		Delay delay = factory.createDelay();
		delay.setModality(object.getModality());
		if (object.getMaximum() == null) {
			delay.setMaximum(expressionFactory.createInfinityExpression());
		} else {
			delay.setMaximum(ecoreUtil.clone(object.getMaximum()));
		}
		delay.setMinimum(ecoreUtil.clone(object.getMinimum()));
		if (object.eContainer() instanceof ModalInteractionSet) {
			return delay;
		} else {
			ModalInteractionSet set = factory.createModalInteractionSet();
			set.getModalInteractions().add(delay);
			return set;
		}
	}

	@Override
	public EObject caseScenarioCheckExpression(ScenarioCheckExpression object) {
		ScenarioCheckExpression check = factory.createScenarioCheckExpression();
		check.setExpression(ecoreUtil.clone(object.getExpression()));
		return check;
	}

}
