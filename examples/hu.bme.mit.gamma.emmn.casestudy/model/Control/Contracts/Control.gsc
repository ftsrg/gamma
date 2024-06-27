package control

import "Interfaces/Interfaces.gcd"

import "Control/Controller.gcd"

component Controller

// Context-dependent - no result
scenario S1 [
	{
		cold receives Input.a
	}
	{
		cold receives Input.b
	}
	{
		hot sends Output.x
	}
]
