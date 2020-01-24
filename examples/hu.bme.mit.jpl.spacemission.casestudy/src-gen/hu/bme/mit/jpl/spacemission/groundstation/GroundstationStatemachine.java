package hu.bme.mit.jpl.spacemission.groundstation;

public class GroundstationStatemachine {
	public enum Main {__Inactive__, Idle, Operation}
	public enum ReceiveData {__Inactive__, Waiting}
	private boolean control_start;
	private boolean control_shutdown;
	private boolean connection_data;
	private boolean connection_ping;
	private Main main;
	private ReceiveData receiveData;
	private long pingTimeout;
	private long autoStart;
	
	public GroundstationStatemachine() {
	}
	
	public void reset() {
		this.main = Main.__Inactive__;
		this.receiveData = ReceiveData.__Inactive__;
		if (true) {
			long pingTimeout;
			ReceiveData receiveData;
			boolean control_start;
			boolean control_shutdown;
			boolean connection_data;
			boolean connection_ping;
			Main main;
			long autoStart;
			pingTimeout = (1000 * 10);
			receiveData = ReceiveData.__Inactive__;
			control_start = false;
			control_shutdown = false;
			connection_data = false;
			connection_ping = false;
			main = Main.Idle;
			autoStart = 0;
			this.pingTimeout = pingTimeout;
			this.receiveData = receiveData;
			this.control_start = control_start;
			this.control_shutdown = control_shutdown;
			this.connection_data = connection_data;
			this.connection_ping = connection_ping;
			this.main = main;
			this.autoStart = autoStart;
		}
	}
	
	public void setControl_start(boolean control_start) {
		this.control_start = control_start;
	}
	
	public boolean getControl_start() {
		return control_start;
	}
	
	public void setControl_shutdown(boolean control_shutdown) {
		this.control_shutdown = control_shutdown;
	}
	
	public boolean getControl_shutdown() {
		return control_shutdown;
	}
	
	public void setConnection_data(boolean connection_data) {
		this.connection_data = connection_data;
	}
	
	public boolean getConnection_data() {
		return connection_data;
	}
	
	public void setConnection_ping(boolean connection_ping) {
		this.connection_ping = connection_ping;
	}
	
	public boolean getConnection_ping() {
		return connection_ping;
	}
	
	public void setMain(Main main) {
		this.main = main;
	}
	
	public Main getMain() {
		return main;
	}
	
	public void setReceiveData(ReceiveData receiveData) {
		this.receiveData = receiveData;
	}
	
	public ReceiveData getReceiveData() {
		return receiveData;
	}
	
	public void setPingTimeout(long pingTimeout) {
		this.pingTimeout = pingTimeout;
	}
	
	public long getPingTimeout() {
		return pingTimeout;
	}
	
	public void setAutoStart(long autoStart) {
		this.autoStart = autoStart;
	}
	
	public long getAutoStart() {
		return autoStart;
	}
	
	public void runCycle() {
		clearOutEvents();
		signalTimePassing();
		changeState();
		clearInEvents();
	}
	
	private void signalTimePassing() {
		if (pingTimeout == 0) {
			pingTimeout = -1;
		}
		if (autoStart == 0) {
			autoStart = -1;
		}
	}
	
	private void changeState() {
		if ((((!(((this.main == Main.Operation) && ((1000 * 10) <= this.pingTimeout))) && !(((this.main == Main.Operation) && (this.control_shutdown == true)))) && (((this.main == Main.Operation) && (this.receiveData == ReceiveData.Waiting)) && (this.connection_data == true))) && (this.receiveData == ReceiveData.Waiting))) {
			ReceiveData receiveData;
			receiveData = ReceiveData.Waiting;
			this.receiveData = receiveData;
		}
		else if
		(((((this.main == Main.Idle) && ((1000 * 30) <= this.autoStart))) && (this.main == Main.Idle))) {
			Main main;
			ReceiveData receiveData;
			boolean connection_ping;
			long pingTimeout;
			main = Main.Operation;
			receiveData = ReceiveData.Waiting;
			connection_ping = true;
			pingTimeout = 0;
			this.main = main;
			this.receiveData = receiveData;
			this.connection_ping = connection_ping;
			this.pingTimeout = pingTimeout;
		}
		else if
		((((((this.main == Main.Operation) && ((1000 * 10) <= this.pingTimeout))) && (this.main == Main.Operation)) && (this.receiveData == ReceiveData.Waiting))) {
			Main main;
			ReceiveData receiveData;
			boolean connection_ping;
			long pingTimeout;
			main = Main.Operation;
			receiveData = ReceiveData.Waiting;
			connection_ping = true;
			pingTimeout = 0;
			this.main = main;
			this.receiveData = receiveData;
			this.connection_ping = connection_ping;
			this.pingTimeout = pingTimeout;
		}
		else if
		((((((this.main == Main.Operation) && (this.control_shutdown == true))) && (this.main == Main.Operation)) && (this.receiveData == ReceiveData.Waiting))) {
			ReceiveData receiveData;
			Main main;
			long autoStart;
			receiveData = ReceiveData.__Inactive__;
			main = Main.Idle;
			autoStart = 0;
			this.receiveData = receiveData;
			this.main = main;
			this.autoStart = autoStart;
		}
		else if
		(((((this.main == Main.Idle) && (this.control_start == true))) && (this.main == Main.Idle))) {
			Main main;
			ReceiveData receiveData;
			boolean connection_ping;
			long pingTimeout;
			main = Main.Operation;
			receiveData = ReceiveData.Waiting;
			connection_ping = true;
			pingTimeout = 0;
			this.main = main;
			this.receiveData = receiveData;
			this.connection_ping = connection_ping;
			this.pingTimeout = pingTimeout;
		}
	}
	
	private void clearOutEvents() {
		connection_ping = false;
	}
	
	private void clearInEvents() {
		control_start = false;
		control_shutdown = false;
		connection_data = false;
	}
	
	@Override
	public String toString() {
		return
			"control_start = " + control_start + System.lineSeparator() +
			"control_shutdown = " + control_shutdown + System.lineSeparator() +
			"connection_data = " + connection_data + System.lineSeparator() +
			"connection_ping = " + connection_ping + System.lineSeparator() +
			"main = " + main + System.lineSeparator() +
			"receiveData = " + receiveData + System.lineSeparator() +
			"pingTimeout = " + pingTimeout + System.lineSeparator() +
			"autoStart = " + autoStart
		;
	}
	
}
