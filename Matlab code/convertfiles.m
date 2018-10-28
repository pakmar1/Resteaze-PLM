function [] = convertfiles(dirname, diroutput)
    allfiles = dir(dirname);
    for i=3:length(allfiles)
        filename = strcat(dirname,'\',allfiles(i).name)
        X = csvread(filename, 1, 0);
        Y = convertformat(X);
        filenameoutput = strcat(diroutput,'\','new', allfiles(i).name);
        dlmwrite(filenameoutput, Y, 'delimiter', ',', 'precision', '%.6f');
    end
     
end