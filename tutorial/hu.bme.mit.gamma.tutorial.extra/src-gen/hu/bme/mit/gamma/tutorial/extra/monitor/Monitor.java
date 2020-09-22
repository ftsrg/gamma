package hu.bme.mit.gamma.tutorial.extra.monitor;

import java.util.Queue;
import java.util.List;
import java.util.LinkedList;

import hu.bme.mit.gamma.tutorial.extra.interfaces.*;
// Yakindu listeners
import hu.bme.mit.gamma.tutorial.extra.monitor.IMonitorStatemachine.*;
import hu.bme.mit.gamma.tutorial.extra.*;
import hu.bme.mit.gamma.tutorial.extra.monitor.MonitorStatemachine.State;

public class Monitor implements MonitorInterface {
	// The wrapped Yakindu statemachine
	private MonitorStatemachine monitorStatemachine;
	// Port instances
	private LightInputs lightInputs;
	private Error error;
	// Indicates which queue is active in a cycle
	private boolean insertQueue = true;
	private boolean processQueue = false;
	// Event queues for the synchronization of statecharts
	private Queue<Event> eventQueue1 = new LinkedList<Event>();
	private Queue<Event> eventQueue2 = new LinkedList<Event>();
	
	public Monitor() {
		monitorStatemachine = new MonitorStatemachine();
		lightInputs = new LightInputs();
		error = new Error();
	}
	
	/** Resets the statemachine. Must be called to initialize the component. */
	@Override
	public void reset() {
		// Clearing the in events
		insertQueue = true;
		processQueue = false;
		eventQueue1.clear();
		eventQueue2.clear();
		//
		monitorStatemachine.init();
		monitorStatemachine.enter();
		notifyListeners();
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
					case "LightInputs.DisplayYellow": 
						monitorStatemachine.getSCILightInputs().raiseDisplayYellow();
					break;
					case "LightInputs.DisplayRed": 
						monitorStatemachine.getSCILightInputs().raiseDisplayRed();
					break;
					case "LightInputs.DisplayGreen": 
						monitorStatemachine.getSCILightInputs().raiseDisplayGreen();
					break;
					default:
						throw new IllegalArgumentException("No such event!");
				}
		}
		monitorStatemachine.runCycle();
		notifyListeners();
	}
	
	// Inner classes representing Ports
	public class LightInputs implements LightCommandsInterface.Required {
		private List<LightCommandsInterface.Listener.Required> registeredListeners = new LinkedList<LightCommandsInterface.Listener.Required>();

		@Override
		public void raiseDisplayNone() {
			getInsertQueue().add(new Event("LightInputs.DisplayNone"));
		}
		
		@Override
		public void raiseDisplayYellow() {
			getInsertQueue().add(new Event("LightInputs.DisplayYellow"));
		}
		
		@Override
		public void raiseDisplayRed() {
			getInsertQueue().add(new Event("LightInputs.DisplayRed"));
		}
		
		@Override
		public void raiseDisplayGreen() {
			getInsertQueue().add(new Event("LightInputs.DisplayGreen"));
		}

		@Override
		public void registerListener(final LightCommandsInterface.Listener.Required listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<LightCommandsInterface.Listener.Required> getRegisteredListeners() {
			return registeredListeners;
		}
		
		/** Notifying the registered listeners. */
		public void notifyListeners() {
		}

	}
	
	@Override
	public LightInputs getLightInputs() {
		return lightInputs;
	}
	
	public class Error implements ErrorInterface.Provided {
		private List<ErrorInterface.Listener.Provided> registeredListeners = new LinkedList<ErrorInterface.Listener.Provided>();


		@Override
		public boolean isRaisedError() {
			return monitorStatemachine.getSCIError().isRaisedError();
		}
		@Override
		public void registerListener(final ErrorInterface.Listener.Provided listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<ErrorInterface.Listener.Provided> getRegisteredListeners() {
			return registeredListeners;
		}
		
		/** Notifying the registered listeners. */
		public void notifyListeners() {
			if (isRaisedError()) {
				for (ErrorInterface.Listener.Provided listener : registeredListeners) {
					listener.raiseError();
				}
			}
		}

	}
	
	@Override
	public Error getError() {
		return error;
	}
	
	/** Interface method, needed for composite component initialization chain. */
	public void notifyAllListeners() {
		notifyListeners();
	}
	
	/** Notifies all registered listeners in each contained port. */
	public void notifyListeners() {
		getLightInputs().notifyListeners();
		getError().notifyListeners();
	}
	
	
	/** Checks whether the wrapped statemachine is in the given state. */
	public boolean isStateActive(State state) {
		return monitorStatemachine.isStateActive(state);
	}
	
	public boolean isStateActive(String region, String state) {
		switch (region) {
			case "main_region":
				switch (state) {
					case "Green":
						return isStateActive(State.main_region_Green);
					case "Error":
						return isStateActive(State.main_region_Error);
					case "Other":
						return isStateActive(State.main_region_Other);
					case "Red":
						return isStateActive(State.main_region_Red);
				}
		}
		return false;
	}

	
	
	
}
