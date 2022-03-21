import "controller" 
component Controller
@Strict
@AllowedWaiting 0 .. 1
scenario exampleScenario [
	{
		cold receives PoliceInterrupt.police
	}
	{
		hot sends PriorityPolice.police
		hot sends SecondaryPolice.police
	}
	{
		hot delay (500)
	}
	optional {
		{
			cold receives PoliceInterrupt.police
		}
	}
	alternative {
		{
			hot sends PriorityControl.toggle
		}
	} or {
		{
			hot sends SecondaryControl.toggle
		}
	}
	loop (1 .. 10) {
		{
			cold delay (500 .. 500)
		}
		{
			hot sends PriorityPolice.police
			hot sends SecondaryPolice.police
		}
	}
	unordered {
		{
			hot sends PriorityControl.toggle
		}
	} and {
		{
			hot sends SecondaryControl.toggle
		}
	}
	parallel {
		{
			hot sends PriorityControl.toggle
		}
	} and {
		{
			hot sends SecondaryControl.toggle
		}
	}
]