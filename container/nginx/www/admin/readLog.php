<?php
include '/opt/stateful/config/phvalheim-frontend.conf';
#include '../includes/config.php';


if (!empty($_GET['logfile'])) {
        $logFile = $_GET['logfile'];
}


function populateLogOutput($logFile,$logExclusions,$logHighlight,$logHighlightError,$logHighlightWarn,$logHighlightNotice,$logHighlightGreen,$logHighlightErrorDarker,$logHighlightWarnDarker,$logHighlightNoticeDarker,$logHighlightGreenDarker){
	$logOutput = nl2br(file_get_contents( "/opt/stateful/logs/$logFile" ));
	

	#Log filters

	#Exclusions
	foreach ($logExclusions as $logExclusion) {
		$logOutput = preg_replace("/(.*)$logExclusion(.*)/i",'',$logOutput);
	}

	#Put log lines into an array. This is used for highlighting
	$logArray = explode("\n", $logOutput);

	#Highlighter
	foreach ($logArray as $key => $logEntry) {

		foreach ($logHighlight as $keyword => $alertType) {

			if (stripos($logEntry, $keyword) !== false) {

				if($alertType == "error") {
					$logEntry = "<p style='background:$logHighlightError;color:$logHighlightErrorDarker;'>$logEntry</p>";
				}
			
                                if($alertType == "warn") {
                                        $logEntry = "<p style='background:$logHighlightWarn;color:$logHighlightWarnDarker;'>$logEntry</p>";
                                }

                                if($alertType == "notice") {
                                        $logEntry = "<p style='background:$logHighlightNotice;color:$logHighlightNoticeDarker;'>$logEntry</p>";
                                }
			}

			#ready for connections message
			if (preg_match('/Loaded(.*)locations/i', $logEntry))
			{
				$logEntry = "<br><p style='background:$logHighlightGreen;color:$logHighlightGreenDarker;'>Valheim World is online and ready for players.</p>";
			}

			#world completely stopped message
                        if (preg_match('/Net scene destroyed/i', $logEntry))
                        {
                                $logEntry = "<br><p style='background:$logHighlightNotice;color:$logHighlightNoticeDarker;'>Valheim world sucessfully stopped.</p>";
                        }

		}
		print $logEntry;
	}
}

?>

<html>

	<head>

		<link rel="stylesheet" type="text/css" href="/css/readLog.css">
		
		<script>
			//scroll to bottom of page (latest log entry)
			history.scrollRestoration = "manual";
			$(window).on('beforeunload', function(){
   			   $(window).scrollTop(0);
			});
		</script>
	</head>

	<body onload="window.location='#bottom';">
		<div>
			<p><?php populateLogOutput($logFile,$logExclusions,$logHighlight,$logHighlightError,$logHighlightWarn,$logHighlightNotice,$logHighlightGreen,$logHighlightErrorDarker,$logHighlightWarnDarker,$logHighlightNoticeDarker,$logHighlightGreenDarker);?></p>
		</div>
		<p>&nbsp;</p>
		<hr>
	
		<table border=0>
			<thead>
				<th><button onClick="window.location.reload();">Refresh</button></th>
				<td style="padding-left:35px;"></td>
				<td id="roundCorners" style="background: <?php echo $logHighlightError;?>;color: <?php echo $logHighlightErrorDarker;?>">Error</td>
				<td style="padding-left:10px;"></td>
				<td id="roundCorners" style="background: <?php echo $logHighlightWarn;?>;color: <?php echo $logHighlightWarnDarker;?>">Warning</td>
				<td style="padding-left:10px;"></td>
				<td id="roundCorners" style="background: <?php echo $logHighlightNotice;?>;color: <?php echo $logHighlightNoticeDarker;?>">Notice</td>
				<td style="padding-left:10px;"></td>
				<td id="roundCorners" style="background: <?php echo $logHighlightGreen;?>;color: <?php echo $logHighlightGreenDarker;?>">Ready</td>
			</thead>
		</table>
		

		<p id='bottom'></p>
	</body>

</html>
