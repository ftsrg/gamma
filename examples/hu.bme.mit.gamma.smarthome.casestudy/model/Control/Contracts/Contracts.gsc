import "Interfaces/Constants.gcd"
import "Interfaces/Interfaces.gcd"

import "Control/Controller.gcd"

component Controller

//scenario SwitchLights [
//	variable isOn : integer;
//	{
//		cold receives InIllumination.lightSwitch
//		assign isOn = InIllumination.lightSwitch::on
//	}
//	{
//		hot sends OutIllumination.lightSwitch
//		check(OutIllumination.lightSwitch::on == isOn)
//	}
//]

scenario MotionIncreasesIllumination [
//	variable personCount : integer;
//	variable brightness : integer;
	{
		cold receives Camera.motion
//		check Illumination.dim::brightness == brightness
	}
	{
		cold receives Camera.personPresence
//		assign personCount := Camera.personPresence::count
		
	}
	alternative {
		check personCount > 10
	} or {
		check personCount <= 10
	}
	{
		hot sends Illumination.dim
		hot sends Illumination.dim // TODO match assign and check order in mapping
//		check Illumination.dim::brightness == brightness
//		assign brightness := calculateBrightness(personCount)
	}
	{
		hot sends Illumination.dim
//		check Illumination.dim::brightness == brightness
//		assign brightness := brightness - BRIGHTNESS_DELTA
	}
]

scenario BrightnessValue [
	alternative { 
		{
			cold receives Camera.motion
//			check Camera.motion::on == false
		}
	} or {
		{
			cold receives MotionDetector.motion
//			check MotionDetector.motion::on == false
		}
	}
	{
		hot sends Illumination.switchLight
//		check Illumination.switchLight::on == false
	}
]