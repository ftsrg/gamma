	package hu.bme.mit.jpl.spacemission.mission;

	import java.util.List;
	import java.util.LinkedList;
	
	import hu.bme.mit.jpl.spacemission.*;
	import hu.bme.mit.jpl.spacemission.interfaces.*;
	import hu.bme.mit.jpl.spacemission.groundstation.*;
	import hu.bme.mit.jpl.spacemission.spacecraft.*;
	
	public class Mission implements MissionInterface {
		// Component instances
		private GroundStation station;
		private Spacecraft satellite;
		// Port instances
		private Control control;
		
		public Mission(UnifiedTimerInterface timer) {
			station = new GroundStation();
			satellite = new Spacecraft();
			control = new Control();
			setTimer(timer);
			init();
		}
		
		public Mission() {
			station = new GroundStation();
			satellite = new Spacecraft();
			control = new Control();
			init();
		}
		
		/** Resets the contained statemachines recursively. Must be called to initialize the component. */
		@Override
		public void reset() {
			station.reset();
			satellite.reset();
			// Initializing chain of listeners and events 
			initListenerChain();
		}
		
		/** Creates the channel mappings and enters the wrapped statemachines. */
		private void init() {
			// Registration of simple channels
			satellite.getConnection().registerListener(station.getConnection());
			station.getConnection().registerListener(satellite.getConnection());
			// Registration of broadcast channels
		}
		
		// Inner classes representing Ports
		public class Control implements StationControlInterface.Required {
			private List<StationControlInterface.Listener.Required> listeners = new LinkedList<StationControlInterface.Listener.Required>();

			
			public Control() {
				// Registering the listener to the contained component
				station.getControl().registerListener(new ControlUtil());
			}
			
			@Override
			public void raiseStart() {
				station.getControl().raiseStart();
			}
			
			@Override
			public void raiseShutdown() {
				station.getControl().raiseShutdown();
			}
			
			
			// Class for the setting of the boolean fields (events)
			private class ControlUtil implements StationControlInterface.Listener.Required {
			}
			
			@Override
			public void registerListener(StationControlInterface.Listener.Required listener) {
				listeners.add(listener);
			}
			
			@Override
			public List<StationControlInterface.Listener.Required> getRegisteredListeners() {
				return listeners;
			}
			
			/** Resetting the boolean event flags to false. */
			public void clear() {
			}
			
			/** Notifying the registered listeners. */
			public void notifyListeners() {
			}
			
		}
		
		@Override
		public Control getControl() {
			return control;
		}
		
		/** Clears the the boolean flags of all out-events in each contained port. */
		private void clearPorts() {
			getControl().clear();
		}
		
		/** Notifies all registered listeners in each contained port. */
		private void notifyListeners() {
			getControl().notifyListeners();
		}
		
		/** Needed for the right event notification after initialization, as event notification from contained components
		 * does not happen automatically (see the port implementations and runComponent method). */
		public void initListenerChain() {
			notifyListeners();
		}
		
		/** Changes the event and process queues of all component instances. Should be used only be the container (composite system) class. */
		public void changeEventQueues() {
			station.changeEventQueues();
			satellite.changeEventQueues();
		}
		
		/** Returns whether all event queues of the contained component instances are empty. 
		Should be used only be the container (composite system) class. */
		public boolean isEventQueueEmpty() {
			return station.isEventQueueEmpty() && satellite.isEventQueueEmpty();
		}
		
		/** Initiates cycle runs until all event queues of component instances are empty. */
		@Override
		public void runFullCycle() {
			do {
				runCycle();
			}
			while (!isEventQueueEmpty());
		}
		
		/** Changes event queues and initiates a cycle run.
			This should be the execution point from an asynchronous component. */
		@Override
		public void runCycle() {
			// Changing the insert and process queues for all synchronous subcomponents
			changeEventQueues();
			// Composite type-dependent behavior
			runComponent();
		}
		
		/** Initiates a cycle run without changing the event queues.
		 * Should be used only be the container (composite system) class. */
		public void runComponent() {
			// Starts with the clearing of the previous out-event flags
			clearPorts();
			// Running contained components
			station.runComponent();
			satellite.runComponent();
			// Notifying registered listeners
			notifyListeners();
		}

		/** Setter for the timer e.g., a virtual timer. */
		public void setTimer(UnifiedTimerInterface timer) {
			station.setTimer(timer);
			satellite.setTimer(timer);
		}
		
		/**  Getter for component instances, e.g., enabling to check their states. */
		public GroundStation getStation() {
			return station;
		}
		
		public Spacecraft getSatellite() {
			return satellite;
		}
		
	}
