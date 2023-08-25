package ventilation

import "Interfaces/Constants.gcd"
import "Interfaces/Interfaces.gcd"

import "Control/Controller.gcd"

component Controller

// Context-independent
scenario S8MotionThenDelayThenMotion [
	{
		cold receives Motion.motion
		check !Motion.motion::on
	}
	{
		hot sends Ventilation.switchVentilation
		check !Ventilation.switchVentilation::on
	}
	{
		cold receives Motion.motion
		check Motion.motion::on
	}
	{
		hot sends Ventilation.switchVentilation
		hot sends Ventilation.ventilate
		check Ventilation.switchVentilation::on and Ventilation.ventilate::level == BASE_VENTILATION // Decomment to check violation: // + 25
	}
]

// Context-independent
scenario S9Delay initial outputs [
	hot sends Ventilation.switchVentilation
	hot sends Ventilation.ventilate
	check Ventilation.switchVentilation::on and Ventilation.ventilate::level == BASE_VENTILATION
] [
	{
		delay (SWITCH_OFF_TIME * 1000)
	}
	{
		hot sends Ventilation.switchVentilation
		check !Ventilation.switchVentilation::on // Negate it for violation
	}
]

// Context-independent
scenario S10DelayThenMotion initial outputs [
	hot sends Ventilation.switchVentilation
	hot sends Ventilation.ventilate
	check Ventilation.switchVentilation::on and Ventilation.ventilate::level == BASE_VENTILATION
] [
	call S9Delay
	{
		cold receives Motion.motion
		check Motion.motion::on
	}
	{
		hot sends Ventilation.switchVentilation
		hot sends Ventilation.ventilate
		check Ventilation.switchVentilation::on and Ventilation.ventilate::level == BASE_VENTILATION // Decomment to check violation: // + 25 
	}
]

// Context-independent
scenario S11MotionThenPersonCountThenDelay
	var personCount : integer
	var ventilationLevel : integer [
	{
		cold receives Motion.motion
		check Motion.motion::on
	}
	optional {
		{
			cold sends Ventilation.switchVentilation
			check Ventilation.switchVentilation::on
		}
	}
	{
//		cold delay (FIRST_VENTILATION_CHANGE_TIME + 1 .. (SWITCH_OFF_TIME / 2) * 1000) // Check loop edge in the model
		cold receives Motion.personPresence
		check (0 <= Motion.personPresence::count)
			/* */ and Motion.personPresence::count < 5 // To check input values
		assign personCount := Motion.personPresence::count
	}
	{
		hot sends Ventilation.ventilate
		check Ventilation.ventilate::level ==
			calculateVentilationLevel(personCount)
		assign ventilationLevel := Ventilation.ventilate::level
	}
	{
		delay (FIRST_VENTILATION_CHANGE_TIME * 1000)
		check ventilationLevel > 60 // To demonstrate input values for violations
	}
	{
		hot sends Ventilation.ventilate
		check Ventilation.ventilate::level == ventilationLevel
	}
	{
		delay (VENTILATION_CHANGE_TIME * 1000)
	}
	{
		hot sends Ventilation.ventilate
		check Ventilation.ventilate::level ==
			max(ventilationLevel - VENTILATION_DELTA, BASE_VENTILATION) // Decomment to check violation: // + 25 
	}
]