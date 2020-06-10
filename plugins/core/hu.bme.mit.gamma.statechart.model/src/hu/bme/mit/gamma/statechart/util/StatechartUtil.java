package hu.bme.mit.gamma.statechart.util;

import org.eclipse.emf.common.util.EList;

import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.statechart.model.Port;
import hu.bme.mit.gamma.statechart.model.TimeSpecification;
import hu.bme.mit.gamma.statechart.model.TimeUnit;
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.model.composite.Component;
import hu.bme.mit.gamma.statechart.model.composite.CompositeFactory;
import hu.bme.mit.gamma.statechart.model.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.model.composite.PortBinding;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance;

public class StatechartUtil extends ExpressionUtil {

	private static StatechartUtil instance = null;
	
	public static StatechartUtil getInstance() {
		if (instance == null) {
			instance = new StatechartUtil();
		}
		return instance;
	}
	
	protected StatechartUtil() {}
	
	// Singleton
	
	protected CompositeFactory compositeFactory = CompositeFactory.eINSTANCE;
	
	public int evaluateMilliseconds(TimeSpecification time) {
		int value = evaluator.evaluateInteger(time.getValue());
		TimeUnit unit = time.getUnit();
		switch (unit) {
		case MILLISECOND:
			return value;
		case SECOND:
			return value * 1000;
		default:
			throw new IllegalArgumentException("Not known unit: " + unit);
		}
	}
	
	public CascadeCompositeComponent wrapSynchronousComponent(SynchronousComponent component) {
		CascadeCompositeComponent cascade = compositeFactory.createCascadeCompositeComponent();
		cascade.setName(component.getName()); // Trick: same name, so reflective api will work
		SynchronousComponentInstance instance = compositeFactory.createSynchronousComponentInstance();
		instance.setName(getWrapperInstanceName(component));
		instance.setType(component);
		for (ParameterDeclaration parameterDeclaration : component.getParameterDeclarations()) {
			ParameterDeclaration newParameter = ecoreUtil.clone(parameterDeclaration, true, true);
			cascade.getParameterDeclarations().add(newParameter);
			ReferenceExpression reference = factory.createReferenceExpression();
			reference.setDeclaration(newParameter);
			instance.getArguments().add(reference);
		}
		cascade.getComponents().add(instance);
		EList<Port> ports = component.getPorts();
		for (int i = 0; i < ports.size(); ++i) {
			Port port = ports.get(i);
			Port clonedPort = ecoreUtil.clone(port, true, true);
			cascade.getPorts().add(clonedPort);
			PortBinding portBinding = compositeFactory.createPortBinding();
			portBinding.setCompositeSystemPort(clonedPort);
			InstancePortReference instancePortReference = compositeFactory.createInstancePortReference();
			instancePortReference.setInstance(instance);
			instancePortReference.setPort(port);
			portBinding.setInstancePortReference(instancePortReference);
			cascade.getPortBindings().add(portBinding);
		}
		return cascade;
	}
	
	public String getWrapperInstanceName(Component component) {
		String name = component.getName();
		// The same as in Namings.getComponentClassName
		return Character.toUpperCase(name.charAt(0)) + name.substring(1);
	}
	
}
