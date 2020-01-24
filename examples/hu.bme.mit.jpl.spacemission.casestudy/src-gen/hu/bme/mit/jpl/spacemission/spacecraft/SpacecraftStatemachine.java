package hu.bme.mit.jpl.spacemission.spacecraft;

public class SpacecraftStatemachine {
	public enum Communication {__Inactive__, WaitingPing, Transmitting}
	public enum Battery {__Inactive__, NotRecharging, Recharging}
	public enum SendData {__Inactive__, Sending}
	public enum ConsumePower {__Inactive__, Consuming}
	private boolean connection_ping;
	private boolean connection_data;
	private Communication communication;
	private Battery battery;
	private SendData sendData;
	private ConsumePower consumePower;
	private long data;
	private long batteryVariable;
	private boolean recharging;
	private long rechargeTimeout;
	private long consumeTimeout;
	private long transmitTimeout;
	
	public SpacecraftStatemachine() {
	}
	
	public void reset() {
		this.communication = Communication.__Inactive__;
		this.battery = Battery.__Inactive__;
		this.sendData = SendData.__Inactive__;
		this.consumePower = ConsumePower.__Inactive__;
		if (true) {
			long batteryVariable;
			long data;
			long rechargeTimeout;
			long consumeTimeout;
			long transmitTimeout;
			SendData sendData;
			ConsumePower consumePower;
			boolean connection_ping;
			boolean connection_data;
			Communication communication;
			Battery battery;
			boolean recharging;
			batteryVariable = 100;
			data = 100;
			rechargeTimeout = (1000 * 10);
			consumeTimeout = (1000 * 1);
			transmitTimeout = 1500;
			sendData = SendData.__Inactive__;
			consumePower = ConsumePower.__Inactive__;
			connection_ping = false;
			connection_data = false;
			communication = Communication.WaitingPing;
			battery = Battery.NotRecharging;
			recharging = false;
			this.batteryVariable = batteryVariable;
			this.data = data;
			this.rechargeTimeout = rechargeTimeout;
			this.consumeTimeout = consumeTimeout;
			this.transmitTimeout = transmitTimeout;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.connection_ping = connection_ping;
			this.connection_data = connection_data;
			this.communication = communication;
			this.battery = battery;
			this.recharging = recharging;
		}
	}
	
	public void setConnection_ping(boolean connection_ping) {
		this.connection_ping = connection_ping;
	}
	
	public boolean getConnection_ping() {
		return connection_ping;
	}
	
	public void setConnection_data(boolean connection_data) {
		this.connection_data = connection_data;
	}
	
	public boolean getConnection_data() {
		return connection_data;
	}
	
	public void setCommunication(Communication communication) {
		this.communication = communication;
	}
	
	public Communication getCommunication() {
		return communication;
	}
	
	public void setBattery(Battery battery) {
		this.battery = battery;
	}
	
	public Battery getBattery() {
		return battery;
	}
	
	public void setSendData(SendData sendData) {
		this.sendData = sendData;
	}
	
	public SendData getSendData() {
		return sendData;
	}
	
	public void setConsumePower(ConsumePower consumePower) {
		this.consumePower = consumePower;
	}
	
	public ConsumePower getConsumePower() {
		return consumePower;
	}
	
	public void setRechargeTimeout(long rechargeTimeout) {
		this.rechargeTimeout = rechargeTimeout;
	}
	
	public long getRechargeTimeout() {
		return rechargeTimeout;
	}
	
	public void setConsumeTimeout(long consumeTimeout) {
		this.consumeTimeout = consumeTimeout;
	}
	
	public long getConsumeTimeout() {
		return consumeTimeout;
	}
	
	public void setTransmitTimeout(long transmitTimeout) {
		this.transmitTimeout = transmitTimeout;
	}
	
	public long getTransmitTimeout() {
		return transmitTimeout;
	}
	
	public void setData(long data) {
		this.data = data;
	}
	
	public long getData() {
		return data;
	}
	
	public void setBatteryVariable(long batteryVariable) {
		this.batteryVariable = batteryVariable;
	}
	
	public long getBatteryVariable() {
		return batteryVariable;
	}
	
	public void setRecharging(boolean recharging) {
		this.recharging = recharging;
	}
	
	public boolean getRecharging() {
		return recharging;
	}
	
	public void runCycle() {
		clearOutEvents();
		signalTimePassing();
		changeState();
		clearInEvents();
	}
	
