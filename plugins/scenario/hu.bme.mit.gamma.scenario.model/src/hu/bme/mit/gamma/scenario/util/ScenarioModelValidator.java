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
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;
import hu.bme.mit.gamma.scenario.model.Annotation;
import hu.bme.mit.gamma.scenario.model.CombinedFragment;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.InteractionDirection;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment;
import hu.bme.mit.gamma.scenario.model.ModalInteraction;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.ModalityType;
import hu.bme.mit.gamma.scenario.model.NegPermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.NegStrictAnnotation;
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction;
import hu.bme.mit.gamma.scenario.model.ParallelCombinedFragment;
import hu.bme.mit.gamma.scenario.model.PermissiveAnnotation;
import hu.bme.mit.gamma.scenario.model.Reset;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition;
import hu.bme.mit.gamma.scenario.model.ScenarioModelPackage;
import hu.bme.mit.gamma.scenario.model.Signal;
import hu.bme.mit.gamma.scenario.model.StrictAnnotation;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;

public class ScenarioModelValidator extends ExpressionModelValidator {
	// Singleton
	public static final ScenarioModelValidator INSTANCE = new ScenarioModelValidator();
	protected ScenarioModelValidator() {}
	//

	public Collection<ValidationResultMessage> checkIncompatibleAnnotations(ScenarioDefinition scenario) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		boolean strictPresent = false;
		boolean permissivePresent = false;
		boolean negstrictPresent = false;
		boolean negpermissivePresent = false;
		for (Annotation annotation : scenario.getAnnotation()) {
			if (annotation instanceof StrictAnnotation) {
				strictPresent = true;
			}
			else if (annotation instanceof PermissiveAnnotation) {
				permissivePresent = true;
			}
			else if (annotation instanceof NegStrictAnnotation) {
				negstrictPresent = true;
			}
			else if (annotation instanceof NegPermissiveAnnotation) {
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
				"A scenario should be annotated with either a permissive or strict annotation with respect to negated sends blocks",
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkScenarioNamesAreUnique(ScenarioDeclaration scenarioDeclaration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		for (ScenarioDefinition scen : scenarioDeclaration.getScenarios()) {
			int i = 0;
			for (ScenarioDefinition sd : scenarioDeclaration.getScenarios()) {
				if (scen.getName().equals(sd.getName())) {
					i++;
				}
			}
			if (i > 1) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Scenario names should be unique",
						new ReferenceInfo(ScenarioModelPackage.Literals.SCENARIO_DECLARATION__SCENARIOS)));
				return validationResultMessages;
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkAtLeastOneHotSignalInChart(ScenarioDefinition scenario) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		boolean allCold = scenario.getChart().getFragment().getInteractions().stream()
				.allMatch((i) ->  interactionIsCold(i));
		if (allCold) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
					"There should be at least one hot signal in chart",
					new ReferenceInfo(ScenarioModelPackage.Literals.SCENARIO_DEFINITION__CHART)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkModalInteractionSets(ModalInteractionSet modalInteractionSet) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ScenarioDeclaration scenario = ecoreUtil.getContainerOfType(modalInteractionSet, ScenarioDeclaration.class);
		Component component = scenario.getComponent();
		int idx = ecoreUtil.getIndex(modalInteractionSet);
		EObject eContainer = modalInteractionSet.eContainer();
		if (component instanceof SynchronousComponent) {
			List<ModalInteractionSet> sets = ecoreUtil.getAllContentsOfType(modalInteractionSet, ModalInteractionSet.class);
			if (!sets.isEmpty()) {
				// Just to make sure, in the current grammar this is impossible
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Modal interaction sets cannot contain modal interaction sets",
						new ReferenceInfo(modalInteractionSet.eContainingFeature(), idx, eContainer)));
			}
		}
		else {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Scenarios with respect to asynchronous components cannot contain modal interaction sets",
					new ReferenceInfo(modalInteractionSet.eContainingFeature(), idx, eContainer)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkModalInteractionsInSynchronousComponents(
			ModalInteraction interaction) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ScenarioDeclaration scenario = ecoreUtil.getContainerOfType(interaction, ScenarioDeclaration.class);
		Component component = scenario.getComponent();
		if (component instanceof SynchronousComponent) {
			if (interaction instanceof ModalInteractionSet || interaction instanceof Reset
					|| interaction instanceof Delay) {
				// Delays and resets may not be contained by modal interaction sets
				return validationResultMessages;
			} else {
				EObject eContainer = interaction.eContainer();
				if (!(eContainer instanceof ModalInteractionSet)
						&& !(eContainer instanceof NegatedModalInteraction
								&& eContainer.eContainer() instanceof ModalInteractionSet)) {
					int idx = 0;
					if (eContainer instanceof InteractionFragment) {
						InteractionFragment set = (InteractionFragment) eContainer;
						idx = set.getInteractions().indexOf(interaction);
					}

					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"Modal interactions in scenarios with respect to synchronous components must be contained by modal interaction sets",
							new ReferenceInfo(interaction.eContainingFeature(), idx, eContainer)));
				}
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkModalInteractionsInSynchronousComponents(Reset reset) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EObject eContainer = reset.eContainer();
		int idx = ecoreUtil.getIndex(eContainer);
		if (eContainer instanceof ModalInteractionSet) {
			if (idx != 0) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Resets must be specified as the first element in a containing set", new ReferenceInfo(
								eContainer.eContainingFeature(), idx, eContainer.eContainer())));
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
			for (InteractionFragment fragment : combinedFragment.getFragments()) {
				ModalityType tmpModality = getFirstInteractionsModality(fragment.getInteractions());
				if (!tmpModality.equals(firstModality)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"First interaction's modality should be the same in each fragment belonging to the same combined fragment",
							new ReferenceInfo(ScenarioModelPackage.Literals.COMBINED_FRAGMENT__FRAGMENTS)));
					return validationResultMessages;
				}
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkPortCanSendSignal(Signal signal) {
		if (signal.getDirection() != InteractionDirection.SEND) {
			return new ArrayList<ValidationResultMessage>();
		}
		// PROVIDED -> IN is IN, OUT is OUT; REQUIRED -> IN is OUT, OUT is IN
		Map<RealizationMode, EventDirection> expectedDirections = new HashMap<>();
		expectedDirections.put(RealizationMode.PROVIDED, EventDirection.OUT);
		expectedDirections.put(RealizationMode.REQUIRED, EventDirection.IN);
		return checkEventDirections(signal, expectedDirections, "Port cannot send");
	}

	public Collection<ValidationResultMessage> checkPortCanReceiveSignal(Signal signal) {
		if (signal.getDirection() != InteractionDirection.RECEIVE) {
			return new ArrayList<ValidationResultMessage>();
		}
		// PROVIDED -> IN is IN, OUT is OUT; REQUIRED -> IN is OUT, OUT is IN
		Map<RealizationMode, EventDirection> expectedDirections = new HashMap<>();
		expectedDirections.put(RealizationMode.PROVIDED, EventDirection.IN);
		expectedDirections.put(RealizationMode.REQUIRED, EventDirection.OUT);
		return checkEventDirections(signal, expectedDirections, "Port cannot receive");
	}

	public Collection<ValidationResultMessage> negatedReceives(NegatedModalInteraction nmi) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		InteractionDefinition mi = nmi.getModalinteraction();
		if (mi instanceof Signal) {
			Signal signal = (Signal) mi;
			if (signal.getDirection().equals(InteractionDirection.RECEIVE)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
						"Currently negated interactions received by the component are not processed",
						new ReferenceInfo(ScenarioModelPackage.Literals.NEGATED_MODAL_INTERACTION__MODALINTERACTION)));
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
				new ReferenceInfo(fragment.eContainingFeature(), idx,fragment.eContainer()))); 
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkIntervals(LoopCombinedFragment loop) {
		return checkInterval(loop.getMinimum(), loop.getMaximum(),
				ScenarioModelPackage.Literals.LOOP_COMBINED_FRAGMENT__MINIMUM);
	}

	public Collection<ValidationResultMessage> checkIntervals(Delay delay) {
		return checkInterval(delay.getMinimum(), delay.getMaximum(),
				ScenarioModelPackage.Literals.DELAY__MINIMUM);
	}

	private Collection<ValidationResultMessage> checkInterval(Expression minimum, Expression maximum,
			EStructuralFeature feature) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			int min = expressionEvaluator.evaluateInteger(minimum);
			if (min < 0) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The minimum value must be greater than or equals to 0", new ReferenceInfo(feature)));
			}
			if (maximum != null) {
				int max = expressionEvaluator.evaluateInteger(maximum);
				if (min > max) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The minimum value must not be greater than the maximum value",
							new ReferenceInfo(feature)));
				}
			}
		} catch (IllegalArgumentException e) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Both the minimum and maximum values must be of type integer", new ReferenceInfo(feature)));
		}
		return validationResultMessages;
	}

	private Collection<ValidationResultMessage> checkEventDirections(Signal signal,
			Map<RealizationMode, EventDirection> directionByMode, String prefix) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		RealizationMode portRealizationMode = signal.getPort().getInterfaceRealization().getRealizationMode();
		Interface signalInterface = signal.getPort().getInterfaceRealization().getInterface();
		Event signalEvent = signal.getEvent();

		List<EventDeclaration> interfaceEventDeclarations = StatechartModelDerivedFeatures
				.getAllEventDeclarations(signalInterface);
		List<EventDeclaration> signalEventDeclarations = interfaceEventDeclarations.stream()
				.filter((it) -> it.getEvent().equals(signalEvent)).collect(Collectors.toList());

		EventDirection expectedDir = directionByMode.get(portRealizationMode);

		List<EventDirection> expectedDirections = new ArrayList<EventDirection>();
		expectedDirections.add(expectedDir);
		expectedDirections.add(EventDirection.INOUT);
		boolean eventDirIsWrong = signalEventDeclarations.stream()
				.anyMatch((it) -> expectedDirections.contains(it.getDirection()));
		if (!eventDirIsWrong) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, prefix
					+ " this event, because of incompatible port mode; should the port be Provided, set the event to be "
					+ directionByMode.get(RealizationMode.PROVIDED) + "; should the port be Required, set the event to be "
					+ directionByMode.get(RealizationMode.REQUIRED),
					new ReferenceInfo(ScenarioModelPackage.Literals.SIGNAL__EVENT)));
		}
		return validationResultMessages;
	}

	private ModalityType getFirstInteractionsModality(List<Interaction> interactions) {
		Interaction first = interactions.get(0);
		if (first instanceof ModalInteraction) {
			ModalInteraction modalInteraction = (ModalInteraction) first;
			return modalInteraction.getModality();
		}
		else if (first instanceof CombinedFragment) {
			CombinedFragment combinedFragment = (CombinedFragment) first;
			List<Interaction> interactionsOfFirstFragment = combinedFragment.getFragments()
					.get(0).getInteractions();
			return getFirstInteractionsModality(interactionsOfFirstFragment);
		}
		else if (first instanceof ModalInteractionSet) {
			ModalInteractionSet modalInteractionSet = (ModalInteractionSet) first;
			if (modalInteractionSet.getModalInteractions().size() > 0) {
				InteractionDefinition def = modalInteractionSet.getModalInteractions().get(0);
				if (def instanceof ModalInteraction) {
					ModalInteraction modalInteraction = (ModalInteraction) def;
					return modalInteraction.getModality();
				}
				else if (def instanceof NegatedModalInteraction) {
					NegatedModalInteraction negatedModalInteraction = (NegatedModalInteraction) def;
					InteractionDefinition interactionDefinition = negatedModalInteraction.getModalinteraction();
					if (interactionDefinition instanceof ModalInteraction) {
						ModalInteraction modalInteraction = (ModalInteraction) interactionDefinition;
						return modalInteraction.getModality();
					}
				}
			}
		}
		return ModalityType.COLD;
	}

	private boolean interactionIsCold(Interaction interaction) {
		if (interaction instanceof Delay || interaction instanceof Reset) {
			return true;
		}
		else if (interaction instanceof ModalInteractionSet) {
			ModalInteractionSet modalInteractionSet = (ModalInteractionSet) interaction;
			return modalInteractionSet.getModalInteractions().stream().allMatch((i) -> interactionIsCold(i));
		}
		else if (interaction instanceof ModalInteraction) {
			ModalInteraction modalInteraction = (ModalInteraction) interaction;
			return modalInteraction.getModality().equals(ModalityType.COLD);
		}
		else if (interaction instanceof CombinedFragment) {
			CombinedFragment combinedFragment = (CombinedFragment) interaction;
			return combinedFragment.getFragments().stream()
					.allMatch((fragment) -> fragment.getInteractions().stream()
							.allMatch((i) -> interactionIsCold(i)));
		}
		return false;
	}

}