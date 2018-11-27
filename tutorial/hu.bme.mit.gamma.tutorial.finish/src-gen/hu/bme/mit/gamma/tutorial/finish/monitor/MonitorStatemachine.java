package hu.bme.mit.gamma.tutorial.finish.monitor;

public class MonitorStatemachine implements IMonitorStatemachine {

	protected class SCILightInputsImpl implements SCILightInputs {
	
		private boolean displayRed;
		
		public void raiseDisplayRed() {
			displayRed = true;
		}
		
		private boolean displayGreen;
		
		public void raiseDisplayGreen() {
			displayGreen = true;
		}
		
		private boolean displayYellow;
		
		public void raiseDisplayYellow() {
			displayYellow = true;
		}
		
		private boolean displayNone;
		
		public void raiseDisplayNone() {
			displayNone = true;
		}
		
		protected void clearEvents() {
			displayRed = false;
			displayGreen = false;
			displayYellow = false;
			displayNone = false;
		}
	}
	
	protected SCILightInputsImpl sCILightInputs;
	
	private boolean initialized = false;
	
	public enum State {
		main_region_Other,
		main_region_Green,
		main_region_Error,
		main_region_Red,
		$NullState$
	};
	
	private final State[] stateVector = new State[1];
	
	private int nextStateIndex;
	
	public MonitorStatemachine() {
		sCILightInputs = new SCILightInputsImpl();
	}
	
	public void init() {
		this.initialized = true;
		for (int i = 0; i < 1; i++) {
			stateVector[i] = State.$NullState$;
		}
		clearEvents();
		clearOutEvents();
	}
	
	public void enter() {
		if (!initialized) {
			throw new IllegalStateException(
					"The state machine needs to be initialized first by calling the init() function.");
		}
		enterSequence_main_region_default();
	}
	
	public void exit() {
		exitSequence_main_region();
	}
	
	/**
	 * @see IStatemachine#isActive()
	 */
	public boolean isActive() {
		return stateVector[0] != State.$NullState$;
	}
	
	/** 
	* Always returns 'false' since this state machine can never become final.
	*
	* @see IStatemachine#isFinal()
	*/
	public boolean isFinal() {
		return false;
	}
	/**
	* This method resets the incoming events (time events included).
	*/
	protected void clearEvents() {
		sCILightInputs.clearEvents();
	}
	
	/**
	* This method resets the outgoing events.
	*/
	protected void clearOutEvents() {
	}
	
	/**
	* Returns true if the given state is currently active otherwise false.
	*/
	public boolean isStateActive(State state) {
	
		switch (state) {
		case main_region_Other:
			return stateVector[0] == State.main_region_Other;
		case main_region_Green:
			return stateVector[0] == State.main_region_Green;
		case main_region_Error:
			return stateVector[0] == State.main_region_Error;
		case main_region_Red:
			return stateVector[0] == State.main_region_Red;
		default:
			return false;
		}
	}
	
	public SCILightInputs getSCILightInputs() {
		return sCILightInputs;
	}
	
	/* 'default' enter sequence for state Other */
	private void enterSequence_main_region_Other_default() {
		nextStateIndex = 0;
		stateVector[0] = State.main_region_Other;
	}
	
	/* 'default' enter sequence for state Green */
	private void enterSequence_main_region_Green_default() {
		nextStateIndex = 0;
		stateVector[0] = State.main_region_Green;
	}
	
	/* 'default' enter sequence for state Error */
	private void enterSequence_main_region_Error_default() {
		nextStateIndex = 0;
		stateVector[0] = State.main_region_Error;
	}
	
	/* 'default' enter sequence for state Red */
	private void enterSequence_main_region_Red_default() {
		nextStateIndex = 0;
		stateVector[0] = State.main_region_Red;
	}
	
	/* 'default' enter sequence for region main_region */
	private void enterSequence_main_region_default() {
		react_main_region__entry_Default();
	}
	
	/* Default exit sequence for state Other */
	private void exitSequence_main_region_Other() {
		nextStateIndex = 0;
		stateVector[0] = State.$NullState$;
	}
	
	/* Default exit sequence for state Green */
	private void exitSequence_main_region_Green() {
		nextStateIndex = 0;
		stateVector[0] = State.$NullState$;
	}
	
