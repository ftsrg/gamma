import
"controller" component Controller
@AllowedWaiting 0 .. 1
scenario NegSendsStrict [
	{
		negate hot sends PriorityControl.toggle
		hot sends SecondaryControl.toggle
	}
]