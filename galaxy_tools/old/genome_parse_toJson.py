import csv
import json
import sys

def generate_chromosome_collection(csv_file, output_json):
    chromosomes = []
    with open(csv_file, newline='') as f:
        reader = csv.reader(f)
        for row in reader:
            chrom = row[0].strip()
            chromosomes.append({"src": "hda", "name": chrom})

    collection = {
        "name": "chromosomes",
        "elements": chromosomes
    }

    with open(output_json, 'w') as out:
        json.dump(collection, out, indent=2)
    print(f"Galaxy collection JSON saved to {output_json}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python split_genome_csv.py genome_allchr.csv chromosomes_collection.json")
        sys.exit(1)

    generate_chromosome_collection(sys.argv[1], sys.argv[2])
