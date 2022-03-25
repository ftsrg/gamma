import
"controller" component Controller
@AllowedWaiting 0 .. 1
scenario NegBlockSendsPermissive [
	negate {
		hot sends PriorityControl.toggle
		hot sends SecondaryControl.toggle
	}
]