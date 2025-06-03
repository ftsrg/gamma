package hu.bme.mit.gamma.stpa.cofi.casestudy.traindoorcontrol;

import static org.junit.Assert.assertTrue;

import org.junit.Before;
import org.junit.Test;

import hu.bme.mit.gamma.stpa.cofi.casestudy.interfaces.ControlAction;
import hu.bme.mit.gamma.stpa.cofi.casestudy.interfaces.DoorState;
import hu.bme.mit.gamma.stpa.cofi.casestudy.interfaces.ExternalCommunicationInterface.Required;
import hu.bme.mit.gamma.stpa.cofi.casestudy.interfaces.MotionState;
import hu.bme.mit.gamma.stpa.cofi.casestudy.traindoorcontrol.TrainDoorControllerAdapter.ControlActions;
import hu.bme.mit.gamma.stpa.cofi.casestudy.traindoorcontrol.TrainDoorControllerAdapter.FeedbackDoorState;

public class Tests {

	private static TrainDoorControllerAdapter controller;

	@Before
	public void init() {
		controller = new TrainDoorControllerAdapter();
		controller.reset();
	}
	
	@Test
	public void test() {
		Required communicationPort = controller.getExternalCommunication();
		ControlActions actionsPort = controller.getControlActions();
		
		communicationPort.raiseAlignment(true); // Remains in the same state
		controller.schedule();
		
		assertTrue(actionsPort.isRaisedControlDoor());
	}
	
	@Test
	public void test2() {
		Required communicationPort = controller.getExternalCommunication();
		ControlActions actionsPort = controller.getControlActions();
		
		communicationPort.raiseAlignment(false);
		controller.schedule();

		assertTrue(!actionsPort.isRaisedControlDoor());
		
		communicationPort.raiseMovement(MotionState.UNCATEGORIZED_MOTION);
		controller.schedule();
		
		assertTrue(!actionsPort.isRaisedControlDoor());
	}
	
	@Test
	public void test3() {
		Required communicationPort = controller.getExternalCommunication();
		ControlActions actionsPort = controller.getControlActions();
		
		test2();
		
		communicationPort.raiseAlignment(true);
		controller.schedule();
		
		communicationPort.raiseMovement(MotionState.STILL);
		controller.schedule();
		
		assertTrue(actionsPort.isRaisedControlDoor());
		assertTrue(actionsPort.getAction() == ControlAction.OPEN);
	}
	
	@Test
	public void test4() {
		Required communicationPort = controller.getExternalCommunication();
		ControlActions actionsPort = controller.getControlActions();
		
		test2();
		
		communicationPort.raiseMovement(MotionState.STILL);
		controller.schedule();
		
		communicationPort.raiseAlignment(true);
		controller.schedule();
		
		assertTrue(actionsPort.isRaisedControlDoor());
		assertTrue(actionsPort.getAction() == ControlAction.OPEN);
	}
	
	@Test
	public void test5() {
		Required communicationPort = controller.getExternalCommunication();
		FeedbackDoorState doorPort = controller.getFeedbackDoorState();
		ControlActions actionsPort = controller.getControlActions();
		
		test4();
		
		doorPort.raiseFeedback(DoorState.OPENING); // End of test4
		controller.schedule();
		
		communicationPort.raiseMovement(MotionState.DEPARTING);
		controller.schedule();
		
		assertTrue(actionsPort.isRaisedControlDoor());
		assertTrue(actionsPort.getAction() == ControlAction.CLOSE);
	}

}