	/* Default exit sequence for state Error */
	private void exitSequence_main_region_Error() {
		nextStateIndex = 0;
		stateVector[0] = State.$NullState$;
	}
	
	/* Default exit sequence for state Red */
	private void exitSequence_main_region_Red() {
		nextStateIndex = 0;
		stateVector[0] = State.$NullState$;
	}
	
	/* Default exit sequence for region main_region */
	private void exitSequence_main_region() {
		switch (stateVector[0]) {
		case main_region_Other:
			exitSequence_main_region_Other();
			break;
		case main_region_Green:
			exitSequence_main_region_Green();
			break;
		case main_region_Error:
			exitSequence_main_region_Error();
			break;
		case main_region_Red:
			exitSequence_main_region_Red();
			break;
		default:
			break;
		}
	}
	
	/* Default react sequence for initial entry  */
	private void react_main_region__entry_Default() {
		enterSequence_main_region_Other_default();
	}
	
	private boolean react(boolean try_transition) {
		return false;
	}
	
	private boolean main_region_Other_react(boolean try_transition) {
		boolean did_transition = try_transition;
		
		if (try_transition) {
			if (react(try_transition)==false) {
				if (sCILightInputs.displayGreen) {
					exitSequence_main_region_Other();
					enterSequence_main_region_Green_default();
				} else {
					if (sCILightInputs.displayRed) {
						exitSequence_main_region_Other();
						enterSequence_main_region_Red_default();
					} else {
						did_transition = false;
					}
				}
			}
		}
		if (did_transition==false) {
		}
		return did_transition;
	}
	
	private boolean main_region_Green_react(boolean try_transition) {
		boolean did_transition = try_transition;
		
		if (try_transition) {
			if (react(try_transition)==false) {
				if (sCILightInputs.displayGreen) {
					exitSequence_main_region_Green();
					enterSequence_main_region_Error_default();
				} else {
					if (sCILightInputs.displayRed) {
						exitSequence_main_region_Green();
						enterSequence_main_region_Red_default();
					} else {
						if (sCILightInputs.displayNone) {
							exitSequence_main_region_Green();
							enterSequence_main_region_Other_default();
						} else {
							if (sCILightInputs.displayYellow) {
								exitSequence_main_region_Green();
								enterSequence_main_region_Other_default();
							} else {
								did_transition = false;
							}
						}
					}
				}
			}
		}
		if (did_transition==false) {
		}
		return did_transition;
	}
	
	private boolean main_region_Error_react(boolean try_transition) {
		boolean did_transition = try_transition;
		
		if (try_transition) {
			if (react(try_transition)==false) {
				did_transition = false;
			}
		}
		if (did_transition==false) {
		}
		return did_transition;
	}
	
	private boolean main_region_Red_react(boolean try_transition) {
		boolean did_transition = try_transition;
		
		if (try_transition) {
			if (react(try_transition)==false) {
				if (sCILightInputs.displayGreen) {
					exitSequence_main_region_Red();
					enterSequence_main_region_Green_default();
				} else {
					if (sCILightInputs.displayRed) {
						exitSequence_main_region_Red();
						enterSequence_main_region_Error_default();
					} else {
						if (sCILightInputs.displayNone) {
							exitSequence_main_region_Red();
							enterSequence_main_region_Other_default();
						} else {
							if (sCILightInputs.displayYellow) {
								exitSequence_main_region_Red();
								enterSequence_main_region_Other_default();
							} else {
								did_transition = false;
							}
						}
					}
				}
			}
		}
		if (did_transition==false) {
		}
		return did_transition;
	}
	
	public void runCycle() {
		if (!initialized)
			throw new IllegalStateException(
					"The state machine needs to be initialized first by calling the init() function.");
		clearOutEvents();
		for (nextStateIndex = 0; nextStateIndex < stateVector.length; nextStateIndex++) {
			switch (stateVector[nextStateIndex]) {
			case main_region_Other:
				main_region_Other_react(true);
				break;
			case main_region_Green:
				main_region_Green_react(true);
				break;
			case main_region_Error:
				main_region_Error_react(true);
				break;
			case main_region_Red:
				main_region_Red_react(true);
				break;
			default:
				// $NullState$
			}
		}
		clearEvents();
	}
}
