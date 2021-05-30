package hu.bme.mit.gamma.scenario.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EStructuralFeature;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ReferenceInfo;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResult;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResultMessage;
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
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ScenarioModelValidator {

	private GammaEcoreUtil util = GammaEcoreUtil.INSTANCE;
	private ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE;

	public static final ScenarioModelValidator INSTANCE = new ScenarioModelValidator();

	protected ScenarioModelValidator() {
	}

	public Collection<ValidationResultMessage> checkIncompatibleAnnotations(ScenarioDefinition s) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		boolean strictPresent = false;
		boolean permissivePresent = false;
		boolean negstrictPresent = false;
		boolean negpermissivePresent = false;
		for (Annotation a : s.getAnnotation()) {
			if (a instanceof StrictAnnotation) {
				strictPresent = true;
			} else if (a instanceof PermissiveAnnotation) {
				permissivePresent = true;
			} else if (a instanceof NegStrictAnnotation) {
				negstrictPresent = true;
			} else if (a instanceof NegPermissiveAnnotation) {
				negpermissivePresent = true;
			}
		}
		if (permissivePresent && strictPresent) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"A scenario should be annotated with either a permissive or strict annotation.",
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME, null)));
		}
		if (negpermissivePresent && negstrictPresent) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"A scenario should be annotated with either a permissive or strict annotation with respect to negated sends blocks.",
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME, null)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkScenarioNamesAreUnique(ScenarioDeclaration s) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		for (ScenarioDefinition scen : s.getScenarios()) {
			int i = 0;
			for (ScenarioDefinition sd : s.getScenarios()) {
				if (scen.getName().equals(sd.getName())) {
					i++;
				}
			}
			if (i > 1) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Scenario names should be unique.",
						new ReferenceInfo(ScenarioModelPackage.Literals.SCENARIO_DECLARATION__SCENARIOS, null)));
				return validationResultMessages;
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkAtLeastOneHotSignalInChart(ScenarioDefinition s) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		boolean allCold = s.getChart().getFragment().getInteractions().stream().allMatch((i) ->  interactionIsCold(i));
		if (allCold) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
					"There should be at least one hot signal in chart.",
					new ReferenceInfo(ScenarioModelPackage.Literals.SCENARIO_DEFINITION__CHART, null)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkModalInteractionSets(ModalInteractionSet modalInteractionSet) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ScenarioDeclaration s = util.getContainerOfType(modalInteractionSet, ScenarioDeclaration.class);
		Component c = s.getComponent();
		int idx = util.getIndex(modalInteractionSet);
		if (c instanceof SynchronousComponent) {
			List<ModalInteractionSet> sets = util.getAllContentsOfType(modalInteractionSet, ModalInteractionSet.class);
			if (!sets.isEmpty()) {
				// Just to make sure, in the current grammar this is impossible
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Modal interaction sets cannot contain modal interaction sets.",
						new ReferenceInfo(modalInteractionSet.eContainingFeature(), idx,modalInteractionSet.eContainer())));
			}
		} else {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Scenarios with respect to asynchronous components cannot contain modal interaction sets.",
					new ReferenceInfo(modalInteractionSet.eContainingFeature(), idx,modalInteractionSet.eContainer())));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkModalInteractionsInSynchronousComponents(
			ModalInteraction interaction) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ScenarioDeclaration s = util.getContainerOfType(interaction, ScenarioDeclaration.class);
		Component c = s.getComponent();
		if (c instanceof SynchronousComponent) {
			if (interaction instanceof ModalInteractionSet || interaction instanceof Reset
					|| interaction instanceof Delay) {
				// Delays and resets may not be contained by modal interaction sets
				return validationResultMessages;
			} else if (!(interaction.eContainer() instanceof ModalInteractionSet)
					&& !(interaction.eContainer() instanceof NegatedModalInteraction
							&& interaction.eContainer().eContainer() instanceof ModalInteractionSet)) {
				int idx = 0;
				if (interaction.eContainer() instanceof InteractionFragment) {
					InteractionFragment set = (InteractionFragment) interaction.eContainer();
					idx = set.getInteractions().indexOf(interaction);
				}

				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Modal interactions in scenarios with respect to synchronous components must be contained by modal interaction sets.",
						new ReferenceInfo(interaction.eContainingFeature(), idx, interaction.eContainer())));
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkModalInteractionsInSynchronousComponents(Reset reset) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		int idx = util.getIndex(reset.eContainer());
		if (reset.eContainer() instanceof ModalInteractionSet) {
			if (idx != 0) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Resets must be specified as the first element in a containing set.", new ReferenceInfo(
								reset.eContainer().eContainingFeature(), idx, reset.eContainer().eContainer())));
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
							"First interaction's modality should be the same in each fragment belonging to the same combined fragment.",
							new ReferenceInfo(ScenarioModelPackage.Literals.COMBINED_FRAGMENT__FRAGMENTS, null)));
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
			if (((Signal) mi).getDirection().equals(InteractionDirection.RECEIVE)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
						"Currently negated interactions received by the component are not processed.",
						new ReferenceInfo(ScenarioModelPackage.Literals.NEGATED_MODAL_INTERACTION__MODALINTERACTION,
								null)));
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkParallelCombinedFragmentExists(ParallelCombinedFragment fragment) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		int idx = util.getIndex(fragment);
		validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
				"Beware that a parallel combined fragment will introduce every possible partial orderings of its fragments. It may have a significant impact on the performance.",
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
						"The minimum value must be greater than or equals to 0.", new ReferenceInfo(feature, null)));
			}
			if (maximum != null) {
				int max = expressionEvaluator.evaluateInteger(maximum);
				if (min > max) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The minimum value must not be greater than the maximum value.",
							new ReferenceInfo(feature, null)));
				}
			}
		} catch (IllegalArgumentException e) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Both the minimum and maximum values must be of type integer.", new ReferenceInfo(feature, null)));
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
					+ " this event, because of incompatible port mode. Should the port be Provided, set the event to be "
					+ directionByMode.get(RealizationMode.PROVIDED)
					+ ". Should the port be Required, set the event to be "
					+ directionByMode.get(RealizationMode.REQUIRED) + ".",
					new ReferenceInfo(ScenarioModelPackage.Literals.SIGNAL__EVENT, null)));
		}
		return validationResultMessages;
	}

	private ModalityType getFirstInteractionsModality(List<Interaction> interactions) {
		Interaction first = interactions.get(0);
		if (first instanceof ModalInteraction) {
			return ((ModalInteraction) first).getModality();
		} else if (first instanceof CombinedFragment) {
			return getFirstInteractionsModality(((CombinedFragment) first).getFragments().get(0).getInteractions());
		} else if (first instanceof ModalInteractionSet
				&& ((ModalInteractionSet) first).getModalInteractions().size() > 0) {
			InteractionDefinition def = ((ModalInteractionSet) first).getModalInteractions().get(0);
			if (def instanceof ModalInteraction) {
				return ((ModalInteraction) def).getModality();
			} else if (def instanceof NegatedModalInteraction
					&& ((NegatedModalInteraction) def).getModalinteraction() instanceof ModalInteraction) {
				return ((ModalInteraction) ((NegatedModalInteraction) def).getModalinteraction()).getModality();
			}
		}
		return ModalityType.COLD;
	}

	private boolean interactionIsCold(Interaction interaction) {
		if (interaction instanceof ModalInteractionSet) {
			return ((ModalInteractionSet) interaction).getModalInteractions().stream().allMatch((i) -> interactionIsCold(i));
		} else if (interaction instanceof Delay) {
			return true;
		} else if (interaction instanceof Reset) {
			return true;
		} else if (interaction instanceof ModalInteraction) {
			return ((ModalInteraction) interaction).getModality().equals(ModalityType.COLD);
		} else if (interaction instanceof CombinedFragment) {
			return ((CombinedFragment) interaction).getFragments().stream()
					.allMatch((fragment) -> fragment.getInteractions().stream().allMatch((i) -> interactionIsCold(i)));
		}
		return false;

	}

}
