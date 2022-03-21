import "controller" 
component Controller
scenario PoliceInterruptionResponse [
	{
		hot sends PriorityPolice.police
		hot sends SecondaryPolice.police
	}
]

scenario PoliceInterruption(loopMax : integer) [
	{
		cold delay (2000)
	}
	loop (1 .. loopMax) {
		{
			hot receives PoliceInterrupt.police
		}
		call PoliceInterruptionResponse
	}
]
	