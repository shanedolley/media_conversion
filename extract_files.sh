#!/bin/bash

find '/mnt/plexmedia/Movies' -type f -size +5M -printf '%f|%s\n' > ./files.csv
find '/mnt/plexmedia/TV' -type f -size +5M -printf '%f|%s\n' >> ./files.csv
find '/mnt/plexmedia/Comedy' -type f -size +5M -printf '%f|%s\n' >> ./files.csv
find '/mnt/plexmedia/Documentaries' -type f -size +5M -printf '%f|%s\n' >> ./files.csv
find '/mnt/plexmedia/Theatre' -type f -size +5M -printf '%f|%s\n' >> ./files.csv