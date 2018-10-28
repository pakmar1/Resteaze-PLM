<?php

//$name = $_REQUEST['name'];
//$filename = $_REQUEST['files'];
//$filepath = $_REQUEST['path'];

$name = "taylor bright";
$filename = "01_07_2016_Leftsleep1.csv,01_07_2016_Rightsleep1.csv,01_11_2016_Leftsleep1.csv";
$filepath = "../uploads/taylor bright/";
$matlabExe = 'matlab';

$mfile = "\"createReport" . "('$name','$filepath','$filename')\"";
$command = $matlabExe . ' -nodisplay -nosplash -nodesktop -r ' . $mfile;
echo $command;
try {
    	//exec($command);
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
