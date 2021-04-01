package hu.bme.mit.gamma.tutorial.contract.finish.controller;

import hu.bme.mit.gamma.tutorial.contract.finish.*; 		
public class ControllerStatemachine {
	
	enum Main_region {__Inactive__, Operating, Init, Interrupted}
	enum Operating {__Inactive__, PriorityPrepares, Secondary, SecondaryPrepares, Priority}
	private boolean SecondaryPolice_police_Out;
	private boolean PriorityPolice_police_Out;
	private boolean SecondaryControl_toggle_Out;
	private boolean PriorityControl_toggle_Out;
	private boolean PoliceInterrupt_police_In;
	private Main_region main_region;
	private Operating operating;
	private boolean __assertionFailed;
	private long InitTimeout3;
	private long SecondaryPreparesTimeout2;
	
	public ControllerStatemachine() {
	}
	
	public void reset() {
		this.main_region = Main_region.__Inactive__;
		this.operating = Operating.__Inactive__;
		clearOutEvents();
		clearInEvents();
		this.__assertionFailed = false;
		this.SecondaryPreparesTimeout2 = ((((1000 * 2) + (1000 * 1)) + (1000 * 2)) + (1000 * 1));
		this.InitTimeout3 = (1000 * 2);
		this.main_region = Main_region.__Inactive__;
		this.operating = Operating.__Inactive__;
		this.PoliceInterrupt_police_In = false;
		this.SecondaryPolice_police_Out = false;
		this.PriorityPolice_police_Out = false;
		this.SecondaryControl_toggle_Out = false;
		this.PriorityControl_toggle_Out = false;
		this.main_region = Main_region.Init;
		if ((this.main_region == Main_region.Operating)) {
			if ((this.operating == Operating.PriorityPrepares)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.PriorityControl_toggle_Out = true;
			} else 
			if ((this.operating == Operating.Secondary)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.PriorityControl_toggle_Out = true;
				this.SecondaryControl_toggle_Out = true;
			} else 
			if ((this.operating == Operating.SecondaryPrepares)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.SecondaryControl_toggle_Out = true;
			} else 
			if ((this.operating == Operating.Priority)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.PriorityControl_toggle_Out = true;
				this.SecondaryControl_toggle_Out = true;
			}
		} else 
		if ((this.main_region == Main_region.Init)) {
			this.InitTimeout3 = 0;
			this.PriorityControl_toggle_Out = true;
		}
	}
	
	public void setSecondaryPolice_police_Out(boolean SecondaryPolice_police_Out) {
		this.SecondaryPolice_police_Out = SecondaryPolice_police_Out;
	}
	
	public boolean getSecondaryPolice_police_Out() {
		return SecondaryPolice_police_Out;
	}
	
	public void setPriorityPolice_police_Out(boolean PriorityPolice_police_Out) {
		this.PriorityPolice_police_Out = PriorityPolice_police_Out;
	}
	
	public boolean getPriorityPolice_police_Out() {
		return PriorityPolice_police_Out;
	}
	
	public void setSecondaryControl_toggle_Out(boolean SecondaryControl_toggle_Out) {
		this.SecondaryControl_toggle_Out = SecondaryControl_toggle_Out;
	}
	
	public boolean getSecondaryControl_toggle_Out() {
		return SecondaryControl_toggle_Out;
	}
	
	public void setPriorityControl_toggle_Out(boolean PriorityControl_toggle_Out) {
		this.PriorityControl_toggle_Out = PriorityControl_toggle_Out;
	}
	
	public boolean getPriorityControl_toggle_Out() {
		return PriorityControl_toggle_Out;
	}
	
	public void setPoliceInterrupt_police_In(boolean PoliceInterrupt_police_In) {
		this.PoliceInterrupt_police_In = PoliceInterrupt_police_In;
	}
	
	public boolean getPoliceInterrupt_police_In() {
		return PoliceInterrupt_police_In;
	}
	
	public void setMain_region(Main_region main_region) {
		this.main_region = main_region;
	}
	
	public Main_region getMain_region() {
		return main_region;
	}
	
	public void setOperating(Operating operating) {
		this.operating = operating;
	}
	
	public Operating getOperating() {
		return operating;
	}
	
	public void setInitTimeout3(long InitTimeout3) {
		this.InitTimeout3 = InitTimeout3;
	}
	
	public long getInitTimeout3() {
		return InitTimeout3;
	}
	
	public void setSecondaryPreparesTimeout2(long SecondaryPreparesTimeout2) {
		this.SecondaryPreparesTimeout2 = SecondaryPreparesTimeout2;
	}
	
	public long getSecondaryPreparesTimeout2() {
		return SecondaryPreparesTimeout2;
	}
	
	public void set__assertionFailed(boolean __assertionFailed) {
		this.__assertionFailed = __assertionFailed;
	}
	
	public boolean get__assertionFailed() {
		return __assertionFailed;
	}
	
	public void runCycle() {
		clearOutEvents();
		changeState();
		clearInEvents();
	}

