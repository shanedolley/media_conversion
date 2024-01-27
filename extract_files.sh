#!/bin/bash

echo 'category|filename|filesize' > ./files.csv
find '/mnt/plexmedia/Movies' -type f -size +5M -printf 'Movies|%p|%s\n' >> ./files.csv
find '/mnt/plexmedia/TV' -type f -size +5M -printf 'TV|%p|%s\n' >> ./files.csv
find '/mnt/plexmedia/Comedy' -type f -size +5M -printf 'Comedy|%p|%s\n' >> ./files.csv
find '/mnt/plexmedia/Documentaries' -type f -size +5M -printf 'Documentaries|%p|%s\n' >> ./files.csv
find '/mnt/plexmedia/Theatre' -type f -size +5M -printf 'Theatre|%p|%s\n' >> ./files.csv