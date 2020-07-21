/*
Checking successful lockup.
*/
E<> (F_VU_lez_valOffojelzo && F_VU_lez_valOffojelzoval_VU_tip == 0) && isStable

/*
Checking unsuccessful lockup.
*/
E<> (F_VU_lez_valOffojelzo && F_VU_lez_valOffojelzoval_VU_tip == 1 && F_VU_lez_valOffojelzoobj_id == 11) && isStable