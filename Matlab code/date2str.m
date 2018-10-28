function dateStrings = date2str(dates)
dateStrings = num2str(dates,'%i');
dateStrings = cellstr(dateStrings);
for i=1:size(dateStrings)
    date = dateStrings{i};
    dateStrings{i} = strcat(date(7:8),'-',date(5:6),'-',date(1:4));
end