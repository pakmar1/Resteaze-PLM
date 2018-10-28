<?php

//$name = $_REQUEST['name'];
//$filename = $_REQUEST['files'];
//$filepath = $_REQUEST['path'];

$name = "amitanshu jha";
$filename = "01_17_2016_Leftsleep1.csv,01_19_2016_Leftsleep1.csv";
$filepath = "../uploads/amitanshu jha";

$matlabExe = 'matlab -logfile log.out';
$mfile = "\"createReport" . "('$name','$filepath','$filename')\"";
$command = $matlabExe . ' -nodisplay -nosplash -nodesktop -r ' . $mfile;
try {
    	exec($command);
	$reportFile = "./".$name." Data Report.pdf";
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
