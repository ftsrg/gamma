/*
slp: SLP_Acquisition_Experiment-->SLP_Receive
*/
E<> transitionId == 1 && isStable
/*
slp: SLP_Receive-->SLP_Send
*/
E<> transitionId == 2 && isStable
/*
obc: OBC_IDLE-->OBC_SEND
*/
E<> transitionId == 3 && isStable
/*
obc: OBC_Write-->OBC_Receive
*/
E<> transitionId == 4 && isStable
/*
obc: OBC_Receive-->OBC_Write
*/
E<> transitionId == 5 && isStable
/*
obc: OBC_SEND-->OBC_Receive
*/
E<> transitionId == 6 && isStable
/*
slp: SLP_Send-->SLP_Receive
*/
E<> transitionId == 7 && isStable
/*
slp: SLP_Receive-->SLP_Send
*/
E<> transitionId == 8 && isStable
/*
slp: SLP_Read_Experiment-->SLP_Send
*/
E<> transitionId == 9 && isStable
/*
slp: SLP_Send-->SLP_Acquisition_Experiment
*/
E<> transitionId == 10 && isStable
/*
obc: OBC_IDLE-->OBC_SEND
*/
E<> transitionId == 11 && isStable
/*
obc: OBC_Receive-->OBC_IDLE
*/
E<> transitionId == 12 && isStable
/*
slp: SLP_ON-->SLP_Receive
*/
E<> transitionId == 13 && isStable
/*
obc: OBC_IDLE-->OBC_SEND
*/
E<> transitionId == 14 && isStable
/*
slp: SLP_Send-->SLP_Read_Experiment
*/
E<> transitionId == 15 && isStable
/*
slp: SLP_Receive-->SLP_Send
*/
E<> transitionId == 16 && isStable
/*
obc: OBC_Receive-->OBC_IDLE
*/
E<> transitionId == 17 && isStable
