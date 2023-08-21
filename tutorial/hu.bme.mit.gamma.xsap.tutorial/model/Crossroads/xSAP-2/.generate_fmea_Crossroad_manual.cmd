set on_failure_script_quits
set input_file "C:/Users/grben/git/gamma/tutorial/hu.bme.mit.gamma.xsap.tutorial.finish\model/Crossroads/xSAP-2\extended_Crossroad.smv"
set sa_compass
set sa_compass_task_file "C:/Users/grben/git/gamma/tutorial/hu.bme.mit.gamma.xsap.tutorial.finish\model/Crossroads/xSAP-2\.fms_Crossroad.xml"
go_msat
compute_fmea_table_msat_bmc -N 2 -k 12 -x "Crossroad_0_" -o "C:/Users/grben/git/gamma/tutorial/hu.bme.mit.gamma.xsap.tutorial.finish\model/Crossroads/xSAP-2\Crossroad.txt" -t "!((!( (((LightCommands_displayRed_Out_prior & LightCommands_displayGreen_Out_prior & LightCommands_displayYellow_Out_prior) | (LightCommands_displayRed_Out_second & LightCommands_displayGreen_Out_second & LightCommands_displayYellow_Out_second))))))"
quit