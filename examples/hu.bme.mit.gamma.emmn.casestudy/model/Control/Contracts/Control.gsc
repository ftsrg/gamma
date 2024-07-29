package control

import "Interfaces/Interfaces.gcd"

import "Control/Controller.gcd"

component Controller

scenario OrchestratorEmmnActivation [
	{ cold receives OperationsManager.initTracking }
	
	{ hot sends SatelliteManager.getDataSat	}
	{ cold receives SatelliteManager.getDataSatReturn }
	
	{ hot sends MQTT.trackingActivation }
	{ cold receives MQTT.trackingActivationReturn }
	{ hot sends MQTT.radioActivation }
	{ cold receives MQTT.radioActivationReturn }
	{ hot sends MQTT.remoteActivation }
	{ cold receives MQTT.remoteActivationReturn }
]
