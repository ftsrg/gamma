import "controller"
component Controller

@Strict
@AllowedWaiting 0 .. 1
scenario ReceivesStrict [
	{
		hot receives PoliceInterrupt.police
	}
]