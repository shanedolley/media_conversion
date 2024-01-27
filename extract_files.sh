#!/bin/bash

find '/mnt/plexmedia/Movies' -type f -size +5M -printf 'Movies|%f|%s\n' > ./files.csv
find '/mnt/plexmedia/TV' -type f -size +5M -printf 'TV|%f|%s\n' >> ./files.csv
find '/mnt/plexmedia/Comedy' -type f -size +5M -printf 'Comedy|%f|%s\n' >> ./files.csv
find '/mnt/plexmedia/Documentaries' -type f -size +5M -printf 'Documentaries|%f|%s\n' >> ./files.csv
find '/mnt/plexmedia/Theatre' -type f -size +5M -printf 'Theatre|%f|%s\n' >> ./files.csv