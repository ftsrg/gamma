/*
Checking Green&Green state.
*/
E<> (LightCommands_displayGreenOfcrossroad_prior && LightCommands_displayGreenOfcrossroad_second) && isStable
E<> ((P_normalOfNormalOfcrossroad_prior.Green) && P_normalOfNormalOfcrossroad_prior.isActive && (P_normalOfNormalOfcrossroad_second.Green) && P_normalOfNormalOfcrossroad_second.isActive) && isStable