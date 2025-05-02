# this script prepares a csv file with valid WIS2 topics from the Earth System Discipline onwards
# the target directory is provided as an argument
# target directory should exists and writable or the script will fail
# if the .csv file already exists, it will be overwritten

import requests
import zipfile
import io
import os
import sys

# if no argument is provided, exit with error
if len(sys.argv) != 2:
    print("Usage: python generate-topic-list.py <target_directory>")
    sys.exit(1)


INPUT_FILE = "earth-system-discipline.csv"
OUTPUT_FILE = "topics-dropdown-list.csv"
# download zip-file from url
ZIPFILE_URL = 'https://wmo-im.github.io/wis2-topic-hierarchy/wth-bundle.zip'


def prepare_topic_list(target_directory):
    # download zip-file from url
    response = requests.get(ZIPFILE_URL)
    if response.status_code != 200:
        print(f"Error downloading zip file: {response.status_code}")
        sys.exit(1)

    lines = []
    # extract zip-file, 
    with zipfile.ZipFile(io.BytesIO(response.content)) as z:
        # check if the file exists in the zip-file
        if INPUT_FILE not in z.namelist():
            print(f"Error: {INPUT_FILE} not found in zip file")
            sys.exit(1)
        # read the csv file from the zip-file
        with z.open(INPUT_FILE) as f:
            # read the csv file into a list of lines
            lines = f.read().decode('utf-8').splitlines()
    # check if the file is empty
    if not lines:
        print(f"Error: {INPUT_FILE} is empty")
        sys.exit(1)
    # loop over lines and write to file
    with open(os.path.join(target_directory, OUTPUT_FILE), 'w') as f:
        # check that the first line is Name
        if lines[0].strip() != "Name":
            print(f"Error: {INPUT_FILE} does not start with Name")
            sys.exit(1)
        # loop over rest of the lines
        # skip if line is contained in any of the following lines
        # for example skip "ocean" if the following line is "ocean/experimental"
        # write the line to the file
        for line in lines[1:]:
            # check if the line is empty
            if not line.strip():
                continue
            # check if the line is contained in any of the following lines
            if any(line.strip() in l for l in lines[lines.index(line) + 1:]):
                continue
            # write the line to the file
            f.write(line.strip() + "\n")
        print(f"Updated {OUTPUT_FILE} with {len(lines) - 1} topics")
            

if __name__ == "__main__":
    print("Preparing topic list...")
    # check if the target directory exists and is writable
    target_directory = sys.argv[1]
    if not os.path.exists(target_directory):
        print(f"Error: {target_directory} does not exist")
        sys.exit(1)
    if not os.access(target_directory, os.W_OK):
        print(f"Error: {target_directory} is not writable")
        sys.exit(1)

    # prepare the topic list
    prepare_topic_list(target_directory)
    # check if the file exists
    if not os.path.exists(os.path.join(target_directory, OUTPUT_FILE)):
        print(f"Error: {OUTPUT_FILE} not found in {target_directory}")
        sys.exit(1)