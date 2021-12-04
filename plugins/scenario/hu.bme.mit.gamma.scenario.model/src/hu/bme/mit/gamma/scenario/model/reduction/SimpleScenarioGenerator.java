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
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment;
import hu.bme.mit.gamma.scenario.model.Annotation;
import hu.bme.mit.gamma.scenario.model.DedicatedColdViolationAnnotation;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.InitialBlock;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment;
import hu.bme.mit.gamma.scenario.model.ModalInteraction;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.NegPermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.NegStrictAnnotation;
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction;
import hu.bme.mit.gamma.scenario.model.NegatedWaitAnnotation;
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment;
import hu.bme.mit.gamma.scenario.model.ParallelCombinedFragment;
import hu.bme.mit.gamma.scenario.model.PermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.Reset;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinitionReference;
import hu.bme.mit.gamma.scenario.model.ScenarioModelFactory;
import hu.bme.mit.gamma.scenario.model.Signal;
import hu.bme.mit.gamma.scenario.model.StartAsColdViolationAnnotation;
import hu.bme.mit.gamma.scenario.model.StrictAnnotation;
import hu.bme.mit.gamma.scenario.model.UnorderedCombinedFragment;
import hu.bme.mit.gamma.scenario.model.WaitAnnotation;
import hu.bme.mit.gamma.scenario.model.util.ScenarioModelSwitch;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class SimpleScenarioGenerator extends ScenarioModelSwitch<EObject> {

	private ScenarioDefinition base = null;
	private ScenarioDefinition simple = null;
	private ScenarioModelFactory factory = null;
	private boolean transformLoopFragments = false;
	private List<Expression> parameters = null;
	ScenarioReferenceResolver refResolver = new ScenarioReferenceResolver();

	public SimpleScenarioGenerator(ScenarioDefinition base, boolean transformLoopFragments) {
		this(base, transformLoopFragments, new LinkedList<Expression>());
	}
	
	public SimpleScenarioGenerator(ScenarioDefinition base, boolean transformLoopFragments, List<Expression> parameters) {
		this.base = base;
		this.transformLoopFragments = transformLoopFragments;
		this.parameters  = parameters;
	}

	// Needs to be saved and reset after handling a new InteractionFragment, needs
	// to be kept for transformation of loop fragment
	private InteractionFragment previousFragment = null;
	GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	public ScenarioDefinition execute() {
		factory = ScenarioModelFactory.eINSTANCE;
		simple = factory.createScenarioDefinition();
		simple.setName(base.getName());
		simple.setChart(factory.createChart());
		simple.getChart().setFragment(factory.createInteractionFragment());
		simple.setInitialblock(handleInitBlockCopy());
		refResolver.resolveReferences(base);
		for (Annotation annotation : base.getAnnotation()) {
			simple.getAnnotation().add((Annotation) this.doSwitch(annotation));
		}
		previousFragment = simple.getChart().getFragment();
		for (Interaction interaction : base.getChart().getFragment().getInteractions()) {
			simple.getChart().getFragment().getInteractions().add((Interaction) this.doSwitch(interaction));
		}
		return simple;
	}
	
	private Expression extractExpression(Expression expr) {
		if (expr instanceof DirectReferenceExpression) {
			DirectReferenceExpression ref = (DirectReferenceExpression) expr;
			Declaration decl = ref.getDeclaration();
			if (decl instanceof ConstantDeclaration) {
				ConstantDeclaration _const = (ConstantDeclaration) decl;
				return ecoreUtil.clone(_const.getExpression());
			}
			if(decl instanceof ParameterDeclaration)
			{
				ParameterDeclaration param = (ParameterDeclaration) decl;
				for(ParameterDeclaration paramD: base.getParameterDeclarations()) {
					if(paramD.getName() == param.getName()) {
						return ecoreUtil.clone(parameters.get(base.getParameterDeclarations().indexOf(paramD)));
					}
				}
			}
			throw new IllegalArgumentException();
		}
		return ecoreUtil.clone(expr);
	}

	private InitialBlock handleInitBlockCopy() {
		if (base.getInitialblock() == null) {
			return null;
		}
		InitialBlock initBloc = factory.createInitialBlock();
		for (ModalInteraction modalInteraction : base.getInitialblock().getModalInteractions()) {
			initBloc.getModalInteractions().add((ModalInteraction) doSwitch(modalInteraction));
		}
		return initBloc;
	}

	@Override
	public EObject caseStrictAnnotation(StrictAnnotation object) {
		return factory.createStrictAnnotation();
	}

	@Override
	public EObject caseDedicatedColdViolationAnnotation(DedicatedColdViolationAnnotation object) {
		return factory.createDedicatedColdViolationAnnotation();
	}

	@Override
	public EObject caseStartAsColdViolationAnnotation(StartAsColdViolationAnnotation object) {
		return factory.createStartAsColdViolationAnnotation();
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
		annotation.setMaximum(extractExpression(object.getMaximum()));
		annotation.setMinimum(extractExpression(object.getMinimum()));
		return annotation;
	}

	@Override
	public EObject caseNegatedWaitAnnotation(NegatedWaitAnnotation object) {
		NegatedWaitAnnotation annotation = factory.createNegatedWaitAnnotation();
		annotation.setMaximum(extractExpression(object.getMaximum()));
		annotation.setMinimum(extractExpression(object.getMinimum()));
		return annotation;
	}

	@Override
	public EObject caseAlternativeCombinedFragment(AlternativeCombinedFragment object) {
		AlternativeCombinedFragment acf = factory.createAlternativeCombinedFragment();
		for (InteractionFragment fragment : object.getFragments()) {
			acf.getFragments().add((InteractionFragment) this.doSwitch(fragment));
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
			loop.setMaximum(extractExpression(object.getMaximum()));
			loop.setMinimum(extractExpression(object.getMinimum()));
			InteractionFragment fragment = factory.createInteractionFragment();
			loop.getFragments().add(fragment);

			for (Interaction interaction : object.getFragments().get(0).getInteractions()) {
				fragment.getInteractions().add((Interaction) this.doSwitch(interaction));
			}

			return loop;
		}
		InteractionFragment prev = previousFragment;
		AlternativeCombinedFragment alt = factory.createAlternativeCombinedFragment();
		ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
		Expression mine = extractExpression(object.getMinimum());
		Expression maxe = extractExpression(object.getMaximum());
		int min = evaluator.evaluate(mine);
		int max = 0;
		if (maxe == null) {
			max = min;
		} else {
			max = evaluator.evaluate(maxe);
		}
		for (int i = 0; i < min; i++) {
			for (Interaction j : object.getFragments().get(0).getInteractions()) {
				previousFragment.getInteractions().add((Interaction) this.doSwitch(j));
			}
		}
		for (int i = 0; i <= max - min; i++) {
			InteractionFragment frag = factory.createInteractionFragment();
			previousFragment = frag;
			for (int k = 0; k < i; k++)
				for (Interaction j : object.getFragments().get(0).getInteractions()) {
					frag.getInteractions().add((Interaction) this.doSwitch(j));
				}
			alt.getFragments().add(frag);
		}
		previousFragment = prev;
		return alt;
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
		generatePermutation(list.size(), list, permutations);
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

	// Heap's Algorithm
	public static void generatePermutation(int k, List<Integer> a, List<List<Integer>> l) {

		if (k == 1) {
			l.add(new ArrayList<Integer>(a));
		} else {
			for (int i = 0; i < (k - 1); i++) {
				int tmp;
				generatePermutation(k - 1, a, l);
				if (k % 2 == 0) {
					tmp = a.get(i);
					a.set(i, a.get(k - 1));
					a.set(k - 1, tmp);
				} else {
					tmp = a.get(0);
					a.set(0, a.get(k - 1));
					a.set(k - 1, tmp);
				}
			}
			generatePermutation(k - 1, a, l);
		}
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
		createSequences(listlist, used, maximum);
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

	private void createSequences(List<List<FragmentInteractionPair>> listlist, List<List<Integer>> used,
			List<Integer> maximum) {

		boolean ok = false;

		while (!ok) {
			boolean wasAdded = false;
			for (int i = 0; i < used.get(0).size(); i++) {
				if (used.get(0).get(i) < maximum.get(i)) {
					wasAdded = true;
					List<FragmentInteractionPair> tmplist = new ArrayList<FragmentInteractionPair>();
					List<Integer> tmpused = new ArrayList<Integer>();
					for (int j = 0; j < used.get(0).size(); j++) {
						tmpused.add(used.get(0).get(j));
					}
					for (int j = 0; j < listlist.get(0).size(); j++) {
						tmplist.add(listlist.get(0).get(j));
					}
					tmplist.add(new FragmentInteractionPair(i, tmpused.get(i)));
					tmpused.set(i, tmpused.get(i) + 1);

					used.add(tmpused);
					listlist.add(tmplist);
				}
			}
			if (!wasAdded) {
				used.add(used.get(0));
				listlist.add(listlist.get(0));
			}
			used.remove(0);
			listlist.remove(0);
			ok = done(used, maximum);
		}
	}

	private boolean done(List<List<Integer>> used, List<Integer> maximum) {
		for (List<Integer> l : used) {
			for (int i = 0; i < l.size(); i++) {
				if (l.get(i) != maximum.get(i))
					return false;
			}
		}
		return true;
	}

	@Override
	public EObject caseNegatedModalInteraction(NegatedModalInteraction object) {
		NegatedModalInteraction negatedModalInteraction = factory.createNegatedModalInteraction();
		negatedModalInteraction.setModalinteraction((InteractionDefinition) this.doSwitch(object.getModalinteraction()));
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
			signal.getArguments().add(extractExpression(argument));
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
	public EObject caseDelay(Delay object) {
		Delay delay = factory.createDelay();
		delay.setModality(object.getModality());
		if (object.getMaximum() == null)

			delay.setMaximum(extractExpression(object.getMinimum()));
		else
			delay.setMaximum(extractExpression(object.getMaximum()));
		delay.setMinimum(extractExpression(object.getMinimum()));
		return delay;
	}

}
