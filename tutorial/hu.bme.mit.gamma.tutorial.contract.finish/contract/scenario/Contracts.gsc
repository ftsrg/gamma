package contracts

import  "/contract/adaptive/Crossroads.gcd"

component Crossroads

//// Do not modify these scenarios!

@Strict
@AllowedWaiting 0 .. 1
scenario Blinking initial outputs [
	hot sends priorityOutput.displayYellow
	hot sends secondaryOutput.displayYellow
] [
//	loop (1 .. 2) {
	{
		hot sends priorityOutput.displayNone
		hot sends secondaryOutput.displayNone
		delay (500)
	}
	{
		hot sends priorityOutput.displayYellow
		hot sends secondaryOutput.displayYellow
		delay (500)
	}
//	}
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

@Strict
@AllowedWaiting 0 .. 1
scenario Normal initial outputs [
	hot sends priorityOutput.displayYellow
] [
	{
		delay (1000)
		hot sends priorityOutput.displayRed
		hot sends secondaryOutput.displayGreen
	}
	{
		delay (2000)
		hot sends secondaryOutput.displayYellow
	}
	{
		delay (1000)
		hot sends secondaryOutput.displayRed
		hot sends priorityOutput.displayGreen
	}
	{
		delay (2000)
		hot sends priorityOutput.displayYellow
	}
]