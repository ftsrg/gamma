package hu.bme.mit.gamma.tutorial.contract.finish.trafficlightctrl;

import hu.bme.mit.gamma.tutorial.contract.finish.*; 		
public class TrafficLightCtrlStatemachine {
	
	enum Main_region {__Inactive__, Interrupted, Normal}
	enum Interrupted {__Inactive__, BlinkingYellow, Black}
	enum Normal {__Inactive__, Red, Green, Yellow}
	private boolean LightCommands_displayYellow_Out;
	private boolean LightCommands_displayNone_Out;
	private boolean LightCommands_displayRed_Out;
	private boolean LightCommands_displayGreen_Out;
	private boolean PoliceInterrupt_police_In;
	private boolean Control_toggle_In;
	private Main_region main_region;
	private Interrupted interrupted;
	private Normal normal;
	private boolean __assertionFailed;
	private long BlackTimeout3;
	
	public TrafficLightCtrlStatemachine() {
	}
	
	public void reset() {
		this.main_region = Main_region.__Inactive__;
		this.interrupted = Interrupted.__Inactive__;
		this.normal = Normal.__Inactive__;
		clearOutEvents();
		clearInEvents();
		this.__assertionFailed = false;
		this.BlackTimeout3 = (500 + 500);
		this.main_region = Main_region.__Inactive__;
		this.interrupted = Interrupted.__Inactive__;
		this.normal = Normal.__Inactive__;
		this.PoliceInterrupt_police_In = false;
		this.Control_toggle_In = false;
		this.LightCommands_displayYellow_Out = false;
		this.LightCommands_displayNone_Out = false;
		this.LightCommands_displayRed_Out = false;
		this.LightCommands_displayGreen_Out = false;
		this.main_region = Main_region.Normal;
		if ((this.normal == Normal.__Inactive__)) {
			this.normal = Normal.Red;
		}
		if ((this.main_region == Main_region.Interrupted)) {
			if ((this.interrupted == Interrupted.BlinkingYellow)) {
				this.BlackTimeout3 = 0;
				this.LightCommands_displayYellow_Out = true;
			} else 
			if ((this.interrupted == Interrupted.Black)) {
				this.BlackTimeout3 = 0;
				this.LightCommands_displayNone_Out = true;
			}
		} else 
		if ((this.main_region == Main_region.Normal)) {
			if ((this.normal == Normal.Red)) {
				this.LightCommands_displayRed_Out = true;
			} else 
			if ((this.normal == Normal.Green)) {
				this.LightCommands_displayGreen_Out = true;
			} else 
			if ((this.normal == Normal.Yellow)) {
				this.LightCommands_displayYellow_Out = true;
			}
		}
	}
	
	public void setLightCommands_displayYellow_Out(boolean LightCommands_displayYellow_Out) {
		this.LightCommands_displayYellow_Out = LightCommands_displayYellow_Out;
	}
	
	public boolean getLightCommands_displayYellow_Out() {
		return LightCommands_displayYellow_Out;
	}
	
	public void setLightCommands_displayNone_Out(boolean LightCommands_displayNone_Out) {
		this.LightCommands_displayNone_Out = LightCommands_displayNone_Out;
	}
	
	public boolean getLightCommands_displayNone_Out() {
		return LightCommands_displayNone_Out;
	}
	
	public void setLightCommands_displayRed_Out(boolean LightCommands_displayRed_Out) {
		this.LightCommands_displayRed_Out = LightCommands_displayRed_Out;
	}
	
	public boolean getLightCommands_displayRed_Out() {
		return LightCommands_displayRed_Out;
	}
	
	public void setLightCommands_displayGreen_Out(boolean LightCommands_displayGreen_Out) {
		this.LightCommands_displayGreen_Out = LightCommands_displayGreen_Out;
	}
	
	public boolean getLightCommands_displayGreen_Out() {
		return LightCommands_displayGreen_Out;
	}
	
	public void setPoliceInterrupt_police_In(boolean PoliceInterrupt_police_In) {
		this.PoliceInterrupt_police_In = PoliceInterrupt_police_In;
	}
	
	public boolean getPoliceInterrupt_police_In() {
		return PoliceInterrupt_police_In;
	}
	
	public void setControl_toggle_In(boolean Control_toggle_In) {
		this.Control_toggle_In = Control_toggle_In;
	}
	
	public boolean getControl_toggle_In() {
		return Control_toggle_In;
	}
	
	public void setMain_region(Main_region main_region) {
		this.main_region = main_region;
	}
	
	public Main_region getMain_region() {
		return main_region;
	}
	
	public void setInterrupted(Interrupted interrupted) {
		this.interrupted = interrupted;
	}
	
	public Interrupted getInterrupted() {
		return interrupted;
	}
	
	public void setNormal(Normal normal) {
		this.normal = normal;
	}
	
	public Normal getNormal() {
		return normal;
	}
	
