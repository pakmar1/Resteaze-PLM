<?php
$pathname = ".";
$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($pathname));

foreach($iterator as $item) {
	echo $item."\n";    
	chmod($item, 0775);
	chgrp($item,"rls");
}

?>
