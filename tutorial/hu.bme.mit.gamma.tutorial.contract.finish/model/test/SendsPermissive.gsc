import "controller"
component Controller

//@Strict
@AllowedWaiting 0 .. 1
scenario SendsPermissive [
	{
		hot sends PriorityPolice.police
	}
]