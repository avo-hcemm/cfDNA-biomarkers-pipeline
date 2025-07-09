import sys

input_path = sys.argv[1]
output_path = sys.argv[2]

with open(input_path, 'r') as infile:
    content = infile.read()

with open(output_path, 'w') as outfile:
    outfile.write(content.upper())
