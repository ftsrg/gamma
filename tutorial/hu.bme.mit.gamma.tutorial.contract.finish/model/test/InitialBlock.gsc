import
"controller" component Controller
@AllowedWaiting 0 .. 1
scenario InitialOutputs initial outputs [
	hot sends PriorityControl.toggle
]
[
	{
		hot receives PoliceInterrupt.police
	}
	{
		hot sends PriorityControl.toggle
	}
]