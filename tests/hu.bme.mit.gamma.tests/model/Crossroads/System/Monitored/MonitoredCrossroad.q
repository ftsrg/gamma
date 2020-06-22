/*
crossroad_prior: Green -i-> monitor: Other-->Green
*/
E<> sendingInteractionOfcrossroad_prior == 1 && receivingInteractionOfmonitor == 8 && isStable
/*
crossroad_prior: Green -i-> monitor: Red-->Green
*/
E<> sendingInteractionOfcrossroad_prior == 1 && receivingInteractionOfmonitor == 1 && isStable
/*
crossroad_prior: Green -i-> monitor: Green-->Error
*/
E<> sendingInteractionOfcrossroad_prior == 1 && receivingInteractionOfmonitor == 4 && isStable
/*
crossroad_prior: BlinkingYellow -i-> monitor: Red-->Other
*/
E<> sendingInteractionOfcrossroad_prior == 2 && receivingInteractionOfmonitor == 5 && isStable
/*
crossroad_prior: BlinkingYellow -i-> monitor: Green-->Other
*/
E<> sendingInteractionOfcrossroad_prior == 2 && receivingInteractionOfmonitor == 2 && isStable
/*
crossroad_prior: Yellow -i-> monitor: Red-->Other
*/
E<> sendingInteractionOfcrossroad_prior == 3 && receivingInteractionOfmonitor == 5 && isStable
/*
crossroad_prior: Yellow -i-> monitor: Green-->Other
*/
E<> sendingInteractionOfcrossroad_prior == 3 && receivingInteractionOfmonitor == 2 && isStable
/*
crossroad_prior: Red -i-> monitor: Other-->Red
*/
E<> sendingInteractionOfcrossroad_prior == 0 && receivingInteractionOfmonitor == 7 && isStable
/*
crossroad_prior: Red -i-> monitor: Green-->Red
*/
E<> sendingInteractionOfcrossroad_prior == 0 && receivingInteractionOfmonitor == 0 && isStable
/*
crossroad_prior: Red -i-> monitor: Red-->Error
*/
E<> sendingInteractionOfcrossroad_prior == 0 && receivingInteractionOfmonitor == 6 && isStable
/*
crossroad_prior: Black -i-> monitor: Red-->Other
*/
E<> sendingInteractionOfcrossroad_prior == 4 && receivingInteractionOfmonitor == 9 && isStable
/*
crossroad_prior: Black -i-> monitor: Green-->Other
*/
E<> sendingInteractionOfcrossroad_prior == 4 && receivingInteractionOfmonitor == 3 && isStable
/*
crossroad_controller: Operating-->Operating -i-> crossroad_second: Interrupted-->Normal
*/
E<> sendingInteractionOfcrossroad_controller == 0 && receivingInteractionOfcrossroad_second == 8 && isStable
/*
crossroad_controller: Operating-->Operating -i-> crossroad_second: Normal-->Interrupted
*/
E<> sendingInteractionOfcrossroad_controller == 0 && receivingInteractionOfcrossroad_second == 2 && isStable
/*
crossroad_controller: Priority -i-> crossroad_second: Green-->Yellow
*/
E<> sendingInteractionOfcrossroad_controller == 3 && receivingInteractionOfcrossroad_second == 6 && isStable
/*
crossroad_controller: Priority -i-> crossroad_second: Red-->Green
*/
E<> sendingInteractionOfcrossroad_controller == 3 && receivingInteractionOfcrossroad_second == 5 && isStable
/*
crossroad_controller: Priority -i-> crossroad_second: Yellow-->Red
*/
E<> sendingInteractionOfcrossroad_controller == 3 && receivingInteractionOfcrossroad_second == 4 && isStable
/*
crossroad_controller: Init -i-> crossroad_prior: Green-->Yellow
*/
E<> sendingInteractionOfcrossroad_controller == 1 && receivingInteractionOfcrossroad_prior == 7 && isStable
/*
crossroad_controller: Init -i-> crossroad_prior: Red-->Green
*/
E<> sendingInteractionOfcrossroad_controller == 1 && receivingInteractionOfcrossroad_prior == 1 && isStable
/*
crossroad_controller: Init -i-> crossroad_prior: Yellow-->Red
*/
E<> sendingInteractionOfcrossroad_controller == 1 && receivingInteractionOfcrossroad_prior == 3 && isStable
/*
crossroad_controller: Priority -i-> crossroad_prior: Green-->Yellow
*/
E<> sendingInteractionOfcrossroad_controller == 3 && receivingInteractionOfcrossroad_prior == 7 && isStable
/*
crossroad_controller: Priority -i-> crossroad_prior: Yellow-->Red
*/
E<> sendingInteractionOfcrossroad_controller == 3 && receivingInteractionOfcrossroad_prior == 3 && isStable
/*
crossroad_controller: Priority -i-> crossroad_prior: Red-->Green
*/
E<> sendingInteractionOfcrossroad_controller == 3 && receivingInteractionOfcrossroad_prior == 1 && isStable
/*
crossroad_controller: SecondaryPrepares -i-> crossroad_second: Green-->Yellow
*/
E<> sendingInteractionOfcrossroad_controller == 5 && receivingInteractionOfcrossroad_second == 6 && isStable
/*
crossroad_controller: SecondaryPrepares -i-> crossroad_second: Yellow-->Red
*/
E<> sendingInteractionOfcrossroad_controller == 5 && receivingInteractionOfcrossroad_second == 4 && isStable
/*
crossroad_controller: SecondaryPrepares -i-> crossroad_second: Red-->Green
*/
E<> sendingInteractionOfcrossroad_controller == 5 && receivingInteractionOfcrossroad_second == 5 && isStable
/*
crossroad_controller: Operating-->Operating -i-> crossroad_prior: Normal-->Interrupted
*/
E<> sendingInteractionOfcrossroad_controller == 0 && receivingInteractionOfcrossroad_prior == 0 && isStable
/*
crossroad_controller: Operating-->Operating -i-> crossroad_prior: Interrupted-->Normal
*/
E<> sendingInteractionOfcrossroad_controller == 0 && receivingInteractionOfcrossroad_prior == 9 && isStable
/*
crossroad_controller: PriorityPrepares -i-> crossroad_prior: Green-->Yellow
*/
E<> sendingInteractionOfcrossroad_controller == 2 && receivingInteractionOfcrossroad_prior == 7 && isStable
/*
crossroad_controller: PriorityPrepares -i-> crossroad_prior: Red-->Green
*/
E<> sendingInteractionOfcrossroad_controller == 2 && receivingInteractionOfcrossroad_prior == 1 && isStable
/*
crossroad_controller: PriorityPrepares -i-> crossroad_prior: Yellow-->Red
*/
E<> sendingInteractionOfcrossroad_controller == 2 && receivingInteractionOfcrossroad_prior == 3 && isStable
/*
crossroad_controller: Secondary -i-> crossroad_second: Green-->Yellow
*/
E<> sendingInteractionOfcrossroad_controller == 4 && receivingInteractionOfcrossroad_second == 6 && isStable
/*
crossroad_controller: Secondary -i-> crossroad_second: Yellow-->Red
*/
E<> sendingInteractionOfcrossroad_controller == 4 && receivingInteractionOfcrossroad_second == 4 && isStable
/*
crossroad_controller: Secondary -i-> crossroad_second: Red-->Green
*/
E<> sendingInteractionOfcrossroad_controller == 4 && receivingInteractionOfcrossroad_second == 5 && isStable
/*
crossroad_controller: Secondary -i-> crossroad_prior: Green-->Yellow
*/
E<> sendingInteractionOfcrossroad_controller == 4 && receivingInteractionOfcrossroad_prior == 7 && isStable
/*
crossroad_controller: Secondary -i-> crossroad_prior: Red-->Green
*/
E<> sendingInteractionOfcrossroad_controller == 4 && receivingInteractionOfcrossroad_prior == 1 && isStable
/*
crossroad_controller: Secondary -i-> crossroad_prior: Yellow-->Red
*/
E<> sendingInteractionOfcrossroad_controller == 4 && receivingInteractionOfcrossroad_prior == 3 && isStable
