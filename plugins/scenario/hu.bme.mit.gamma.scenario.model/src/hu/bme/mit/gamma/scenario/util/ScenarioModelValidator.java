/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2;
import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment;
import hu.bme.mit.gamma.scenario.model.Annotation;
import hu.bme.mit.gamma.scenario.model.CombinedFragment;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrence;
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrenceSet;
import hu.bme.mit.gamma.scenario.model.Fragment;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionDirection;
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment;
import hu.bme.mit.gamma.scenario.model.ModalityType;
import hu.bme.mit.gamma.scenario.model.NegPermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.NegStrictAnnotation;
import hu.bme.mit.gamma.scenario.model.NegatedDeterministicOccurrence;
import hu.bme.mit.gamma.scenario.model.Occurrence;
import hu.bme.mit.gamma.scenario.model.ParallelCombinedFragment;
import hu.bme.mit.gamma.scenario.model.PermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.ScenarioAssignmentStatement;
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinitionReference;
import hu.bme.mit.gamma.scenario.model.ScenarioModelPackage;
import hu.bme.mit.gamma.scenario.model.ScenarioPackage;
import hu.bme.mit.gamma.scenario.model.StrictAnnotation;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Persistency;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.util.ExpressionTypeDeterminator;

public class ScenarioModelValidator extends ExpressionModelValidator {
	// Singleton
	public static final ScenarioModelValidator INSTANCE = new ScenarioModelValidator();

	private static final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;

	protected ScenarioModelValidator() {
		super.typeDeterminator = ExpressionTypeDeterminator.INSTANCE; // For eventParamreference
	}
	//

	protected final ExpressionTypeDeterminator2 typeDeterminator = ExpressionTypeDeterminator2.INSTANCE;

