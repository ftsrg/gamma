import "controller"
component Controller

//@Strict
@AllowedWaiting 0 .. 1
scenario PoliceBehaviour [
	{
		cold delay(2000)
	}
	{
		cold receives PoliceInterrupt.police
	} 
	{
		hot sends PriorityPolice.police
		hot sends SecondaryPolice.police
	}

]