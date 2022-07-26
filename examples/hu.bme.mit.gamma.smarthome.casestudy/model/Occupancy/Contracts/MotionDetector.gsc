import "Interfaces/Constants.gcd"
import "Interfaces/Interfaces.gcd"

import "Control/Controller.gcd"

component Controller

//scenario DelayThenMotion [
//	call MotionThenDelay()
//] 
//
//scenario MotionThenMotion [
//	call MotionThenDelayThenMotion()
//]

scenario MaximumRelayedMotion [
	loop (MAXIMUM_RELAYED_MOTION_COUNT) {
		{
			cold receives MotionDetector.motion
		}
		{
			cold delay (1 .. EXPECTED_DELAY_TIME * 1000)
		}
	}
	{
		hot sends Defense.attackSensed
	}
]