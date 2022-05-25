package contractsPackage import
"crossroad" import
"Interfaces" component Crossroads
const one : integer := 1 
@AllowedWaiting 0 .. 1
scenario Blinking 
var variable1 : integer := 0 
initial outputs [
	hot sends priorityOutput.displayYellow 
	hot sends secondaryOutput.displayYellow
	hot sends secondaryOutput.displayYellow2
	check one == variable1 + 1
	assign variable1 :=secondaryOutput.displayYellow2::outEventName
]
[
	{
		hot sends priorityOutput.displayNone
		hot sends secondaryOutput.displayNone
		hot delay (500 .. 501)
		check 0 < variable1 and variable1 < 10
		assign variable1 := 1 + one * 3
	}
	{
		hot sends priorityOutput.displayYellow
		hot sends secondaryOutput.displayYellow
		hot delay (500 .. 501)
	}
	{
		hot receives police.police2(variable1)
		check police.police2::Name > 1
		assign variable1 := police.police2::Name
	}
]

@Strict
@AllowedWaiting 0 .. 1
scenario Init initial outputs [
	cold sends priorityOutput.displayRed cold sends secondaryOutput.displayRed
]
[
	{
		hot sends priorityOutput.displayGreen
	}
]

@AllowedWaiting 0 .. 1
scenario Normal initial outputs [
	hot sends priorityOutput.displayYellow
]
[
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