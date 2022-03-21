import
"controller" component Controller
@AllowedWaiting 0 .. 1
scenario DelayAlone [
	{
		hot delay (100)
	}
	{
		hot receives PoliceInterrupt.police
	}
]