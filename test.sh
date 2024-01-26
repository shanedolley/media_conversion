#!/bin/bash

f_format="AVC"
f_folder="/mnt/plexmedia/TV/South Park (1997) - {tvdb-75897}/Season 01"
f_filename="South Park (1997) - S01E04 - Big Gay Al's Big Gay Boat Ride [HDTV-1080p]"
f_duration="1327551"
f_filesize="146604320"
f_extension=".mkv"

#psql -c "insert into transcoding_results values ('$f_folder','filename','0','0','0','0','0','0')" postgres://postgres.ckmjhueoqmogtqfkruzq:Omega47.blue!@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres

min_duration=$(bc <<< "0.98*$f_duration/1")
echo "$min_duration"
max_duration=$(bc <<< "1.02*$f_duration/1")
echo "$max_duration"

if [ $f_duration -gt $min_duration ]; then
	echo "greater than min"
fi
if [ $f_duration -lt $max_duration ]; then
	echo "less than max"
fi
