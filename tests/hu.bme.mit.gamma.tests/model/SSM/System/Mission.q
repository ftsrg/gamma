/*
satellite: WaitingPing-->Transmitting
*/
E<> transitionId == 1 && isStable
/*
satellite: Consuming-->Consuming
*/
E<> transitionId == 2 && isStable
/*
station: Waiting-->Waiting
*/
E<> transitionId == 3 && isStable
/*
satellite: NotRecharging-->Recharging
*/
E<> transitionId == 4 && isStable
/*
station: Idle-->Operation
*/
E<> transitionId == 5 && isStable
/*
station: Operation-->Operation
*/
E<> transitionId == 6 && isStable
/*
station: Idle-->Operation
*/
E<> transitionId == 7 && isStable
/*
satellite: Transmitting-->WaitingPing
*/
E<> transitionId == 8 && isStable
/*
satellite: Recharging-->NotRecharging
*/
E<> transitionId == 9 && isStable
/*
satellite: Sending-->Sending
*/
E<> transitionId == 10 && isStable
/*
station: Operation-->Idle
*/
E<> transitionId == 11 && isStable
/*
satellite: Recharging-->Recharging
*/
E<> transitionId == 12 && isStable
/*
satellite: Transmitting-->WaitingPing
*/
E<> transitionId == 13 && isStable
