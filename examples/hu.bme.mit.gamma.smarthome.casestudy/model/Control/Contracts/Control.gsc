package control

import "Interfaces/Constants.gcd"
import "Interfaces/Interfaces.gcd"

import "Control/Controller.gcd"

component Controller

// Context-dependent - no result
scenario S1MotionThenDelay initial outputs [
	hot sends Ventilation.switchVentilation
	hot sends Ventilation.ventilate
	check Ventilation.switchVentilation::on and Ventilation.ventilate::level == BASE_VENTILATION
] [
	{
		cold receives MotionDetector.motion
	}
	{
		delay (TIMEOUT_TIME * 1000)
	}
	// Internal event transmission
	{
		hot sends Ventilation.switchVentilation
		check Ventilation.switchVentilation::on == false
	}
]

// Context-dependent - deliberately unsatisfied or no result
scenario S2MotionThenMotionThenVentilation  initial outputs [
	hot sends Ventilation.switchVentilation
	hot sends Ventilation.ventilate
	check Ventilation.switchVentilation::on and Ventilation.ventilate::level == BASE_VENTILATION
] [
	{
		cold receives MotionDetector.motion
	}
	// Internal event transmission
	{
		cold receives MotionDetector.motion
	}
	{
		delay (1 .. 4001)
		hot sends Ventilation.switchVentilation
		hot sends Ventilation.ventilate
		check Ventilation.switchVentilation::on
	}
]