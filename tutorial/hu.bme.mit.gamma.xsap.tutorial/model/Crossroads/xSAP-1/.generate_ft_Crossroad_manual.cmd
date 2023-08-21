set on_failure_script_quits
set input_file "C:/Users/grben/git/gamma/tutorial/hu.bme.mit.gamma.xsap.tutorial.finish\model/Crossroads/xSAP-1\extended_Crossroad.smv"
set sa_compass
set sa_compass_task_file "C:/Users/grben/git/gamma/tutorial/hu.bme.mit.gamma.xsap.tutorial.finish\model/Crossroads/xSAP-1\.fms_Crossroad.xml"
go_msat
compute_fault_tree_param -x "Crossroad_0_" -o "C:/Users/grben/git/gamma/tutorial/hu.bme.mit.gamma.xsap.tutorial.finish\model/Crossroads/xSAP-1\Crossroad.txt" -t "!( (!((normal_prior = Green & main_region_prior = Normal & normal_second = Green & main_region_second = Normal))))"
quit