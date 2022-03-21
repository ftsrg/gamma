import
"controller" component Controller
@AllowedWaiting 0 .. 1
scenario Optional [
	optional {
		{
			hot receives PoliceInterrupt.police
		}
	}
	{
		hot sends PriorityControl.toggle
	}
]