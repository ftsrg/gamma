/*
TrafficLight: Ok-->Threshold
*/
E<> transitionId == 1 && isStable
/*
TrafficLight: Yellow-->Red
*/
E<> transitionId == 2 && isStable
/*
TrafficLight: Ok-->Ok
*/
E<> transitionId == 3 && isStable
/*
TrafficLight: On-->Off
*/
E<> transitionId == 4 && isStable
/*
TrafficLight: Off-->Off
*/
E<> transitionId == 5 && isStable
/*
TrafficLight: Green-->Yellow
*/
E<> transitionId == 6 && isStable
/*
TrafficLight: Normal-->Interrupted
*/
E<> transitionId == 7 && isStable
/*
TrafficLight: On-->On
*/
E<> transitionId == 8 && isStable
/*
TrafficLight: Interrupted-->Normal
*/
E<> transitionId == 9 && isStable
/*
TrafficLight: Threshold-->Interrupted
*/
E<> transitionId == 10 && isStable
/*
TrafficLight: Red-->Green
*/
E<> transitionId == 11 && isStable
/*
TrafficLight: Ok-->Ok
*/
E<> transitionId == 12 && isStable
/*
TrafficLight: Off-->On
*/
E<> transitionId == 13 && isStable