	private void changeState() {
		if (((((!((((this.main_region == Main_region.Operating)) && ((this.PoliceInterrupt_police_In == true))))))) && ((((((this.main_region == Main_region.Operating)) && ((this.operating == Operating.Priority)))) && (((1000 * 2) <= this.SecondaryPreparesTimeout2)))))) {
			this.operating = Operating.PriorityPrepares;
			this.SecondaryPreparesTimeout2 = 0;
			this.PriorityControl_toggle_Out = true;
		} else 
		if (((((!((((this.main_region == Main_region.Operating)) && ((this.PoliceInterrupt_police_In == true))))))) && ((((((this.main_region == Main_region.Operating)) && ((this.operating == Operating.Secondary)))) && (((1000 * 2) <= this.SecondaryPreparesTimeout2)))))) {
			this.operating = Operating.SecondaryPrepares;
			this.SecondaryPreparesTimeout2 = 0;
			this.SecondaryControl_toggle_Out = true;
		} else 
		if (((((!((((this.main_region == Main_region.Operating)) && ((this.PoliceInterrupt_police_In == true))))))) && ((((((this.main_region == Main_region.Operating)) && ((this.operating == Operating.SecondaryPrepares)))) && (((1000 * 1) <= this.SecondaryPreparesTimeout2)))))) {
			this.operating = Operating.Priority;
			this.SecondaryPreparesTimeout2 = 0;
			this.PriorityControl_toggle_Out = true;
			this.SecondaryControl_toggle_Out = true;
		} else 
		if (((((!((((this.main_region == Main_region.Operating)) && ((this.PoliceInterrupt_police_In == true))))))) && ((((((this.main_region == Main_region.Operating)) && ((this.operating == Operating.PriorityPrepares)))) && (((1000 * 1) <= this.SecondaryPreparesTimeout2)))))) {
			this.operating = Operating.Secondary;
			this.SecondaryPreparesTimeout2 = 0;
			this.PriorityControl_toggle_Out = true;
			this.SecondaryControl_toggle_Out = true;
		} else 
		if ((((((this.main_region == Main_region.Operating)) && ((this.PoliceInterrupt_police_In == true)))))) {
			this.operating = Operating.__Inactive__;
			this.PriorityPolice_police_Out = true;
			this.SecondaryPolice_police_Out = true;
			this.main_region = Main_region.Interrupted;
		} else 
		if ((((((this.main_region == Main_region.Init)) && (((1000 * 2) <= this.InitTimeout3)))))) {
			this.main_region = Main_region.Operating;
			this.operating = Operating.PriorityPrepares;
			if ((this.operating == Operating.PriorityPrepares)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.PriorityControl_toggle_Out = true;
			} else 
			if ((this.operating == Operating.Secondary)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.PriorityControl_toggle_Out = true;
				this.SecondaryControl_toggle_Out = true;
			} else 
			if ((this.operating == Operating.SecondaryPrepares)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.SecondaryControl_toggle_Out = true;
			} else 
			if ((this.operating == Operating.Priority)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.PriorityControl_toggle_Out = true;
				this.SecondaryControl_toggle_Out = true;
			}
		} else 
		if ((((((this.main_region == Main_region.Interrupted)) && ((this.PoliceInterrupt_police_In == true)))))) {
			this.PriorityPolice_police_Out = true;
			this.SecondaryPolice_police_Out = true;
			this.main_region = Main_region.Operating;
			this.operating = Operating.PriorityPrepares;
			if ((this.operating == Operating.PriorityPrepares)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.PriorityControl_toggle_Out = true;
			} else 
			if ((this.operating == Operating.Secondary)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.PriorityControl_toggle_Out = true;
				this.SecondaryControl_toggle_Out = true;
			} else 
			if ((this.operating == Operating.SecondaryPrepares)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.SecondaryControl_toggle_Out = true;
			} else 
			if ((this.operating == Operating.Priority)) {
				this.SecondaryPreparesTimeout2 = 0;
				this.PriorityControl_toggle_Out = true;
				this.SecondaryControl_toggle_Out = true;
			}
		}
	}
	
	private void clearOutEvents() {
		SecondaryPolice_police_Out = false;
		PriorityPolice_police_Out = false;
		SecondaryControl_toggle_Out = false;
		PriorityControl_toggle_Out = false;
	}
	
	private void clearInEvents() {
		PoliceInterrupt_police_In = false;
	}
	
	@Override
	public String toString() {
		return
			"SecondaryPolice_police_Out = " + SecondaryPolice_police_Out + System.lineSeparator() +
			"PriorityPolice_police_Out = " + PriorityPolice_police_Out + System.lineSeparator() +
			"SecondaryControl_toggle_Out = " + SecondaryControl_toggle_Out + System.lineSeparator() +
			"PriorityControl_toggle_Out = " + PriorityControl_toggle_Out + System.lineSeparator() +
			"PoliceInterrupt_police_In = " + PoliceInterrupt_police_In + System.lineSeparator() +
			"main_region = " + main_region + System.lineSeparator() +
			"operating = " + operating + System.lineSeparator() +
			"InitTimeout3 = " + InitTimeout3 + System.lineSeparator() +
			"SecondaryPreparesTimeout2 = " + SecondaryPreparesTimeout2 + System.lineSeparator() +
			"__assertionFailed = " + __assertionFailed
		;
	}
	
}
