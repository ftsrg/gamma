package contractsPackage
import "crossroad"
import "Interfaces"
component Crossroads

const one : integer := 1

@AllowedWaiting 0 .. 1
scenario Blinking initial outputs [
	hot sends priorityOutput.displayYellow
	hot sends secondaryOutput.displayYellow
] 
var variable1 : integer :=0
[
	{
		hot sends priorityOutput.displayNone
		hot sends secondaryOutput.displayNone 
		hot delay (500 .. 501) 
		assign variable1 = 1 + one *3
		check one + variable1 == 1
	}
	{
		hot sends priorityOutput.displayYellow
		hot sends secondaryOutput.displayYellow
		hot delay (500 .. 501)
	}
]

@Strict
@AllowedWaiting 0 .. 1
scenario Init initial outputs [
	cold sends priorityOutput.displayRed
	cold sends secondaryOutput.displayRed
] [
	{
		hot sends priorityOutput.displayGreen
	}
]

@AllowedWaiting 0 .. 1
scenario Normal initial outputs [
		hot sends priorityOutput.displayYellow
] [
	{
		hot delay (1000)
		hot sends priorityOutput.displayRed
		hot sends secondaryOutput.displayGreen
	}
	{
		hot delay (2000)
		hot sends secondaryOutput.displayYellow
	}
	{
		hot delay (1000)
		hot sends secondaryOutput.displayRed
		hot sends priorityOutput.displayGreen
	}
	{
		hot delay (2000)
		hot sends priorityOutput.displayYellow
	}
]