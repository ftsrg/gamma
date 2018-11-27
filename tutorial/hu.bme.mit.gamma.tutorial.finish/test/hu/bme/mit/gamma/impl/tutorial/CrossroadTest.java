package hu.bme.mit.gamma.impl.tutorial;

import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import org.junit.Before;
import org.junit.Test;

import hu.bme.mit.gamma.tutorial.finish.interfaces.LightCommandsInterface.Listener.Provided;
import hu.bme.mit.gamma.tutorial.finish.tutorial.Crossroad;

public class CrossroadTest {

	/**
	 * Use this class to record the output events of the crossroad. Reset after
	 * every step.
	 *
	 */
	private static class CommandListener implements Provided {
		private boolean green = false, yellow = false, red = false, none = false;

		@Override
		public void raiseDisplayGreen() {
			green = true;
		}

		@Override
		public void raiseDisplayRed() {
			red = true;
		}

		@Override
		public void raiseDisplayYellow() {
			yellow = true;
		}

		@Override
		public void raiseDisplayNone() {
			none = true;
		}

		public boolean raisedGreen() {
			return green;
		}

		public boolean raisedYellow() {
			return yellow;
		}

		public boolean raisedRed() {
			return red;
		}

		public boolean raisedNone() {
			return none;
		}

		public void reset() {
			green = false;
			yellow = false;
			red = false;
			none = false;
		}
	}

	private static Crossroad crossroadComponent;

	@Before
	public void init() {
		crossroadComponent = new Crossroad();
	}

	/**
	 * This test checks if the light of the priority road is initially red, but
	 * after the controller is initialized, it is immediately switched to green.
	 * Uses the prepared listener ({@link CommandListener}) to record the output
	 * events.
	 */
	@Test
	public void greenAtStart() {
		// Initialize the component
		crossroadComponent.reset();
		// DisplayRed should be raised right after initialization
		// It is possible to check if a given event is raised on a port, but this may
		// not work with runFullCycle(), because the events are raised only for a single
		// cycle.
		assertTrue(crossroadComponent.getPriorityOutput().isRaisedDisplayRed());

		CommandListener listener = new CommandListener();
		// Register CommandListener
		crossroadComponent.getPriorityOutput().registerListener(listener);

		// The controller will then initialize the priority light to green, but this
		// happens one cycle later
		crossroadComponent.runFullCycle();

		// DisplayGreen should be raised after this
		assertTrue(listener.raisedGreen());
		// Reset listener
		listener.reset();
	}

	/**
	 * This test checks if the light of the priority road will be red again after
	 * waiting for the controller to trigger two times, while raising the
	 * appropriate control events when switching. Uses the prepared listener
	 * ({@link CommandListener}) to record the output events.
	 */
	@Test
	public void switchToRed() {
		CommandListener listener = new CommandListener();
		// Register CommandListener
		crossroadComponent.getPriorityOutput().registerListener(listener);

		// Initialize the component
		crossroadComponent.reset();

		// DisplayGreen should have been raised during initialization
		assertTrue(listener.raisedRed());

		// The controller will first initialize the priority light to green
		crossroadComponent.runFullCycle();

		// DisplayGreen should have been raised during this
		assertTrue(listener.raisedGreen());
		// Reset listener
		listener.reset();

		// Wait for 2 seconds and some to switch to yellow
		try {
			Thread.sleep(2300);
		} catch (InterruptedException e) {
			fail("Interrupted waiting.");
		}
		// Run the statecharts until they process every event (macrostep)
		crossroadComponent.runFullCycle();

		// TODO: complete the test case based on the comments
		// DisplayYellow should have been raised during this
		assertTrue(listener.raisedYellow());
		// Reset listener
		listener.reset();

		// Wait for 1 second to switch to red
		try {
			Thread.sleep(1000);
		} catch (InterruptedException e) {
			fail("Interrupted waiting.");
		}
		// Run the statecharts until they process every event
		crossroadComponent.runFullCycle();

		// DisplayRed should have been raised during this
		assertTrue(listener.raisedRed());
		// Reset listener
		listener.reset();
	}

}
