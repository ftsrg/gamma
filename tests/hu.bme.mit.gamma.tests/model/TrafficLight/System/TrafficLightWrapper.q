/*
TrafficLight: Normal-->Interrupted
*/
E<> transitionId == 1 && isStable
/*
TrafficLight: Off-->Off
*/
E<> transitionId == 2 && isStable
/*
TrafficLight: On-->Off
*/
E<> transitionId == 3 && isStable
/*
TrafficLight: On-->On
*/
E<> transitionId == 4 && isStable
/*
TrafficLight: Green-->Yellow
*/
E<> transitionId == 5 && isStable
/*
TrafficLight: Yellow-->Red
*/
E<> transitionId == 6 && isStable
/*
TrafficLight: Ok-->Ok
*/
E<> transitionId == 7 && isStable
/*
TrafficLight: Threshold-->Interrupted
*/
E<> transitionId == 8 && isStable
/*
TrafficLight: Off-->On
*/
E<> transitionId == 9 && isStable
/*
TrafficLight: Red-->Green
*/
E<> transitionId == 10 && isStable
/*
TrafficLight: Ok-->Ok
*/
E<> transitionId == 11 && isStable
/*
TrafficLight: Ok-->Threshold
*/
E<> transitionId == 12 && isStable
/*
TrafficLight: Interrupted-->Normal
*/
E<> transitionId == 13 && isStable
