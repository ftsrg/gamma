import
"controller" component Controller
@AllowedWaiting 0 .. 1
scenario Loop [
	loop (1 .. 2) {
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