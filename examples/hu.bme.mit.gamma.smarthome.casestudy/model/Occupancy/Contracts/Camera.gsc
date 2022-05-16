import "Interfaces/Constants.gcd"
import "Interfaces/Interfaces.gcd"

import "Control/Controller.gcd"

component Controller

scenario DelayThenMotion [
	{
		cold delay (TIMEOUT_TIME * 1000)
	}
	{
		cold receives Camera.motion
	}
	{
		hot sends Motion.motion // FIXME introduce separate ports for this
	}
]

scenario MotionThenMotion [
	{
		cold receives Camera.motion
	}
	{
		cold delay (TIMEOUT_TIME / 2 * 1000)
	}
	{
		cold receives Camera.motion
	}
	{
		negate hot sends Motion.motion // FIXME introduce separate ports for this
	}
]

scenario DelayThenMotionThenPersonPresence [
//	var lastCount : integer
	call DelayThenMotion
	{
		cold receives Camera.personPresence
//		check Camera.personPresence::count > 0
//		assign lastCount := Camera.personPresence::count
	}
	{
		hot sends Motion.personPresence(lastCount)
	}
	{
		cold receives Camera.personPresence
//		assign lastCount := Camera.personPresence::count
	}
	optional {
		{
			hot sends Motion.personPresence(lastCount)
		}
	}
]