import "controller" 
component Controller
@AllowedWaiting 0 .. 1
scenario DelayWithReceives [
	{
		hot delay (100)
		hot receives PoliceInterrupt.police
	}
]