	public void setBlackTimeout3(long BlackTimeout3) {
		this.BlackTimeout3 = BlackTimeout3;
	}
	
	public long getBlackTimeout3() {
		return BlackTimeout3;
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
		if (((((!((((this.main_region == Main_region.Interrupted)) && ((this.PoliceInterrupt_police_In == true))))))) && ((((((this.main_region == Main_region.Interrupted)) && ((this.interrupted == Interrupted.Black)))) && ((500 <= this.BlackTimeout3)))))) {
			this.interrupted = Interrupted.BlinkingYellow;
			this.BlackTimeout3 = 0;
			this.LightCommands_displayYellow_Out = true;
		} else 
		if (((((!((((this.main_region == Main_region.Interrupted)) && ((this.PoliceInterrupt_police_In == true))))))) && ((((((this.main_region == Main_region.Interrupted)) && ((this.interrupted == Interrupted.BlinkingYellow)))) && ((500 <= this.BlackTimeout3)))))) {
			this.interrupted = Interrupted.Black;
			this.BlackTimeout3 = 0;
			this.LightCommands_displayNone_Out = true;
		} else 
		if (((((!((((this.main_region == Main_region.Normal)) && ((this.PoliceInterrupt_police_In == true))))))) && ((((((this.main_region == Main_region.Normal)) && ((this.normal == Normal.Yellow)))) && ((this.Control_toggle_In == true)))))) {
			this.normal = Normal.Red;
			this.LightCommands_displayRed_Out = true;
		} else 
		if (((((!((((this.main_region == Main_region.Normal)) && ((this.PoliceInterrupt_police_In == true))))))) && ((((((this.main_region == Main_region.Normal)) && ((this.normal == Normal.Green)))) && ((this.Control_toggle_In == true)))))) {
			this.normal = Normal.Yellow;
			this.LightCommands_displayYellow_Out = true;
		} else 
		if (((((!((((this.main_region == Main_region.Normal)) && ((this.PoliceInterrupt_police_In == true))))))) && ((((((this.main_region == Main_region.Normal)) && ((this.normal == Normal.Red)))) && ((this.Control_toggle_In == true)))))) {
			this.normal = Normal.Green;
			this.LightCommands_displayGreen_Out = true;
		} else 
		if ((((((this.main_region == Main_region.Normal)) && ((this.PoliceInterrupt_police_In == true)))))) {
			this.main_region = Main_region.Interrupted;
			this.interrupted = Interrupted.BlinkingYellow;
			if ((this.interrupted == Interrupted.BlinkingYellow)) {
				this.BlackTimeout3 = 0;
				this.LightCommands_displayYellow_Out = true;
			} else 
			if ((this.interrupted == Interrupted.Black)) {
				this.BlackTimeout3 = 0;
				this.LightCommands_displayNone_Out = true;
			}
		} else 
		if ((((((this.main_region == Main_region.Interrupted)) && ((this.PoliceInterrupt_police_In == true)))))) {
			this.interrupted = Interrupted.__Inactive__;
			this.main_region = Main_region.Normal;
			if ((this.normal == Normal.__Inactive__)) {
				this.normal = Normal.Red;
			}
			if ((this.normal == Normal.Red)) {
				this.LightCommands_displayRed_Out = true;
			} else 
			if ((this.normal == Normal.Green)) {
				this.LightCommands_displayGreen_Out = true;
			} else 
			if ((this.normal == Normal.Yellow)) {
				this.LightCommands_displayYellow_Out = true;
			}
		}
	}
	
	private void clearOutEvents() {
		LightCommands_displayYellow_Out = false;
		LightCommands_displayNone_Out = false;
		LightCommands_displayRed_Out = false;
		LightCommands_displayGreen_Out = false;
	}
	
	private void clearInEvents() {
		PoliceInterrupt_police_In = false;
		Control_toggle_In = false;
	}
	
	@Override
	public String toString() {
		return
			"LightCommands_displayYellow_Out = " + LightCommands_displayYellow_Out + System.lineSeparator() +
			"LightCommands_displayNone_Out = " + LightCommands_displayNone_Out + System.lineSeparator() +
			"LightCommands_displayRed_Out = " + LightCommands_displayRed_Out + System.lineSeparator() +
			"LightCommands_displayGreen_Out = " + LightCommands_displayGreen_Out + System.lineSeparator() +
			"PoliceInterrupt_police_In = " + PoliceInterrupt_police_In + System.lineSeparator() +
			"Control_toggle_In = " + Control_toggle_In + System.lineSeparator() +
			"main_region = " + main_region + System.lineSeparator() +
			"interrupted = " + interrupted + System.lineSeparator() +
			"normal = " + normal + System.lineSeparator() +
			"BlackTimeout3 = " + BlackTimeout3 + System.lineSeparator() +
			"__assertionFailed = " + __assertionFailed
		;
	}
	
}
