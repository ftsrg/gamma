import "Interfaces/Interfaces.gcd"
import "Control/Controller.gcd"

component Controller

scenario SwitchLights [
	variable isOn : integer;
	{
		cold receives InIllumination.lightSwitch
		assign isOn = InIllumination.lightSwitch::on
	}
	{
		hot sends OutIllumination.lightSwitch
		check(OutIllumination.lightSwitch::on == isOn)
	}
]