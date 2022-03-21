import "controller" 
component Controller 
@AllowedWaiting 0 .. 1
scenario PoliceBehaviour [
	{
		cold delay (2000)
	}
	{
		cold receives PoliceInterrupt.police
	}
	{
		hot sends PriorityPolice.police
		hot sends SecondaryPolice.police
	}
]

scenario sortTest [
	alternative {
		{
			hot sends PriorityPolice.police
			hot sends SecondaryPolice.police
		}
		{
			hot sends PriorityControl.toggle
		}
	} or {
		{
			hot sends SecondaryPolice.police
			hot sends PriorityPolice.police
		}
		{
			hot sends SecondaryPolice.police
		}
	}
	{
		hot sends PriorityControl.toggle
	}
]

scenario loopTest [
	loop (2 .. 4) {
		{
			hot sends PriorityPolice.police
			hot sends SecondaryPolice.police
		}
		{
			hot sends PriorityControl.toggle
		}
	}
	{
		hot sends PriorityControl.toggle
	}
]

scenario optTest [
	alternative {
		{
			cold receives PoliceInterrupt.police
		}
	} or {
		{
			cold receives PoliceInterrupt.police
		}
		optional {
			{
				hot sends PriorityPolice.police
				hot sends SecondaryPolice.police
			}
			{
				hot sends PriorityControl.toggle
			}
		}
	}
	{
		hot sends PriorityControl.toggle
	}
	{
		hot receives PoliceInterrupt.police
	}
	{
		hot sends PriorityPolice.police
		hot sends SecondaryPolice.police
	}
]