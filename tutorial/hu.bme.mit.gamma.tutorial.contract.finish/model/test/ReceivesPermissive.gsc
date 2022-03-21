import "controller"
component Controller

@AllowedWaiting 0 .. 1
scenario ReceivesPermissive [
	{
		hot receives PoliceInterrupt.police
	}
]