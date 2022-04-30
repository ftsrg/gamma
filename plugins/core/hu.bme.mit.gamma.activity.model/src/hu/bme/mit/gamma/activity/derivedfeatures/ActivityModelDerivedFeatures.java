package hu.bme.mit.gamma.activity.derivedfeatures;

import java.util.Collections;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.activity.model.ActionNode;
import hu.bme.mit.gamma.activity.model.ActivityDeclaration;
import hu.bme.mit.gamma.activity.model.ActivityDeclarationReference;
import hu.bme.mit.gamma.activity.model.ActivityDefinition;
import hu.bme.mit.gamma.activity.model.ActivityNode;
import hu.bme.mit.gamma.activity.model.DataContainer;
import hu.bme.mit.gamma.activity.model.DataFlow;
import hu.bme.mit.gamma.activity.model.DataNodeReference;
import hu.bme.mit.gamma.activity.model.Definition;
import hu.bme.mit.gamma.activity.model.InlineActivityDeclaration;
import hu.bme.mit.gamma.activity.model.InputPinReference;
import hu.bme.mit.gamma.activity.model.NamedActivityDeclarationReference;
import hu.bme.mit.gamma.activity.model.OutputPinReference;
import hu.bme.mit.gamma.activity.model.OutsidePinReference;
import hu.bme.mit.gamma.activity.model.Pin;
import hu.bme.mit.gamma.activity.model.PinReference;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;

public class ActivityModelDerivedFeatures extends ActionModelDerivedFeatures {

	public static ActivityDeclaration getContainingActivityDeclaration(EObject element) {
		if (element instanceof ActivityDeclaration) {
			return (ActivityDeclaration) element;
		}
		
		return getContainingActivityDeclaration(element.eContainer());
	}
	
	public static ActivityDefinition getContainingActivityDefinition(EObject element) {
		if (element instanceof ActivityDefinition) {
			return (ActivityDefinition) element;
		}
		
		return getContainingActivityDefinition(element.eContainer());
	}
	
	public static ActivityDeclaration getReferencedActivityDeclaration(OutsidePinReference reference) {
		ActivityDeclarationReference declReference = reference.getActionNode().getActivityDeclarationReference();

		if (declReference instanceof InlineActivityDeclaration) {
			return (InlineActivityDeclaration) declReference;
		}
		if (declReference instanceof NamedActivityDeclarationReference) {
			NamedActivityDeclarationReference activityDeclarationReference = (NamedActivityDeclarationReference) declReference;
			return activityDeclarationReference.getNamedActivityDeclaration();
		}
		
		return null;
	}
	
	public static List<VariableDeclaration> getTransitiveVariableDeclarations(ActivityDeclaration declaration) {
		if (declaration.getDefinition() instanceof ActivityDefinition) {
			ActivityDefinition activityDefinition = (ActivityDefinition) declaration.getDefinition();
			return activityDefinition.getVariableDeclarations();
		}
		
		return Collections.emptyList();
	}

	public static ActivityNode getSourceNode(DataFlow flow) {
		if (flow.getDataSourceReference() instanceof PinReference) {
			PinReference pinReference = (PinReference) flow.getDataSourceReference();
			Pin pin = getPin(pinReference);
			
			return ecoreUtil.getContainerOfType(pin, ActivityNode.class);
		}

		if (flow.getDataSourceReference() instanceof DataNodeReference) {
			DataNodeReference reference = (DataNodeReference) flow.getDataSourceReference();
			
			return reference.getDataNode();
		}
		
		throw new IllegalStateException("Data flow's source is not a known type.");
	}

	public static DataContainer getSourceDataContainer(DataFlow flow) {
		if (flow.getDataSourceReference() instanceof PinReference) {
			PinReference pinReference = (PinReference) flow.getDataSourceReference();
			Pin pin = getPin(pinReference);
			
			return pin;
		}

		if (flow.getDataSourceReference() instanceof DataNodeReference) {
			DataNodeReference reference = (DataNodeReference) flow.getDataSourceReference();
			
			return reference.getDataNode();
		}
		
		throw new IllegalStateException("Data flow's source is not a known type.");
	}

	public static ActivityNode getTargetNode(DataFlow flow) {
		if (flow.getDataTargetReference() instanceof PinReference) {
			PinReference pinReference = (PinReference) flow.getDataTargetReference();
			Pin pin = getPin(pinReference);
			
			return ecoreUtil.getContainerOfType(pin, ActivityNode.class);
		}

		if (flow.getDataTargetReference() instanceof DataNodeReference) {
			DataNodeReference reference = (DataNodeReference) flow.getDataTargetReference();
			
			return reference.getDataNode();
		}
		
		throw new IllegalStateException("Data flow's source is not of a known type.");
	}

	public static DataContainer getTargetDataContainer(DataFlow flow) {
		if (flow.getDataTargetReference() instanceof PinReference) {
			PinReference pinReference = (PinReference) flow.getDataTargetReference();
			Pin pin = getPin(pinReference);
			
			return pin;
		}

		if (flow.getDataTargetReference() instanceof DataNodeReference) {
			DataNodeReference reference = (DataNodeReference) flow.getDataTargetReference();
			
			return reference.getDataNode();
		}
		
		throw new IllegalStateException("Data flow's source is not of a known type.");
	}
	
	public static Pin getPin(PinReference pinReference) {
		if (pinReference instanceof InputPinReference) {
			InputPinReference reference = (InputPinReference) pinReference;
			return reference.getInputPin();
		}
		if (pinReference instanceof OutputPinReference) {
			OutputPinReference reference = (OutputPinReference) pinReference;
			return reference.getOutputPin();
		}
		
		throw new IllegalStateException("Pin is not of a known type.");
	}
	
	public static List<Pin> getPins(ActivityDeclarationReference reference) {
		if (reference instanceof NamedActivityDeclarationReference) {
			NamedActivityDeclarationReference activityDeclarationReference = (NamedActivityDeclarationReference) reference;
			return activityDeclarationReference.getNamedActivityDeclaration().getPins();
		}
		
		if (reference instanceof InlineActivityDeclaration) {
			InlineActivityDeclaration activityDeclarationReference = (InlineActivityDeclaration) reference;
			return activityDeclarationReference.getPins();
		}
		
		throw new IllegalStateException("ActivityDeclarationReference is not of a known type.");
	}
	
	public static Definition getDefinition(ActivityDeclarationReference reference) {
		if (reference instanceof NamedActivityDeclarationReference) {
			NamedActivityDeclarationReference activityDeclarationReference = (NamedActivityDeclarationReference) reference;
			return activityDeclarationReference.getNamedActivityDeclaration().getDefinition();
		}
		
		if (reference instanceof InlineActivityDeclaration) {
			InlineActivityDeclaration activityDeclarationReference = (InlineActivityDeclaration) reference;
			return activityDeclarationReference.getDefinition();
		}
		
		throw new IllegalStateException("ActivityDeclarationReference is not of a known type.");
	}
	
	public static ActivityDefinition getReferedActivityDefinition(ActionNode node) {
		Definition definition = getDefinition(node.getActivityDeclarationReference());

		if (definition instanceof ActivityDefinition) {
			return (ActivityDefinition) definition;
		}
		
		throw new IllegalStateException("ActionNode does not refer to an ActivityDefinition.");
	}
	
}
