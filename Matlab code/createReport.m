function [] = createReport(patientName,filePath,files)
try
	addpath 'Multiple Night Reports'
	generateReportData;
catch
	error('Problem generating report');
	quit
end
display('Generate Report finished')
display('calling plot graph function')
generateReportGraphs(patientName, patientReport);
quit
end

