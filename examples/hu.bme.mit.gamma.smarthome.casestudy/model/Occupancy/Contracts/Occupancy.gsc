package occupancy

import "Interfaces/Constants.gcd"
import "Interfaces/Interfaces.gcd"

import "Control/Controller.gcd"

component Controller

// Context-independent
scenario S3DelayThenMotions [
	{
		delay (TIMEOUT_TIME * 1000)
	}
	{
		cold receives MotionDetector.motion 
	}
	{
		hot sends Motion.motion
	}
]

// Context-independent
scenario S4MotionThenMotion [
	{
		cold receives MotionDetector.motion
	}
	{
		delay (1 .. min(TEMPORARILY_IDLE_TIME, TIMEOUT_TIME) * 1000)
		cold receives MotionDetector.motion
	}
	{
		negate hot sends Motion.motion
	}
]

// Context-independent - now unsatisfied deliberately
scenario S5MotionThenTooEarlyMotion [
	{
		cold receives MotionDetector.motion
	}
	{
		cold sends Motion.motion
	}
	{
		cold receives MotionDetector.motion
	}
	{
		hot sends Motion.motion
		delay (1 .. 4001)
	}
]

// Context-independent
scenario S6DelayThenMotionThenPersonPresence
	var lastCount : integer [
	call S3DelayThenMotions
	{
		cold receives Camera.personPresence
		check Camera.personPresence::count > 0 and Camera.personPresence::count < 10 /* For input value */
		assign lastCount := Camera.personPresence::count
	}
	{
		hot sends Motion.personPresence(lastCount)
	}
	alternative {
		{
			cold receives Camera.personPresence
			check Camera.personPresence::count > 0 and Camera.personPresence::count < 10 /* For input value */ and
				BASE_GRANULARITY /* Contextless mode */ <= calculateDifference(Camera.personPresence::count, lastCount)
			assign lastCount := Camera.personPresence::count
		}
		{
			hot sends Motion.personPresence(lastCount) // Change to a high value e.g., 15 for a violation
		}
	} or {
		{
			cold receives Camera.personPresence
			check !(Camera.personPresence::count > 0 and Camera.personPresence::count < 10 /* For input value */ and // Exclusive branch
				BASE_GRANULARITY /* Contextless mode */ <= calculateDifference(Camera.personPresence::count, lastCount))
		}
		{
			negate hot sends Motion.personPresence
		}
	}
]

// Context independent if parameter is set
scenario S7MaximumRelayedMotion [
	loop (MAXIMUM_RELAYED_MOTION_COUNT) {
		{
			delay (1 .. EXPECTED_DELAY_TIME * 1000)
			cold receives MotionDetector.motion
		}
	}
	{
		delay (1 .. TEMPORARILY_IDLE_TIME * 1000) // Loop edge is needed
		cold receives MotionDetector.motion
	}
	{
		negate hot sends Motion.motion
	}
]