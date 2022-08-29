package hu.bme.mit.gamma.activity.derivedfeatures;

import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.activity.model.ActivityNode;
import hu.bme.mit.gamma.activity.model.CompositeNode;
import hu.bme.mit.gamma.activity.model.ControlFlow;
import hu.bme.mit.gamma.activity.model.DataFlow;
import hu.bme.mit.gamma.activity.model.DataSourceReference;
import hu.bme.mit.gamma.activity.model.DataTargetReference;
import hu.bme.mit.gamma.activity.model.Flow;
import hu.bme.mit.gamma.activity.model.InputPinReference;
import hu.bme.mit.gamma.activity.model.OutputPinReference;
import hu.bme.mit.gamma.activity.model.OutsidePinReference;
import hu.bme.mit.gamma.activity.model.Pin;
import hu.bme.mit.gamma.activity.model.PinReference;
import hu.bme.mit.gamma.activity.model.PinnedNode;

public class ActivityModelDerivedFeatures extends ActionModelDerivedFeatures {

	public static ActivityNode getSourceNode(Flow flow) {
		if (flow instanceof DataFlow) {
			DataFlow dataFlow = (DataFlow) flow;
			
			if (dataFlow.getDataSourceReference() instanceof PinReference) {
				PinReference pinReference = (PinReference) dataFlow.getDataSourceReference();
				Pin pin = getPin(pinReference);
				
				return getContainingPinnedNode(pin);
			}
		}
			
		if (flow instanceof ControlFlow) {
			ControlFlow controlFlow = (ControlFlow) flow;
			
			return controlFlow.getSourceNode();
		}		
		
		throw new IllegalStateException("Flow's source is not a known type.");
	}

	public static Pin getSourcePin(DataFlow flow) {
		if (flow.getDataSourceReference() instanceof PinReference) {
			PinReference pinReference = (PinReference) flow.getDataSourceReference();
			Pin pin = getPin(pinReference);
			
			return pin;
		}
		
		throw new IllegalStateException("Data flow's source is not a known type.");
	}

	public static ActivityNode getTargetNode(Flow flow) {
		if (flow instanceof DataFlow) {
			DataFlow dataFlow = (DataFlow) flow;
			
			if (dataFlow.getDataTargetReference() instanceof PinReference) {
				PinReference pinReference = (PinReference) dataFlow.getDataTargetReference();
				Pin pin = getPin(pinReference);
				
				return getContainingPinnedNode(pin);
			}
		}
			
		if (flow instanceof ControlFlow) {
			ControlFlow controlFlow = (ControlFlow) flow;
			
			return controlFlow.getTargetNode();
		}
		
		throw new IllegalStateException("Flow's target is not of a known type.");
	}

	public static Pin getTargetPin(DataFlow flow) {
		if (flow.getDataTargetReference() instanceof PinReference) {
			PinReference pinReference = (PinReference) flow.getDataTargetReference();
			Pin pin = getPin(pinReference);
			
			return pin;
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
	
	public static Pin getPin(DataSourceReference sourceReference) {
		if (sourceReference instanceof PinReference) {
			return getPin(sourceReference);
		}
		
		throw new IllegalStateException("Pin is not of a known type.");
	}
	
	public static Pin getPin(DataTargetReference targetReference) {
		if (targetReference instanceof PinReference) {
			return getPin(targetReference);
		}
		
		throw new IllegalStateException("Pin is not of a known type.");
	}

	public static PinnedNode getContainingPinnedNode(EObject context) {
		return ecoreUtil.getContainerOfType(context, PinnedNode.class);
	}

	public static CompositeNode getContainingCompositeNode(EObject context) {
		return ecoreUtil.getContainerOfType(context, CompositeNode.class);
	}
	
	public static List<Flow> getIncomingFlows(ActivityNode node) {
		CompositeNode parent = getContainingCompositeNode(node);
		return parent.getFlows().stream().filter(it -> getTargetNode(it) == node)
				.collect(Collectors.toList());
	}
	
	public static List<Flow> getOutgoingFlows(ActivityNode node) {
		CompositeNode parent = getContainingCompositeNode(node);
		return parent.getFlows().stream().filter(it -> getSourceNode(it) == node)
				.collect(Collectors.toList());
	}
	
	public static CompositeNode getReferencedCompositeNode(OutsidePinReference reference) {
		PinnedNode node = reference.getActionNode();
		
		if (node instanceof CompositeNode) {
			return (CompositeNode) node;
		}
		
		throw new IllegalStateException("Referenced node is not a CompositeNode.");
	}
	
}
