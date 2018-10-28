<?php

//$name = $_REQUEST['name'];
//$filename = $_REQUEST['files'];
//$filepath = $_REQUEST['path'];

$name = "richard allen";
$filename = "new07_25_2015_Leftsleep1.csv";
$filepath = "../uploads/richard allen";

//putenv("HOME=/var/www/");

$matlabExe = "sudo run.sh";
$mfile = "run";
$command = $matlabExe . ' -r ' . $mfile ;
try {
	print "$command\n";
    	echo exec($matlabExe);
	$reportFile = "./".$name.".pdf";
	if(file_exists($reportFile)){
		chgrp($reportFile, 'rls');
        	chmod($reportFile,0775); 
		echo "Report generated successfuly!";	
	}	  
} catch ( Exception $e ) {
    	echo 'failed';
	echo $e->getMessage();
}
?>
