package hu.bme.mit.gamma.trace.util;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.trace.model.Assert;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.NegatedAssert;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;
import hu.bme.mit.gamma.trace.model.TraceModelFactory;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class UnsentEventAssertExtender {

	protected ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE;
	protected StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	List<Step> steps = new ArrayList<>();
	List<Port> ports = new ArrayList<>();

	Component component = null;

	boolean allSteps = false;

	public UnsentEventAssertExtender(List<Step> steps, boolean allSteps) {
		this.steps = steps;
		this.allSteps = allSteps;
	}

	public UnsentEventAssertExtender(Step step) {
		this.steps.add(step);
	}

	public void execute() {

		ExecutionTrace trace =ecoreUtil.getContainerOfType(steps.get(0), ExecutionTrace.class);
		component= trace.getComponent();
		ports = component.getPorts();
		
		for (Step step : steps) {

			List<NegatedAssert> negatedAsserts = new ArrayList<>();
			for (Port p : ports) {
				for (Event e : StatechartModelDerivedFeatures.getOutputEvents(p)) {
					if (e.getParameterDeclarations().isEmpty()) {
						NegatedAssert neg = traceFactory.createNegatedAssert();
						RaiseEventAct raise = traceFactory.createRaiseEventAct();
						raise.setPort(p);
						raise.setEvent(e);
						neg.setNegatedAssert(raise);
						negatedAsserts.add(neg);
					}
				}
			}

			List<Assert> baseAsserts = step.getAsserts();

			for (Assert a : baseAsserts) {
				Set<Assert> removable = new HashSet<>();

				if (a instanceof RaiseEventAct) {
					RaiseEventAct raise = ((RaiseEventAct) a);
					Port aPort = raise.getPort();
					Event aEvent = raise.getEvent();
					for (NegatedAssert neg : negatedAsserts) {
						if (neg.getNegatedAssert() instanceof RaiseEventAct) {
							RaiseEventAct raiseEvent = (RaiseEventAct) neg.getNegatedAssert();
							if (raiseEvent.getPort().getName().equals(aPort.getName())
									&& raiseEvent.getEvent().getName().equals(aEvent.getName())) {
								removable.add(neg);
							}
						}
					}
				}
				negatedAsserts.removeAll(removable);
			}

			step.getAsserts().addAll(negatedAsserts);
		}

	}

}
