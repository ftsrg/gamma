package hu.bme.mit.gamma.trace.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage;
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures;
import hu.bme.mit.gamma.trace.model.ComponentSchedule;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.InstanceSchedule;
import hu.bme.mit.gamma.trace.model.InstanceState;
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration;
import hu.bme.mit.gamma.trace.model.InstanceVariableState;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;
import hu.bme.mit.gamma.trace.model.TraceModelPackage;

public class TraceModelValidator extends ExpressionModelValidator {
	
	public static final TraceModelValidator INSTANCE = new TraceModelValidator();
	private TraceModelValidator() {}
	
	public Collection<ValidationResultMessage> checkArgumentTypes(ArgumentedElement element) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<ParameterDeclaration> parameters = TraceModelDerivedFeatures.getParameterDeclarations(element);
		validationResultMessages.addAll(super.checkArgumentTypes(element, parameters));
		return validationResultMessages;
	}
	
	
	public Collection<ValidationResultMessage> checkRaiseEventAct(RaiseEventAct raiseEventAct) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Step step = ecoreUtil.getContainerOfType(raiseEventAct, Step.class);
		RealizationMode realizationMode = raiseEventAct.getPort().getInterfaceRealization().getRealizationMode();
		Event event = raiseEventAct.getEvent();
		EventDirection eventDirection = ecoreUtil.getContainerOfType(event, EventDeclaration.class).getDirection();
		if (step.getActions().contains(raiseEventAct)) {
			// It should be an in event
			if (realizationMode == RealizationMode.PROVIDED && eventDirection == EventDirection.OUT ||
				realizationMode == RealizationMode.REQUIRED && eventDirection == EventDirection.IN) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This event is an out-event of the component.",
						new ReferenceInfo(StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT, null)));
			}			
		}
		else {
			// It should be an out event
			if (realizationMode == RealizationMode.PROVIDED && eventDirection == EventDirection.IN ||
				realizationMode == RealizationMode.REQUIRED && eventDirection == EventDirection.OUT) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This event is an in-event of the component.",
						new ReferenceInfo(StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT, null)));
			}			
		}
		return validationResultMessages;
	}
	
	
	public Collection<ValidationResultMessage> checkInstanceState(InstanceState instanceState) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		SynchronousComponentInstance instance = instanceState.getInstance();
		SynchronousComponent type = instance.getType();
		if (!(type instanceof StatechartDefinition)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This is not a statechart instance.",
					new ReferenceInfo(TraceModelPackage.Literals.INSTANCE_STATE__INSTANCE, null)));
		}
		return validationResultMessages;
	}
	
	protected <T extends EObject> List<T> getAllContentsOfType(EObject element, Class<T> classType){
		List<T> contents = new ArrayList<T>();
		TreeIterator<EObject> iterator = EcoreUtil.getAllContents(element, true);
		while (iterator.hasNext()) {
			EObject object = iterator.next();
			if (classType.isInstance(object)) {
				contents.add((T) object);
			}
		}
		return contents;
	}
	
	public Collection<ValidationResultMessage> checkInstanceStateConfiguration(InstanceStateConfiguration configuration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		SynchronousComponentInstance instance = configuration.getInstance();
		SynchronousComponent type = instance.getType();
		if (type instanceof StatechartDefinition) {
			State state = configuration.getState();
			List<State> states =  getAllContentsOfType(type, hu.bme.mit.gamma.statechart.statechart.State.class);
			if (!states.contains(state)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This is not a valid state in the specified statechart.",
						new ReferenceInfo(TraceModelPackage.Literals.INSTANCE_STATE_CONFIGURATION__STATE, null)));
			}
		}
		return validationResultMessages;
	}
	
	
	public Collection<ValidationResultMessage> checkInstanceVariableState(InstanceVariableState variableState) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		SynchronousComponentInstance instance = variableState.getInstance();
		SynchronousComponent type = instance.getType();
		if (type instanceof StatechartDefinition) {
			Declaration variable = variableState.getDeclaration();
			StatechartDefinition statechartDefinition = (StatechartDefinition)type;
			List<VariableDeclaration> variables = statechartDefinition.getVariableDeclarations();
			if (!variables.contains(variable)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This is not a valid variable in the specified statechart.",
						new ReferenceInfo(ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION, null)));
			}
		}
		return validationResultMessages;
	}
	
	
	public Collection<ValidationResultMessage> checkInstanceSchedule(InstanceSchedule schedule) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ExecutionTrace executionTrace = (ExecutionTrace)EcoreUtil.getRootContainer(schedule, true);
		Component component = executionTrace.getComponent();
		if (component != null) {
			if (!(component instanceof AsynchronousCompositeComponent)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Instance scheduling is valid only if the component is an asynchronous composite component.",
						new ReferenceInfo(TraceModelPackage.Literals.INSTANCE_SCHEDULE__SCHEDULED_INSTANCE, null)));
			}
		}
		return validationResultMessages;
	}
	
	
	public Collection<ValidationResultMessage> checkInstanceSchedule(ComponentSchedule schedule) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Step step = (Step)schedule.eContainer();
		ExecutionTrace executionTrace = (ExecutionTrace)EcoreUtil.getRootContainer(step, true);
		Component component = executionTrace.getComponent();
		if (component != null) {
			if (!(component instanceof SynchronousComponent || component instanceof AsynchronousAdapter)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Component scheduling is valid only if the component is a synchronous component or synchronous component wrapper.",
						new ReferenceInfo(TraceModelPackage.Literals.STEP__ACTIONS, step.getActions().indexOf(schedule), step)));
			}
		}
		return validationResultMessages;
	}
}
