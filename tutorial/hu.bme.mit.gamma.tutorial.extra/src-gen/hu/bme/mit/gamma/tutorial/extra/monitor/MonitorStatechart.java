package hu.bme.mit.gamma.tutorial.extra.monitor;

import java.util.Queue;
import java.util.List;
import java.util.LinkedList;

import hu.bme.mit.gamma.tutorial.extra.event.*;
import hu.bme.mit.gamma.tutorial.extra.interfaces.*;
// Yakindu listeners
import hu.bme.mit.gamma.tutorial.extra.monitor.IMonitorStatemachine.*;
import hu.bme.mit.gamma.tutorial.extra.monitor.MonitorStatemachine;
import hu.bme.mit.gamma.tutorial.extra.monitor.MonitorStatemachine.State;

public class MonitorStatechart implements MonitorStatechartInterface {
	// The wrapped Yakindu statemachine
	private MonitorStatemachine monitorStatemachine = new MonitorStatemachine();
	// Port instances
	private Monitor monitor = new Monitor();
	private LightInputs lightInputs = new LightInputs();
	// Indicates which queues are active in this cycle
	private boolean insertQueue = true;
	private boolean processQueue = false;
	// Event queues for the synchronization of statecharts
	private Queue<Event> eventQueue1 = new LinkedList<Event>();
	private Queue<Event> eventQueue2 = new LinkedList<Event>();
	
	public MonitorStatechart() {
		// Initializing and entering the wrapped statemachine
	}
	
	/** Resets the statemachine. Should be used only be the container (composite system) class. */
	@Override
	public void reset() {
		monitorStatemachine.init();
		monitorStatemachine.enter();
	}
	
	/** Changes the event queues of the component instance. Should be used only be the container (composite system) class. */
	public void changeEventQueues() {
		insertQueue = !insertQueue;
		processQueue = !processQueue;
	}
	
	/** Changes the event queues to which the events are put. Should be used only be a cascade container (composite system) class. */
	public void changeInsertQueue() {
	    insertQueue = !insertQueue;
	}
	
	/** Returns whether the eventQueue containing incoming messages is empty. Should be used only be the container (composite system) class. */
	public boolean isEventQueueEmpty() {
		return getInsertQueue().isEmpty();
	}
	
	/** Returns the event queue into which events should be put in the particular cycle. */
	private Queue<Event> getInsertQueue() {
		if (insertQueue) {
			return eventQueue1;
		}
		return eventQueue2;
	}
	
	/** Returns the event queue from which events should be inspected in the particular cycle. */
	private Queue<Event> getProcessQueue() {
		if (processQueue) {
			return eventQueue1;
		}
		return eventQueue2;
	}
	
	/** Changes event queues and initiating a cycle run. */
	@Override
	public void runCycle() {
		changeEventQueues();
		runComponent();
	}
	
	/** Changes the insert queue and initiates a run. */
	public void runAndRechangeInsertQueue() {
		// First the insert queue is changed back, so self-event sending can work
	    changeInsertQueue();
	    runComponent();
	}
	
	/** Initiates a cycle run without changing the event queues. It is needed if this component is contained (wrapped) by another component.
	Should be used only be the container (composite system) class. */
	public void runComponent() {
		Queue<Event> eventQueue = getProcessQueue();
		while (!eventQueue.isEmpty()) {
				Event event = eventQueue.remove();
				switch (event.getEvent()) {
					case "LightInputs.DisplayNone": 
						monitorStatemachine.getSCILightInputs().raiseDisplayNone();
					break;
					case "LightInputs.DisplayRed": 
						monitorStatemachine.getSCILightInputs().raiseDisplayRed();
					break;
					case "LightInputs.DisplayYellow": 
						monitorStatemachine.getSCILightInputs().raiseDisplayYellow();
					break;
					case "LightInputs.DisplayGreen": 
						monitorStatemachine.getSCILightInputs().raiseDisplayGreen();
					break;
					default:
						throw new IllegalArgumentException("No such event!");
				}
		}
		monitorStatemachine.runCycle();
	}    		
	
	// Inner classes representing Ports
	public class Monitor implements MonitorInterface.Provided {
		private List<MonitorInterface.Listener.Provided> registeredListeners = new LinkedList<MonitorInterface.Listener.Provided>();


		@Override
		public boolean isRaisedError() {
			return monitorStatemachine.getSCIMonitor().isRaisedError();
		}
		@Override
		public void registerListener(final MonitorInterface.Listener.Provided listener) {
			registeredListeners.add(listener);
			monitorStatemachine.getSCIMonitor().getListeners().add(new SCIMonitorListener() {
				@Override
				public void onErrorRaised() {
					listener.raiseError();
				}
			});
		}
		
		@Override
		public List<MonitorInterface.Listener.Provided> getRegisteredListeners() {
			return registeredListeners;
		}

	}
	
	@Override
	public Monitor getMonitor() {
		return monitor;
	}
	
	public class LightInputs implements LightCommandsInterface.Required {
		private List<LightCommandsInterface.Listener.Required> registeredListeners = new LinkedList<LightCommandsInterface.Listener.Required>();

		@Override
		public void raiseDisplayNone() {
			getInsertQueue().add(new Event("LightInputs.DisplayNone", null));
		}
		
		@Override
		public void raiseDisplayRed() {
			getInsertQueue().add(new Event("LightInputs.DisplayRed", null));
		}
		
		@Override
		public void raiseDisplayYellow() {
			getInsertQueue().add(new Event("LightInputs.DisplayYellow", null));
		}
		
		@Override
		public void raiseDisplayGreen() {
			getInsertQueue().add(new Event("LightInputs.DisplayGreen", null));
		}

		@Override
		public void registerListener(final LightCommandsInterface.Listener.Required listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<LightCommandsInterface.Listener.Required> getRegisteredListeners() {
			return registeredListeners;
		}

	}
	
	@Override
	public LightInputs getLightInputs() {
		return lightInputs;
	}
	
	
	
	/** Checks whether the wrapped statemachine is in the given state. */
	public boolean isStateActive(State state) {
		return monitorStatemachine.isStateActive(state);
	}
	
	
}