	private void signalTimePassing() {
		if (rechargeTimeout == 0) {
			rechargeTimeout = -1;
		}
		if (consumeTimeout == 0) {
			consumeTimeout = -1;
		}
		if (transmitTimeout == 0) {
			transmitTimeout = -1;
		}
	}
	
	private void changeState() {
		if ((((((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && (this.sendData == SendData.Sending)) && ((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.NotRecharging) && (((1000 * 1) <= 0) && ((this.batteryVariable - 1) < 80))))) && (this.battery == Battery.NotRecharging))) {
			long data;
			boolean connection_data;
			SendData sendData;
			long transmitTimeout;
			long batteryVariable;
			ConsumePower consumePower;
			long consumeTimeout;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			data = (this.data - 1);
			connection_data = true;
			sendData = SendData.Sending;
			transmitTimeout = 0;
			batteryVariable = (this.batteryVariable - 1);
			consumePower = ConsumePower.Consuming;
			consumeTimeout = 0;
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.data = data;
			this.connection_data = connection_data;
			this.sendData = sendData;
			this.transmitTimeout = transmitTimeout;
			this.batteryVariable = batteryVariable;
			this.consumePower = consumePower;
			this.consumeTimeout = consumeTimeout;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		((((((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && (this.sendData == SendData.Sending)) && ((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && ((this.batteryVariable - 1) == 100))))) && (this.battery == Battery.Recharging))) {
			long data;
			boolean connection_data;
			SendData sendData;
			long transmitTimeout;
			long batteryVariable;
			ConsumePower consumePower;
			long consumeTimeout;
			Battery battery;
			boolean recharging;
			data = (this.data - 1);
			connection_data = true;
			sendData = SendData.Sending;
			transmitTimeout = 0;
			batteryVariable = (this.batteryVariable - 1);
			consumePower = ConsumePower.Consuming;
			consumeTimeout = 0;
			battery = Battery.NotRecharging;
			recharging = false;
			this.data = data;
			this.connection_data = connection_data;
			this.sendData = sendData;
			this.transmitTimeout = transmitTimeout;
			this.batteryVariable = batteryVariable;
			this.consumePower = consumePower;
			this.consumeTimeout = consumeTimeout;
			this.battery = battery;
			this.recharging = recharging;
		}
		else if
		((((((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && (this.sendData == SendData.Sending)) && ((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && ((this.batteryVariable - 1) < 100))))) && (this.battery == Battery.Recharging))) {
			long data;
			boolean connection_data;
			SendData sendData;
			long transmitTimeout;
			ConsumePower consumePower;
			long consumeTimeout;
			long batteryVariable;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			data = (this.data - 1);
			connection_data = true;
			sendData = SendData.Sending;
			transmitTimeout = 0;
			consumePower = ConsumePower.Consuming;
			consumeTimeout = 0;
			batteryVariable = ((this.batteryVariable - 1) + 1);
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.data = data;
			this.connection_data = connection_data;
			this.sendData = sendData;
			this.transmitTimeout = transmitTimeout;
			this.consumePower = consumePower;
			this.consumeTimeout = consumeTimeout;
			this.batteryVariable = batteryVariable;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		(((((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && (this.sendData == SendData.Sending)) && ((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && (this.consumePower == ConsumePower.Consuming)) && (!((this.battery == Battery.__Inactive__)) && !(((((this.battery == Battery.NotRecharging) && (((1000 * 1) <= 0) && ((this.batteryVariable - 1) < 80)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && ((this.batteryVariable - 1) < 100)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && ((this.batteryVariable - 1) == 100))))))))) {
			long data;
			boolean connection_data;
			SendData sendData;
			long transmitTimeout;
			long batteryVariable;
			ConsumePower consumePower;
			long consumeTimeout;
			data = (this.data - 1);
			connection_data = true;
			sendData = SendData.Sending;
			transmitTimeout = 0;
			batteryVariable = (this.batteryVariable - 1);
			consumePower = ConsumePower.Consuming;
			consumeTimeout = 0;
			this.data = data;
			this.connection_data = connection_data;
			this.sendData = sendData;
			this.transmitTimeout = transmitTimeout;
			this.batteryVariable = batteryVariable;
			this.consumePower = consumePower;
			this.consumeTimeout = consumeTimeout;
		}
		else if
		(((((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && (this.sendData == SendData.Sending)) && (!((this.consumePower == ConsumePower.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40)))))))) && (((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80))))) && (this.battery == Battery.NotRecharging))) {
			long data;
			boolean connection_data;
			SendData sendData;
			long transmitTimeout;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			data = (this.data - 1);
			connection_data = true;
			sendData = SendData.Sending;
			transmitTimeout = 0;
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.data = data;
			this.connection_data = connection_data;
			this.sendData = sendData;
			this.transmitTimeout = transmitTimeout;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		(((((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && (this.sendData == SendData.Sending)) && (!((this.consumePower == ConsumePower.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40)))))))) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))) && (this.battery == Battery.Recharging))) {
			long data;
			boolean connection_data;
			SendData sendData;
			long transmitTimeout;
			Battery battery;
			boolean recharging;
			data = (this.data - 1);
			connection_data = true;
			sendData = SendData.Sending;
			transmitTimeout = 0;
			battery = Battery.NotRecharging;
			recharging = false;
			this.data = data;
			this.connection_data = connection_data;
			this.sendData = sendData;
			this.transmitTimeout = transmitTimeout;
			this.battery = battery;
			this.recharging = recharging;
		}
		else if
		(((((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && (this.sendData == SendData.Sending)) && (!((this.consumePower == ConsumePower.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40)))))))) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100))))) && (this.battery == Battery.Recharging))) {
			long data;
			boolean connection_data;
			SendData sendData;
			long transmitTimeout;
			long batteryVariable;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			data = (this.data - 1);
			connection_data = true;
			sendData = SendData.Sending;
			transmitTimeout = 0;
			batteryVariable = (this.batteryVariable + 1);
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.data = data;
			this.connection_data = connection_data;
			this.sendData = sendData;
			this.transmitTimeout = transmitTimeout;
			this.batteryVariable = batteryVariable;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		((((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && (this.sendData == SendData.Sending)) && (!((this.consumePower == ConsumePower.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40)))))))) && (!((this.battery == Battery.__Inactive__)) && !(((((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))))))) {
			long data;
			boolean connection_data;
			SendData sendData;
			long transmitTimeout;
			data = (this.data - 1);
			connection_data = true;
			sendData = SendData.Sending;
			transmitTimeout = 0;
			this.data = data;
			this.connection_data = connection_data;
			this.sendData = sendData;
			this.transmitTimeout = transmitTimeout;
		}
		else if
		((((((!((this.sendData == SendData.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40)))))))) && ((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.NotRecharging) && (((1000 * 1) <= 0) && ((this.batteryVariable - 1) < 80))))) && (this.battery == Battery.NotRecharging))) {
			long batteryVariable;
			ConsumePower consumePower;
			long consumeTimeout;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			batteryVariable = (this.batteryVariable - 1);
			consumePower = ConsumePower.Consuming;
			consumeTimeout = 0;
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.batteryVariable = batteryVariable;
			this.consumePower = consumePower;
			this.consumeTimeout = consumeTimeout;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		((((((!((this.sendData == SendData.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40)))))))) && ((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && ((this.batteryVariable - 1) == 100))))) && (this.battery == Battery.Recharging))) {
			long batteryVariable;
			ConsumePower consumePower;
			long consumeTimeout;
			Battery battery;
			boolean recharging;
			batteryVariable = (this.batteryVariable - 1);
			consumePower = ConsumePower.Consuming;
			consumeTimeout = 0;
			battery = Battery.NotRecharging;
			recharging = false;
			this.batteryVariable = batteryVariable;
			this.consumePower = consumePower;
			this.consumeTimeout = consumeTimeout;
			this.battery = battery;
			this.recharging = recharging;
		}
		else if
		((((((!((this.sendData == SendData.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40)))))))) && ((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && ((this.batteryVariable - 1) < 100))))) && (this.battery == Battery.Recharging))) {
			ConsumePower consumePower;
			long consumeTimeout;
			long batteryVariable;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			consumePower = ConsumePower.Consuming;
			consumeTimeout = 0;
			batteryVariable = ((this.batteryVariable - 1) + 1);
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.consumePower = consumePower;
			this.consumeTimeout = consumeTimeout;
			this.batteryVariable = batteryVariable;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		(((((!((this.sendData == SendData.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40)))))))) && ((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && (this.consumePower == ConsumePower.Consuming)) && (!((this.battery == Battery.__Inactive__)) && !(((((this.battery == Battery.NotRecharging) && (((1000 * 1) <= 0) && ((this.batteryVariable - 1) < 80)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && ((this.batteryVariable - 1) < 100)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && ((this.batteryVariable - 1) == 100))))))))) {
			long batteryVariable;
			ConsumePower consumePower;
			long consumeTimeout;
			batteryVariable = (this.batteryVariable - 1);
			consumePower = ConsumePower.Consuming;
			consumeTimeout = 0;
			this.batteryVariable = batteryVariable;
			this.consumePower = consumePower;
			this.consumeTimeout = consumeTimeout;
		}
		else if
		(((((!((this.sendData == SendData.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40)))))))) && (!((this.consumePower == ConsumePower.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40)))))))) && (((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80))))) && (this.battery == Battery.NotRecharging))) {
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		(((((!((this.sendData == SendData.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40)))))))) && (!((this.consumePower == ConsumePower.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40)))))))) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))) && (this.battery == Battery.Recharging))) {
			Battery battery;
			boolean recharging;
			battery = Battery.NotRecharging;
			recharging = false;
			this.battery = battery;
			this.recharging = recharging;
		}
		else if
		(((((!((this.sendData == SendData.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40)))))))) && (!((this.consumePower == ConsumePower.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40)))))))) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100))))) && (this.battery == Battery.Recharging))) {
			long batteryVariable;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			batteryVariable = (this.batteryVariable + 1);
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.batteryVariable = batteryVariable;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		((((!((this.sendData == SendData.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40)))))))) && (!((this.consumePower == ConsumePower.__Inactive__)) && !((((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40)))))))) && (!((this.battery == Battery.__Inactive__)) && !(((((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))))))) {
		}
		else if
		((((((((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 40)))) && (this.communication == Communication.Transmitting)) && (this.sendData == SendData.Sending)) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80))))) && (this.battery == Battery.NotRecharging))) {
			SendData sendData;
			ConsumePower consumePower;
			Communication communication;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			sendData = SendData.__Inactive__;
			consumePower = ConsumePower.__Inactive__;
			communication = Communication.WaitingPing;
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.communication = communication;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		((((((((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 40)))) && (this.communication == Communication.Transmitting)) && (this.sendData == SendData.Sending)) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))) && (this.battery == Battery.Recharging))) {
			SendData sendData;
			ConsumePower consumePower;
			Communication communication;
			Battery battery;
			boolean recharging;
			sendData = SendData.__Inactive__;
			consumePower = ConsumePower.__Inactive__;
			communication = Communication.WaitingPing;
			battery = Battery.NotRecharging;
			recharging = false;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.communication = communication;
			this.battery = battery;
			this.recharging = recharging;
		}
		else if
		((((((((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 40)))) && (this.communication == Communication.Transmitting)) && (this.sendData == SendData.Sending)) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100))))) && (this.battery == Battery.Recharging))) {
			SendData sendData;
			ConsumePower consumePower;
			Communication communication;
			long batteryVariable;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			sendData = SendData.__Inactive__;
			consumePower = ConsumePower.__Inactive__;
			communication = Communication.WaitingPing;
			batteryVariable = (this.batteryVariable + 1);
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.communication = communication;
			this.batteryVariable = batteryVariable;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		(((((((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 40)))) && (this.communication == Communication.Transmitting)) && (this.sendData == SendData.Sending)) && (this.consumePower == ConsumePower.Consuming)) && (!((this.battery == Battery.__Inactive__)) && !(((((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))))))) {
			SendData sendData;
			ConsumePower consumePower;
			Communication communication;
			sendData = SendData.__Inactive__;
			consumePower = ConsumePower.__Inactive__;
			communication = Communication.WaitingPing;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.communication = communication;
		}
		else if
		((((((((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && ((1500 <= this.transmitTimeout) && ((this.data <= 1) || (this.batteryVariable < 40))))) && (this.communication == Communication.Transmitting)) && (this.sendData == SendData.Sending)) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80))))) && (this.battery == Battery.NotRecharging))) {
			SendData sendData;
			ConsumePower consumePower;
			Communication communication;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			sendData = SendData.__Inactive__;
			consumePower = ConsumePower.__Inactive__;
			communication = Communication.WaitingPing;
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.communication = communication;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		((((((((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && ((1500 <= this.transmitTimeout) && ((this.data <= 1) || (this.batteryVariable < 40))))) && (this.communication == Communication.Transmitting)) && (this.sendData == SendData.Sending)) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))) && (this.battery == Battery.Recharging))) {
			SendData sendData;
			ConsumePower consumePower;
			Communication communication;
			Battery battery;
			boolean recharging;
			sendData = SendData.__Inactive__;
			consumePower = ConsumePower.__Inactive__;
			communication = Communication.WaitingPing;
			battery = Battery.NotRecharging;
			recharging = false;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.communication = communication;
			this.battery = battery;
			this.recharging = recharging;
		}
		else if
		((((((((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && ((1500 <= this.transmitTimeout) && ((this.data <= 1) || (this.batteryVariable < 40))))) && (this.communication == Communication.Transmitting)) && (this.sendData == SendData.Sending)) && (this.consumePower == ConsumePower.Consuming)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100))))) && (this.battery == Battery.Recharging))) {
			SendData sendData;
			ConsumePower consumePower;
			Communication communication;
			long batteryVariable;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			sendData = SendData.__Inactive__;
			consumePower = ConsumePower.__Inactive__;
			communication = Communication.WaitingPing;
			batteryVariable = (this.batteryVariable + 1);
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.communication = communication;
			this.batteryVariable = batteryVariable;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		(((((((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && ((1500 <= this.transmitTimeout) && ((this.data <= 1) || (this.batteryVariable < 40))))) && (this.communication == Communication.Transmitting)) && (this.sendData == SendData.Sending)) && (this.consumePower == ConsumePower.Consuming)) && (!((this.battery == Battery.__Inactive__)) && !(((((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))))))) {
			SendData sendData;
			ConsumePower consumePower;
			Communication communication;
			sendData = SendData.__Inactive__;
			consumePower = ConsumePower.__Inactive__;
			communication = Communication.WaitingPing;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.communication = communication;
		}
		else if
		(((((((this.communication == Communication.WaitingPing) && ((this.connection_ping == true) && (this.recharging == false)))) && (this.communication == Communication.WaitingPing)) && (((this.battery == Battery.NotRecharging) && (((1000 * 1) <= 0) && (this.batteryVariable < 80))))) && (this.battery == Battery.NotRecharging))) {
			Communication communication;
			SendData sendData;
			ConsumePower consumePower;
			long transmitTimeout;
			long consumeTimeout;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			communication = Communication.Transmitting;
			sendData = SendData.Sending;
			consumePower = ConsumePower.Consuming;
			transmitTimeout = 0;
			consumeTimeout = 0;
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.communication = communication;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.transmitTimeout = transmitTimeout;
			this.consumeTimeout = consumeTimeout;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		(((((((this.communication == Communication.WaitingPing) && ((this.connection_ping == true) && (this.recharging == false)))) && (this.communication == Communication.WaitingPing)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))) && (this.battery == Battery.Recharging))) {
			Communication communication;
			SendData sendData;
			ConsumePower consumePower;
			long transmitTimeout;
			long consumeTimeout;
			Battery battery;
			boolean recharging;
			communication = Communication.Transmitting;
			sendData = SendData.Sending;
			consumePower = ConsumePower.Consuming;
			transmitTimeout = 0;
			consumeTimeout = 0;
			battery = Battery.NotRecharging;
			recharging = false;
			this.communication = communication;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.transmitTimeout = transmitTimeout;
			this.consumeTimeout = consumeTimeout;
			this.battery = battery;
			this.recharging = recharging;
		}
		else if
		(((((((this.communication == Communication.WaitingPing) && ((this.connection_ping == true) && (this.recharging == false)))) && (this.communication == Communication.WaitingPing)) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100))))) && (this.battery == Battery.Recharging))) {
			Communication communication;
			SendData sendData;
			ConsumePower consumePower;
			long transmitTimeout;
			long consumeTimeout;
			long batteryVariable;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			communication = Communication.Transmitting;
			sendData = SendData.Sending;
			consumePower = ConsumePower.Consuming;
			transmitTimeout = 0;
			consumeTimeout = 0;
			batteryVariable = (this.batteryVariable + 1);
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.communication = communication;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.transmitTimeout = transmitTimeout;
			this.consumeTimeout = consumeTimeout;
			this.batteryVariable = batteryVariable;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		((((((this.communication == Communication.WaitingPing) && ((this.connection_ping == true) && (this.recharging == false)))) && (this.communication == Communication.WaitingPing)) && (!((this.battery == Battery.__Inactive__)) && !(((((this.battery == Battery.NotRecharging) && (((1000 * 1) <= 0) && (this.batteryVariable < 80)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))))))) {
			Communication communication;
			SendData sendData;
			ConsumePower consumePower;
			long transmitTimeout;
			long consumeTimeout;
			communication = Communication.Transmitting;
			sendData = SendData.Sending;
			consumePower = ConsumePower.Consuming;
			transmitTimeout = 0;
			consumeTimeout = 0;
			this.communication = communication;
			this.sendData = sendData;
			this.consumePower = consumePower;
			this.transmitTimeout = transmitTimeout;
			this.consumeTimeout = consumeTimeout;
		}
		else if
		((((!((this.communication == Communication.__Inactive__)) && !(((((this.communication == Communication.WaitingPing) && ((this.connection_ping == true) && (this.recharging == false)))) || ((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 40)))) || ((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && ((1500 <= this.transmitTimeout) && ((this.data <= 1) || (this.batteryVariable < 40)))))))) && (((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80))))) && (this.battery == Battery.NotRecharging))) {
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		((((!((this.communication == Communication.__Inactive__)) && !(((((this.communication == Communication.WaitingPing) && ((this.connection_ping == true) && (this.recharging == false)))) || ((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 40)))) || ((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && ((1500 <= this.transmitTimeout) && ((this.data <= 1) || (this.batteryVariable < 40)))))))) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))) && (this.battery == Battery.Recharging))) {
			Battery battery;
			boolean recharging;
			battery = Battery.NotRecharging;
			recharging = false;
			this.battery = battery;
			this.recharging = recharging;
		}
		else if
		((((!((this.communication == Communication.__Inactive__)) && !(((((this.communication == Communication.WaitingPing) && ((this.connection_ping == true) && (this.recharging == false)))) || ((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 40)))) || ((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && ((1500 <= this.transmitTimeout) && ((this.data <= 1) || (this.batteryVariable < 40)))))))) && (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100))))) && (this.battery == Battery.Recharging))) {
			long batteryVariable;
			Battery battery;
			boolean recharging;
			long rechargeTimeout;
			batteryVariable = (this.batteryVariable + 1);
			battery = Battery.Recharging;
			recharging = true;
			rechargeTimeout = 0;
			this.batteryVariable = batteryVariable;
			this.battery = battery;
			this.recharging = recharging;
			this.rechargeTimeout = rechargeTimeout;
		}
		else if
		(((!((this.communication == Communication.__Inactive__)) && !(((((this.communication == Communication.WaitingPing) && ((this.connection_ping == true) && (this.recharging == false)))) || ((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 40)))) || ((!((((this.communication == Communication.Transmitting) && (this.sendData == SendData.Sending)) && ((1500 <= this.transmitTimeout) && ((this.data > 1) && (this.batteryVariable >= 40))))) && !((((this.communication == Communication.Transmitting) && (this.consumePower == ConsumePower.Consuming)) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable >= 40))))) && ((this.communication == Communication.Transmitting) && ((1500 <= this.transmitTimeout) && ((this.data <= 1) || (this.batteryVariable < 40)))))))) && (!((this.battery == Battery.__Inactive__)) && !(((((this.battery == Battery.NotRecharging) && (((1000 * 1) <= this.consumeTimeout) && (this.batteryVariable < 80)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable < 100)))) || (((this.battery == Battery.Recharging) && (((1000 * 10) <= this.rechargeTimeout) && (this.batteryVariable == 100))))))))) {
		}
	}
	
	private void clearOutEvents() {
		connection_data = false;
	}
	
	private void clearInEvents() {
		connection_ping = false;
	}
	
	@Override
	public String toString() {
		return
			"connection_ping = " + connection_ping + System.lineSeparator() +
			"connection_data = " + connection_data + System.lineSeparator() +
			"communication = " + communication + System.lineSeparator() +
			"battery = " + battery + System.lineSeparator() +
			"sendData = " + sendData + System.lineSeparator() +
			"consumePower = " + consumePower + System.lineSeparator() +
			"rechargeTimeout = " + rechargeTimeout + System.lineSeparator() +
			"consumeTimeout = " + consumeTimeout + System.lineSeparator() +
			"transmitTimeout = " + transmitTimeout + System.lineSeparator() +
			"data = " + data + System.lineSeparator() +
			"batteryVariable = " + batteryVariable + System.lineSeparator() +
			"recharging = " + recharging
		;
	}
	
}
