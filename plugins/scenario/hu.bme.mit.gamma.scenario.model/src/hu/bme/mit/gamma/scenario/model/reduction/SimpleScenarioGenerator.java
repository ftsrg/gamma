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
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrence;
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrenceSet;
import hu.bme.mit.gamma.scenario.model.Fragment;
import hu.bme.mit.gamma.scenario.model.InitialBlock;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment;
import hu.bme.mit.gamma.scenario.model.NegPermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.NegStrictAnnotation;
import hu.bme.mit.gamma.scenario.model.NegatedDeterministicOccurrence;
import hu.bme.mit.gamma.scenario.model.NegatedWaitAnnotation;
import hu.bme.mit.gamma.scenario.model.Occurrence;
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment;
import hu.bme.mit.gamma.scenario.model.ParallelCombinedFragment;
import hu.bme.mit.gamma.scenario.model.PermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.ScenarioAssignmentStatement;
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.ScenarioModelFactory;
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
	private Fragment previousFragment = null;
	private GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	private JavaUtil javaUtil = JavaUtil.INSTANCE;
	private ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;

	public ScenarioDeclaration execute() {
		simple = factory.createScenarioDeclaration();
		simple.setName(base.getName());
		simple.setFragment(factory.createFragment());
		simple.setInitialBlock(handleInitBlockCopy());
		refResolver.resolveReferences(base);
		for (Annotation annotation : base.getAnnotation()) {
			simple.getAnnotation().add((Annotation) this.doSwitch(annotation));
		}
		for (VariableDeclaration variable : base.getVariableDeclarations()) {
			simple.getVariableDeclarations().add(ecoreUtil.clone(variable));
		}
		previousFragment = simple.getFragment();
		for (Occurrence interaction : base.getFragment().getInteractions()) {
			simple.getFragment().getInteractions().add((Occurrence) this.doSwitch(interaction));
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
		if (base.getInitialBlock() == null) {
			return null;
		}
		InitialBlock initBloc = factory.createInitialBlock();
		for (DeterministicOccurrence interaction : base.getInitialBlock().getInteractions()) {
			initBloc.getInteractions().add((DeterministicOccurrence) doSwitch(interaction));
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
		for (Fragment fragment : object.getFragments()) {
			boolean shouldBeAdded = true;
			Occurrence firstInteraction = fragment.getInteractions().get(0);
			if (firstInteraction instanceof DeterministicOccurrenceSet) {
				DeterministicOccurrenceSet set = (DeterministicOccurrenceSet) firstInteraction;
				List<ScenarioCheckExpression> checks = javaUtil.filterIntoList(set.getDeterministicOccurrences(),
						ScenarioCheckExpression.class);
				for (int i = 0; i < checks.size(); i++) {
					ScenarioCheckExpression check = checks.get(i);
					try {
						shouldBeAdded = shouldBeAdded && evaluator.evaluateBoolean(check.getExpression());
					} catch (Exception e) {
						// Empty on purpose
					}
				}
			}
			if (shouldBeAdded) {
				acf.getFragments().add((Fragment) this.doSwitch(fragment));
			}
		}
		return acf;
	}

	@Override
	public EObject caseFragment(Fragment object) {
		Fragment prev = previousFragment;
		Fragment fragment = factory.createFragment();
		previousFragment = fragment;
		for (Occurrence a : object.getInteractions()) {
			fragment.getInteractions().add((Occurrence) this.doSwitch(a));
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
			Fragment fragment = factory.createFragment();
			loop.getFragments().add(fragment);

			for (Occurrence interaction : object.getFragments().get(0).getInteractions()) {
				fragment.getInteractions().add((Occurrence) this.doSwitch(interaction));
			}

			return loop;
		} else {
			Fragment prev = previousFragment;
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
				for (Occurrence j : object.getFragments().get(0).getInteractions()) {
					previousFragment.getInteractions().add((Occurrence) this.doSwitch(j));
				}
			}
			for (int i = 0; i <= max - min; i++) {
				Fragment frag = factory.createFragment();
				previousFragment = frag;
				for (int k = 0; k < i + 1; k++)
					for (Occurrence j : object.getFragments().get(0).getInteractions()) {
						frag.getInteractions().add((Occurrence) this.doSwitch(j));
					}
				alt.getFragments().add(frag);
			}
			previousFragment = prev;
			return alt;
		}
	}

	@Override
	public EObject caseOptionalCombinedFragment(OptionalCombinedFragment object) {
		Fragment prev = previousFragment;
		OptionalCombinedFragment opt = factory.createOptionalCombinedFragment();
		Fragment fragment = factory.createFragment();
		previousFragment = fragment;
		fragment = (Fragment) this.doSwitch(object.getFragments().get(0));
		opt.getFragments().clear();
		opt.getFragments().add(fragment);
		previousFragment = prev;
		return opt;
	}

	@Override
	public EObject caseUnorderedCombinedFragment(UnorderedCombinedFragment object) {
		Fragment prev = previousFragment;
		AlternativeCombinedFragment alt = factory.createAlternativeCombinedFragment();
		java.util.List<List<Integer>> permutations = new ArrayList<List<Integer>>();
		List<Integer> list = new ArrayList<>();
		for (int i = 0; i < object.getFragments().size(); i++) {
			list.add(i + 1);
		}
		ScenarioReductionUtil.generatePermutation(list.size(), list, permutations);
		for (int i = 0; i < permutations.size(); i++) {
			Fragment iff = factory.createFragment();
			previousFragment = iff;
			for (int j = 0; j < permutations.get(i).size(); j++) {
				iff.getInteractions()
						.addAll(((Fragment) this.doSwitch(object.getFragments().get(permutations.get(i).get(j) - 1)))
								.getInteractions());
			}
			alt.getFragments().add(iff);
		}
		previousFragment = prev;
		return alt;
	}

	@Override
	public EObject caseParallelCombinedFragment(ParallelCombinedFragment object) {
		Fragment prev = previousFragment;
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
			Fragment iff = factory.createFragment();
			previousFragment = iff;
			for (FragmentInteractionPair f : l) {
				EObject i = this
						.doSwitch(object.getFragments().get(f.getFragment()).getInteractions().get(f.getInteraction()));
				if (i instanceof Occurrence)
					iff.getInteractions().add((Occurrence) i);
				else
					System.out.println(i + ": not interaction");
			}
			alt.getFragments().add(iff);
		}
		previousFragment = prev;
		return alt;
	}

	@Override
	public EObject caseNegatedDeterministicOccurrence(NegatedDeterministicOccurrence object) {
		NegatedDeterministicOccurrence negatedModalInteraction = factory.createNegatedDeterministicOccurrence();
		negatedModalInteraction.setDeterministicOccurrence(
				(DeterministicOccurrence) this.doSwitch(object.getDeterministicOccurrence()));
		return negatedModalInteraction;
	}

	@Override
	public EObject caseInteraction(Interaction object) {
		Interaction signal = factory.createInteraction();
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
	public EObject caseDeterministicOccurrenceSet(DeterministicOccurrenceSet object) {
		DeterministicOccurrenceSet modalInteractionSet = factory.createDeterministicOccurrenceSet();
		for (DeterministicOccurrence id : object.getDeterministicOccurrences()) {
			modalInteractionSet.getDeterministicOccurrences().add((DeterministicOccurrence) this.doSwitch(id));
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
		if (object.getMaximum() == null) {
			delay.setMaximum(expressionFactory.createInfinityExpression());
		} else {
			delay.setMaximum(ecoreUtil.clone(object.getMaximum()));
		}
		delay.setMinimum(ecoreUtil.clone(object.getMinimum()));
		if (object.eContainer() instanceof DeterministicOccurrenceSet) {
			return delay;
		} else {
			DeterministicOccurrenceSet set = factory.createDeterministicOccurrenceSet();
			set.getDeterministicOccurrences().add(delay);
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
