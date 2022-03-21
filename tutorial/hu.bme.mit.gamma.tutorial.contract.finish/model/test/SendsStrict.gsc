import "controller"
component Controller

@Strict
@AllowedWaiting 0 .. 1
scenario SendsStrict [
	{
		hot sends PriorityPolice.police
	}
]