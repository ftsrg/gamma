import
"controller" component Controller
@AllowedWaiting 0 .. 1
scenario Alternative [
	alternative {
		{
			hot receives PoliceInterrupt.police
		}
	} or {
		{
			hot receives PoliceInterrupt.police
		}
		{
			hot receives PoliceInterrupt.police
		}
	}
	{
		hot sends PriorityControl.toggle
	}
]