	public Collection<ValidationResultMessage> checkIncompatibleAnnotations(ScenarioDeclaration scenario) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		boolean strictPresent = false;
		boolean permissivePresent = false;
		boolean negstrictPresent = false;
		boolean negpermissivePresent = false;
		for (Annotation annotation : scenario.getAnnotation()) {
			if (annotation instanceof StrictAnnotation) {
				strictPresent = true;
			} else if (annotation instanceof PermissiveAnnotation) {
				permissivePresent = true;
			} else if (annotation instanceof NegStrictAnnotation) {
				negstrictPresent = true;
			} else if (annotation instanceof NegPermissiveAnnotation) {
				negpermissivePresent = true;
			}
		}
		if (permissivePresent && strictPresent) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"A scenario should be annotated with either a permissive or strict annotation",
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		if (negpermissivePresent && negstrictPresent) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"A scenario should be annotated with either a permissive or strict annotation " +
							"with respect to negated sends blocks",
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkScenarioNamesAreUnique(ScenarioPackage scenarioPackage) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		for (ScenarioDeclaration scenarioDeclaration : scenarioPackage.getScenarios()) {
			int i = 0;
			for (ScenarioDeclaration otherScenario : scenarioPackage.getScenarios()) {
				if (scenarioDeclaration.getName().equals(otherScenario.getName())) {
					i++;
				}
			}
			if (i > 1) {
				validationResultMessages
						.add(new ValidationResultMessage(ValidationResult.ERROR, "Scenario names should be unique",
								new ReferenceInfo(ScenarioModelPackage.Literals.SCENARIO_PACKAGE__SCENARIOS)));
				return validationResultMessages;
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkAtLeastOneHotSignalInChart(ScenarioDeclaration scenario) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		boolean allCold = scenario.getFragment().getInteractions().stream()
				.allMatch((i) -> interactionIsCold(i));
		if (allCold) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
					"There should be at least one hot interaction in the scenario",
					new ReferenceInfo(ScenarioModelPackage.Literals.SCENARIO_PACKAGE__SCENARIOS, ecoreUtil.getIndex(scenario), scenario.eContainer())));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkDeterministicOccurrenceSets(DeterministicOccurrenceSet deterministicOccurrenceSet) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ScenarioPackage scenario = ecoreUtil.getContainerOfType(deterministicOccurrenceSet, ScenarioPackage.class);
		Component component = scenario.getComponent();
		int idx = -1;
		if (deterministicOccurrenceSet.eContainer() instanceof NegatedDeterministicOccurrence) {
			idx = ecoreUtil.getIndex(deterministicOccurrenceSet.eContainer());
		} else {
			idx = ecoreUtil.getIndex(deterministicOccurrenceSet);
		}
		EObject eContainer = deterministicOccurrenceSet.eContainer();
		if (component instanceof SynchronousComponent) {
			List<DeterministicOccurrenceSet> sets = ecoreUtil.getAllContentsOfType(deterministicOccurrenceSet,
					DeterministicOccurrenceSet.class);
			if (!sets.isEmpty()) {
				// Just to make sure, in the current grammar this is impossible
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Modal interaction sets cannot contain modal interaction sets",
						new ReferenceInfo(deterministicOccurrenceSet.eContainingFeature(), idx, eContainer)));
			}
		} else {
			List<Interaction> interactions = ecoreUtil.getAllContentsOfType(deterministicOccurrenceSet,
					Interaction.class);
			if (interactions.size() > 1) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Scenarios with respect to asynchronous components cannot contain modal interaction sets with more than one interaction",
						new ReferenceInfo(deterministicOccurrenceSet.eContainingFeature(), idx, eContainer)));
			}
		}
		
		List<Interaction> interactions = javaUtil.filterIntoList(deterministicOccurrenceSet.getDeterministicOccurrences(), Interaction.class);
		if (!interactions.isEmpty()) {
			boolean allHot = interactions.stream().allMatch((it) -> (it.getModality().equals(ModalityType.HOT)));
			boolean allCold = interactions.stream().allMatch((it) -> (it.getModality().equals(ModalityType.COLD)));
			if (!allCold && !allHot) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Interactions should have the same modality within the same set",
						new ReferenceInfo(deterministicOccurrenceSet.eContainingFeature(), idx, eContainer)));
			}
		}
		
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkFirstInteractionsModalityIsTheSame(
			CombinedFragment combinedFragment) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (combinedFragment.getFragments().size() > 1) {
			ModalityType firstModality = getFirstInteractionsModality(
					combinedFragment.getFragments().get(0).getInteractions());
			for (Fragment fragment : combinedFragment.getFragments()) {
				ModalityType tmpModality = getFirstInteractionsModality(fragment.getInteractions());
				if (!tmpModality.equals(firstModality)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"First interaction's modality should be the same in each fragment " +
									"belonging to the same combined fragment",
							new ReferenceInfo(ScenarioModelPackage.Literals.COMBINED_FRAGMENT__FRAGMENTS)));
					return validationResultMessages;
				}
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkPortCanSendSignal(Interaction signal) {
		if (signal.getDirection() != InteractionDirection.SEND) {
			return new ArrayList<ValidationResultMessage>();
		}
		// PROVIDED -> IN is IN, OUT is OUT; REQUIRED -> IN is OUT, OUT is IN
		Map<RealizationMode, EventDirection> expectedDirections = new HashMap<>();
		expectedDirections.put(RealizationMode.PROVIDED, EventDirection.OUT);
		expectedDirections.put(RealizationMode.REQUIRED, EventDirection.IN);
		return checkEventDirections(signal, expectedDirections, "Port cannot send");
	}

	public Collection<ValidationResultMessage> checkPortCanReceiveSignal(Interaction signal) {
		if (signal.getDirection() != InteractionDirection.RECEIVE) {
			return new ArrayList<ValidationResultMessage>();
		}
		// PROVIDED -> IN is IN, OUT is OUT; REQUIRED -> IN is OUT, OUT is IN
		Map<RealizationMode, EventDirection> expectedDirections = new HashMap<>();
		expectedDirections.put(RealizationMode.PROVIDED, EventDirection.IN);
		expectedDirections.put(RealizationMode.REQUIRED, EventDirection.OUT);
		return checkEventDirections(signal, expectedDirections, "Port cannot receive");
	}

	public Collection<ValidationResultMessage> negatedReceives(NegatedDeterministicOccurrence negatedInteraction) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		DeterministicOccurrence interaction = negatedInteraction.getDeterministicOccurrence();
		if (interaction instanceof Interaction) {
			Interaction signal = (Interaction) interaction;
			if (signal.getDirection().equals(InteractionDirection.RECEIVE)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
					"Currently negated interactions received by the component are not processed",
						new ReferenceInfo(ScenarioModelPackage.Literals.NEGATED_DETERMINISTIC_OCCURRENCE__DETERMINISTIC_OCCURRENCE)));
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkParallelCombinedFragmentExists(ParallelCombinedFragment fragment) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		int idx = ecoreUtil.getIndex(fragment);
		validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
				"Beware that a parallel combined fragment will introduce every possible partial orderings of its fragments;"
						+ " it may have a significant impact on the performance",
				new ReferenceInfo(fragment.eContainingFeature(), idx, fragment.eContainer())));
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkIntervals(LoopCombinedFragment loop) {
		return checkInterval(loop.getMinimum(), loop.getMaximum(),
				ScenarioModelPackage.Literals.LOOP_COMBINED_FRAGMENT__MINIMUM,
				ScenarioModelPackage.Literals.LOOP_COMBINED_FRAGMENT__MAXIMUM);
	}

	public Collection<ValidationResultMessage> checkIntervals(Delay delay) {
		return checkInterval(delay.getMinimum(), delay.getMaximum(), ScenarioModelPackage.Literals.DELAY__MINIMUM,
				ScenarioModelPackage.Literals.DELAY__MAXIMUM);
	}

	private Collection<ValidationResultMessage> checkInterval(Expression minimum, Expression maximum,
			EStructuralFeature minimumFeature, EStructuralFeature maximumFeature) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();

		try {
			int min = expressionEvaluator.evaluateInteger(minimum);
			if (min < 0) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The minimum value must be greater than or equals to 0", new ReferenceInfo(minimumFeature)));
			}
			if (maximum != null) {
				int max = expressionEvaluator.evaluateInteger(maximum);
				if (min > max) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The minimum value must not be greater than the maximum value",
							new ReferenceInfo(minimumFeature)));
				}
			}
		} catch (IllegalArgumentException e) {
			// empty on purpouse
		}

		Type minType = typeDeterminator.getType(minimum);
		if (!(minType instanceof IntegerTypeDefinition)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The minimum value must be of type integer", new ReferenceInfo(minimumFeature)));
		}
		if (maximum != null) {
			Type maxType = typeDeterminator.getType(maximum);
			if (!(maxType instanceof IntegerTypeDefinition)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The maximum value must be of type integer", new ReferenceInfo(maximumFeature)));
			}
		}
		return validationResultMessages;
	}

	private Collection<ValidationResultMessage> checkEventDirections(Interaction signal,
			Map<RealizationMode, EventDirection> directionByMode, String prefix) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Port port = signal.getPort();
		InteractionDirection direction = signal.getDirection();
		InterfaceRealization interfaceRealization = port.getInterfaceRealization();
		RealizationMode portRealizationMode = interfaceRealization.getRealizationMode();
		Interface signalInterface = interfaceRealization.getInterface();
		Event signalEvent = signal.getEvent();
		
		if (StatechartModelDerivedFeatures.isInternal(signalEvent)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
				"Internal events are currently supported only for component-linked behavior equivalence checking",
					new ReferenceInfo(ScenarioModelPackage.Literals.INTERACTION__EVENT)));
			
			ScenarioDeclaration scenario = ecoreUtil.getContainerOfType(signal, ScenarioDeclaration.class);
			List<Interaction> signals = ecoreUtil.getAllContentsOfType(scenario, Interaction.class);
			for (Interaction otherSignal : signals) {
				Port otherPort = otherSignal.getPort();
				InteractionDirection otherDirection = otherSignal.getDirection();
				if (otherPort == port && direction != otherDirection) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"A certain internal port must be used in a single direction in every interaction",
							new ReferenceInfo(ScenarioModelPackage.Literals.INTERACTION__EVENT)));
				}
			}
			
			return validationResultMessages;
		}

		List<EventDeclaration> interfaceEventDeclarations = StatechartModelDerivedFeatures
				.getAllEventDeclarations(signalInterface);
		List<EventDeclaration> signalEventDeclarations = interfaceEventDeclarations.stream()
				.filter((it) -> it.getEvent().equals(signalEvent))
				.collect(Collectors.toList());

		EventDirection expectedDirection = directionByMode.get(portRealizationMode);

		List<EventDirection> expectedDirections = new ArrayList<EventDirection>();
		expectedDirections.add(expectedDirection);
		expectedDirections.add(EventDirection.INOUT);
		
		boolean isDirectionWrong = signalEventDeclarations.stream()
				.anyMatch((it) -> expectedDirections.contains(it.getDirection()));
		if (!isDirectionWrong) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, prefix
					+ " this event, because of incompatible port mode; should the port be Provided, set the event to be "
					+ directionByMode.get(RealizationMode.PROVIDED)
					+ "; should the port be Required, set the event to be "
					+ directionByMode.get(RealizationMode.REQUIRED),
					new ReferenceInfo(ScenarioModelPackage.Literals.INTERACTION__EVENT)));
		}
		
		return validationResultMessages;
	}

	private ModalityType getFirstInteractionsModality(List<Occurrence> interactions) {
		Occurrence first = interactions.get(0);
		if (first instanceof Interaction) {
			Interaction modalInteraction = (Interaction) first;
			return modalInteraction.getModality();
		} else if (first instanceof CombinedFragment) {
			CombinedFragment combinedFragment = (CombinedFragment) first;
			List<Occurrence> interactionsOfFirstFragment = combinedFragment.getFragments().get(0).getInteractions();
			return getFirstInteractionsModality(interactionsOfFirstFragment);
		} else if (first instanceof DeterministicOccurrenceSet) {
			DeterministicOccurrenceSet deterministicOccurrenceSet = (DeterministicOccurrenceSet) first;
			if (deterministicOccurrenceSet.getDeterministicOccurrences().size() > 0) {
				DeterministicOccurrence def = deterministicOccurrenceSet.getDeterministicOccurrences().get(0);
				if (def instanceof Interaction) {
					Interaction interaction = (Interaction) def;
					return interaction.getModality();
				} else if (def instanceof NegatedDeterministicOccurrence) {
					NegatedDeterministicOccurrence negatedDeterministicOccurrence = (NegatedDeterministicOccurrence) def;
					DeterministicOccurrence deterministicOccurrence = negatedDeterministicOccurrence.getDeterministicOccurrence();
					if (deterministicOccurrence instanceof Interaction) {
						Interaction modalInteraction = (Interaction) deterministicOccurrence;
						return modalInteraction.getModality();
					}
				}
			}
		}
		return ModalityType.COLD;
	}

	private boolean interactionIsCold(Occurrence interaction) {
		if (interaction instanceof Delay) {
			return true;
		} else if (interaction instanceof DeterministicOccurrenceSet) {
			DeterministicOccurrenceSet deterministicOccurrenceSet = (DeterministicOccurrenceSet) interaction;
			return deterministicOccurrenceSet.getDeterministicOccurrences().stream().allMatch((i) -> interactionIsCold(i));
		} else if (interaction instanceof Interaction) {
			Interaction modalInteraction = (Interaction) interaction;
			return modalInteraction.getModality().equals(ModalityType.COLD);
		} else if (interaction instanceof CombinedFragment) {
			CombinedFragment combinedFragment = (CombinedFragment) interaction;
			return combinedFragment.getFragments().stream()
					.allMatch((fragment) -> fragment.getInteractions().stream().allMatch((i) -> interactionIsCold(i)));
		}
		return false;
	}

	public Collection<ValidationResultMessage> checkScenarioReferenceParamCount(ScenarioDefinitionReference reference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (reference.getArguments().size() != reference.getScenarioDefinition().getParameterDeclarations().size()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Scenario " + reference.getScenarioDefinition().getName() + " takes "
							+ reference.getScenarioDefinition().getParameterDeclarations().size() + " parameters, but "
							+ reference.getArguments().size() + " arguments are provided",
					new ReferenceInfo(
							ScenarioModelPackage.Literals.SCENARIO_DEFINITION_REFERENCE__SCENARIO_DEFINITION)));
		}
		validationResultMessages
				.addAll(checkArgumentTypes(reference, reference.getScenarioDefinition().getParameterDeclarations()));
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkScenarioCheck(ScenarioCheckExpression check) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<EventParameterReferenceExpression> parameterReferences = ecoreUtil.getAllContentsOfType(check.getExpression(),
				EventParameterReferenceExpression.class);
		if (!parameterReferences.isEmpty()) {
			EObject container = check.eContainer();
			if (container instanceof DeterministicOccurrenceSet) {
				DeterministicOccurrenceSet set = (DeterministicOccurrenceSet) container;
				List<Interaction> signals = set.getDeterministicOccurrences().stream().filter(it -> it instanceof Interaction)
						.map(it -> (Interaction) it).collect(Collectors.toList());
				for (EventParameterReferenceExpression parameterReference : parameterReferences) {
					Event event = parameterReference.getEvent();
					Persistency eventPersistency = event.getPersistency();
					if (eventPersistency == Persistency.TRANSIENT) {
						Port port = parameterReference.getPort();
						boolean isPresentInBlock = false;
						for (Interaction signal : signals) {
							if (signal.getPort().equals(port) && signal.getEvent().equals(event)) {
								isPresentInBlock = true;
							}
						}
						if (!isPresentInBlock) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
								"This synchronous block does not contain any signal for the port and event of "
										+ parameterReference.getParameter().getName(),
									new ReferenceInfo(parameterReference.eContainingFeature(), parameterReference.eContainer())));
						}
					}
				}
			} else if (container instanceof Fragment) {
				Fragment fragment = (Fragment) container;
				int indexOfCheck = fragment.getInteractions().indexOf(check);
				Occurrence previousInteraction = findPreviousNonScenarioCheck(fragment, indexOfCheck);
				if (!(previousInteraction instanceof Interaction)) {
					for (EventParameterReferenceExpression parameterReference : parameterReferences) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The previous interaction is not a signal",
								new ReferenceInfo(parameterReference.eContainingFeature(), parameterReference.eContainer())));
					}
				} else {
					Interaction signal = (Interaction) previousInteraction;
					for (EventParameterReferenceExpression paramReference : parameterReferences) {
						Event event = paramReference.getEvent();
						Port port = paramReference.getPort();
						if (!signal.getPort().equals(port) || !signal.getEvent().equals(event)) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
								"The previous interaction is not a signal for the port and event of "
										+ paramReference.getParameter().getName(),
									new ReferenceInfo(paramReference.eContainingFeature(), paramReference.eContainer())));
						}
					}
				}
			}
		}
		validationResultMessages.addAll(checkTypeAndExpressionConformance(
				expressionFactory.createBooleanTypeDefinition(), check.getExpression(),
				new ReferenceInfo(ScenarioModelPackage.Literals.SCENARIO_CHECK_EXPRESSION__EXPRESSION)));
		return validationResultMessages;
	}

	private Occurrence findPreviousNonScenarioCheck(Fragment fragment, int indexOfCheck) {
		if (indexOfCheck == 0) {
			return null;
		}
		Occurrence previousInteraction = fragment.getInteractions().get(indexOfCheck - 1);
		if (previousInteraction instanceof ScenarioCheckExpression) {
			return findPreviousNonScenarioCheck(fragment, indexOfCheck - 1);
		}
		return previousInteraction;
	}

	public Collection<ValidationResultMessage> checkRecursiveScenraioReference(ScenarioDefinitionReference reference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (isScenarioReferenceRecursive(reference, reference.getScenarioDefinition())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Scenario " + reference.getScenarioDefinition().getName() + " is called recursively",
					new ReferenceInfo(
							ScenarioModelPackage.Literals.SCENARIO_DEFINITION_REFERENCE__SCENARIO_DEFINITION)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkScenraioReferenceInitialBlock(
			ScenarioDefinitionReference reference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (reference.getScenarioDefinition().getInitialBlock() != null) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
					"The initial block of scenario " + reference.getScenarioDefinition().getName()
							+ " will not be included in this scenario",
					new ReferenceInfo(
							ScenarioModelPackage.Literals.SCENARIO_DEFINITION_REFERENCE__SCENARIO_DEFINITION)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkScenraioBlockOrder(DeterministicOccurrenceSet set) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<ScenarioCheckExpression> checks = javaUtil.filterIntoList(set.getDeterministicOccurrences(),
				ScenarioCheckExpression.class);
		List<ScenarioAssignmentStatement> assignments = javaUtil.filterIntoList(set.getDeterministicOccurrences(),
				ScenarioAssignmentStatement.class);

		for (ScenarioCheckExpression check : checks) {
			for (ScenarioAssignmentStatement assignment : assignments) {
				int assingmentIdx = set.getDeterministicOccurrences().indexOf(assignment);
				int checkIdx = set.getDeterministicOccurrences().indexOf(check);
				if (checkIdx > assingmentIdx) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
							"The assignment will only be evaluated after the check",
							new ReferenceInfo(assignment.eContainingFeature(), assingmentIdx, set)));
				}
			}
		}
		return validationResultMessages;
	}

	private boolean isScenarioReferenceRecursive(ScenarioDefinitionReference reference, ScenarioDeclaration base) {
		List<ScenarioDefinitionReference> references = ecoreUtil.getAllContentsOfType(
				reference.getScenarioDefinition(), ScenarioDefinitionReference.class);
		for (ScenarioDefinitionReference innerReference : references) {
			if (innerReference.getScenarioDefinition().equals(base)) {
				return true;
			}
		}
		for (ScenarioDefinitionReference innerReference : references) {
			boolean isInnerWrong = isScenarioReferenceRecursive(innerReference, base);
			if (isInnerWrong) {
				return true;
			}
		}
		return false;
	}

	public Collection<ValidationResultMessage> checkAlternativeWithCheckInteraction(
			AlternativeCombinedFragment alternative) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<Fragment> fragments = new ArrayList<>();
		for (Fragment fragment : alternative.getFragments()) {
			Occurrence head = fragment.getInteractions().get(0);
			if (head instanceof DeterministicOccurrenceSet) {
				DeterministicOccurrenceSet set = (DeterministicOccurrenceSet) head;
				List<ScenarioCheckExpression> checks = javaUtil.filterIntoList(set.getDeterministicOccurrences(),
						ScenarioCheckExpression.class);
				if (checks.size() > 0) {
					fragments.add(fragment);
				}
			} else if (head instanceof ScenarioCheckExpression) {
				fragments.add(fragment);
			}
		}

		if (fragments.size() > 1) {
			for (Fragment fragment : fragments) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
						"Please ensure, that the checks of these interactions do not overlap",
						new ReferenceInfo(fragment.eContainingFeature(), alternative.getFragments().indexOf(fragment),
								fragment.eContainer())));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkDelayAndNegateInSameBlock(DeterministicOccurrenceSet set) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<DeterministicOccurrence> interactions = set.getDeterministicOccurrences();
		List<Interaction> signals = javaUtil.filterIntoList(interactions, Interaction.class);
		List<Delay> delays = javaUtil.filterIntoList(interactions, Delay.class);
		List<NegatedDeterministicOccurrence> negateds = javaUtil.filterIntoList(interactions, NegatedDeterministicOccurrence.class);
		if (signals.size() > 0 || delays.size() == 0 || negateds.size() == 0) {
			return validationResultMessages;
		}
		validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
				"The use of a negated signal and a delay without a signal may lead to the desynchronization of the monitor system",
				new ReferenceInfo(set.eContainingFeature(), ecoreUtil.getIndex(set),
					set.eContainer())));
		return validationResultMessages;
	}
}