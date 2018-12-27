import sys
import csv
import pandas

#read the csv's

class resteaze_dash:
    
    def __init__(self):
        print("hello")

    with open(sys.argv[1]) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 0
        for row in csv_reader:
            if line_count == 0:
                print(f'Column names are {", ".join(row)}')
                line_count += 1
            #else:
            #    print(f'\t{row[0]} works in the {row[1]} department, and was born in {row[2]}.')
            #    line_count += 1
        print(f'Processed {line_count} lines.')

#df = pandas.read_csv(sys.argv[1], index_col='Name')
#print(df)