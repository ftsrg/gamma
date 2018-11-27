	package hu.bme.mit.gamma.tutorial.finish.tutorial;

	import java.util.List;
	import java.util.LinkedList;
	
	import hu.bme.mit.gamma.tutorial.finish.*;
	import hu.bme.mit.gamma.tutorial.finish.interfaces.*;
	import hu.bme.mit.gamma.tutorial.finish.controller.*;
	import hu.bme.mit.gamma.tutorial.finish.trafficlightctrl.*;
	
	public class Crossroad implements CrossroadInterface {			
		// Component instances
		private ControllerStatechart controller = new ControllerStatechart();
		private TrafficLightCtrlStatechart prior = new TrafficLightCtrlStatechart();
		private TrafficLightCtrlStatechart secondary = new TrafficLightCtrlStatechart();
		// Port instances
		private Police police = new Police();
		private PriorityOutput priorityOutput = new PriorityOutput();
		private SecondaryOutput secondaryOutput = new SecondaryOutput();
		
		public Crossroad(ITimer timer) {
			setTimer(timer);
			init();
		}
		
		public Crossroad() {
			init();
		}
		
		/** Resets the contained statemachines recursively. Should be used only be the container (composite system) class. */
		@Override
		public void reset() {
			controller.reset();
			prior.reset();
			secondary.reset();
			// Initializing chain of listeners and events 
			initListenerChain();
		}
		
		/** Creates the channel mappings and enters the wrapped statemachines. */
		private void init() {
			// Registration of simple channels
			controller.getSecondaryControl().registerListener(secondary.getControl());
			secondary.getControl().registerListener(controller.getSecondaryControl());
			controller.getPriorityControl().registerListener(prior.getControl());
			prior.getControl().registerListener(controller.getPriorityControl());
			controller.getPriorityPolice().registerListener(prior.getPoliceInterrupt());
			prior.getPoliceInterrupt().registerListener(controller.getPriorityPolice());
			controller.getSecondaryPolice().registerListener(secondary.getPoliceInterrupt());
			secondary.getPoliceInterrupt().registerListener(controller.getSecondaryPolice());
			// Registration of broadcast channels
		}
		
		// Inner classes representing Ports
		public class Police implements PoliceInterruptInterface.Required {
			private List<PoliceInterruptInterface.Listener.Required> listeners = new LinkedList<PoliceInterruptInterface.Listener.Required>();

			
			public Police() {
				// Registering the listener to the contained component
				controller.getPoliceInterrupt().registerListener(new PoliceUtil());
			}
			
			@Override
			public void raisePolice() {
				controller.getPoliceInterrupt().raisePolice();
			}
			
			
			// Class for the setting of the boolean fields (events)
			private class PoliceUtil implements PoliceInterruptInterface.Listener.Required {
			}
			
			@Override
			public void registerListener(PoliceInterruptInterface.Listener.Required listener) {
				listeners.add(listener);
			}
			
			@Override
			public List<PoliceInterruptInterface.Listener.Required> getRegisteredListeners() {
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
		public Police getPolice() {
			return police;
		}
		
		public class PriorityOutput implements LightCommandsInterface.Provided {
			private List<LightCommandsInterface.Listener.Provided> listeners = new LinkedList<LightCommandsInterface.Listener.Provided>();

			boolean isRaisedDisplayRed;
			boolean isRaisedDisplayYellow;
			boolean isRaisedDisplayNone;
			boolean isRaisedDisplayGreen;
			
			public PriorityOutput() {
				// Registering the listener to the contained component
				prior.getLightCommands().registerListener(new PriorityOutputUtil());
			}
			
			
			@Override
			public boolean isRaisedDisplayRed() {
				return isRaisedDisplayRed;
			}
			
			@Override
			public boolean isRaisedDisplayYellow() {
				return isRaisedDisplayYellow;
			}
			
			@Override
			public boolean isRaisedDisplayNone() {
				return isRaisedDisplayNone;
			}
			
			@Override
			public boolean isRaisedDisplayGreen() {
				return isRaisedDisplayGreen;
			}
			
			// Class for the setting of the boolean fields (events)
			private class PriorityOutputUtil implements LightCommandsInterface.Listener.Provided {
				@Override
				public void raiseDisplayRed() {
					isRaisedDisplayRed = true;
				}
				
				@Override
				public void raiseDisplayYellow() {
					isRaisedDisplayYellow = true;
				}
				
				@Override
				public void raiseDisplayNone() {
					isRaisedDisplayNone = true;
				}
				
				@Override
				public void raiseDisplayGreen() {
					isRaisedDisplayGreen = true;
				}
			}
			
			@Override
			public void registerListener(LightCommandsInterface.Listener.Provided listener) {
				listeners.add(listener);
			}
			
			@Override
			public List<LightCommandsInterface.Listener.Provided> getRegisteredListeners() {
				return listeners;
			}
			
			/** Resetting the boolean event flags to false. */
			public void clear() {
				isRaisedDisplayRed = false;
				isRaisedDisplayYellow = false;
				isRaisedDisplayNone = false;
				isRaisedDisplayGreen = false;
			}
			
			/** Notifying the registered listeners. */
			public void notifyListeners() {
				if (isRaisedDisplayRed) {
					for (LightCommandsInterface.Listener.Provided listener : listeners) {
						listener.raiseDisplayRed();
					}
				}
				if (isRaisedDisplayYellow) {
					for (LightCommandsInterface.Listener.Provided listener : listeners) {
						listener.raiseDisplayYellow();
					}
				}
				if (isRaisedDisplayNone) {
					for (LightCommandsInterface.Listener.Provided listener : listeners) {
						listener.raiseDisplayNone();
					}
				}
				if (isRaisedDisplayGreen) {
					for (LightCommandsInterface.Listener.Provided listener : listeners) {
						listener.raiseDisplayGreen();
					}
				}
			}
			
		}
		
		@Override
		public PriorityOutput getPriorityOutput() {
			return priorityOutput;
		}
		
		public class SecondaryOutput implements LightCommandsInterface.Provided {
			private List<LightCommandsInterface.Listener.Provided> listeners = new LinkedList<LightCommandsInterface.Listener.Provided>();

			boolean isRaisedDisplayRed;
			boolean isRaisedDisplayYellow;
			boolean isRaisedDisplayNone;
			boolean isRaisedDisplayGreen;
			
			public SecondaryOutput() {
				// Registering the listener to the contained component
				secondary.getLightCommands().registerListener(new SecondaryOutputUtil());
			}
			
			
			@Override
			public boolean isRaisedDisplayRed() {
				return isRaisedDisplayRed;
			}
			
			@Override
			public boolean isRaisedDisplayYellow() {
				return isRaisedDisplayYellow;
			}
			
			@Override
			public boolean isRaisedDisplayNone() {
				return isRaisedDisplayNone;
			}
			
			@Override
			public boolean isRaisedDisplayGreen() {
				return isRaisedDisplayGreen;
			}
			
			// Class for the setting of the boolean fields (events)
			private class SecondaryOutputUtil implements LightCommandsInterface.Listener.Provided {
				@Override
				public void raiseDisplayRed() {
					isRaisedDisplayRed = true;
				}
				
				@Override
				public void raiseDisplayYellow() {
					isRaisedDisplayYellow = true;
				}
				
				@Override
				public void raiseDisplayNone() {
					isRaisedDisplayNone = true;
				}
				
				@Override
				public void raiseDisplayGreen() {
					isRaisedDisplayGreen = true;
				}
			}
			
			@Override
			public void registerListener(LightCommandsInterface.Listener.Provided listener) {
				listeners.add(listener);
			}
			
			@Override
			public List<LightCommandsInterface.Listener.Provided> getRegisteredListeners() {
				return listeners;
			}
			
			/** Resetting the boolean event flags to false. */
			public void clear() {
				isRaisedDisplayRed = false;
				isRaisedDisplayYellow = false;
				isRaisedDisplayNone = false;
				isRaisedDisplayGreen = false;
			}
			
			/** Notifying the registered listeners. */
			public void notifyListeners() {
				if (isRaisedDisplayRed) {
					for (LightCommandsInterface.Listener.Provided listener : listeners) {
						listener.raiseDisplayRed();
					}
				}
				if (isRaisedDisplayYellow) {
					for (LightCommandsInterface.Listener.Provided listener : listeners) {
						listener.raiseDisplayYellow();
					}
				}
				if (isRaisedDisplayNone) {
					for (LightCommandsInterface.Listener.Provided listener : listeners) {
						listener.raiseDisplayNone();
					}
				}
				if (isRaisedDisplayGreen) {
					for (LightCommandsInterface.Listener.Provided listener : listeners) {
						listener.raiseDisplayGreen();
					}
				}
			}
			
		}
		
		@Override
		public SecondaryOutput getSecondaryOutput() {
			return secondaryOutput;
		}
		
		/** Clears the the boolean flags of all out-events in each contained port. */
		private void clearPorts() {
			getPolice().clear();
			getPriorityOutput().clear();
			getSecondaryOutput().clear();
		}
		
		/** Notifies all registered listeners in each contained port. */
		private void notifyListeners() {
			getPolice().notifyListeners();
			getPriorityOutput().notifyListeners();
			getSecondaryOutput().notifyListeners();
		}
		
		/** Needed for the right event notification after initialization, as event notification from contained components
		 * does not happen automatically (see the port implementations and runComponent method). */
		public void initListenerChain() {
			notifyListeners();
		}
		
		/** Changes the event and process queues of all component instances. Should be used only be the container (composite system) class. */
		public void changeEventQueues() {
			controller.changeEventQueues();
			prior.changeEventQueues();
			secondary.changeEventQueues();
		}
		
		/** Returns whether all event queues of the contained component instances are empty. 
		Should be used only be the container (composite system) class. */
		public boolean isEventQueueEmpty() {
			return controller.isEventQueueEmpty() && prior.isEventQueueEmpty() && secondary.isEventQueueEmpty();
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
			controller.runComponent();
			prior.runComponent();
			secondary.runComponent();
			// Notifying registered listeners
			notifyListeners();
		}

		/** Setter for the timer e.g., a virtual timer. */
		public void setTimer(ITimer timer) {
			controller.setTimer(timer);
			prior.setTimer(timer);
			secondary.setTimer(timer);
		}
		
		/**  Getter for component instances, e.g. enabling to check their states. */
		public ControllerStatechart getController() {
			return controller;
		}
		
		public TrafficLightCtrlStatechart getPrior() {
			return prior;
		}
		
		public TrafficLightCtrlStatechart getSecondary() {
			return secondary;
		}
		
	}
