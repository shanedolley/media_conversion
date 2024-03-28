#!/bin/bash
copydata() {
    num_files=$(find "/mnt/data_backup/Complete/$1" -type f | wc -l)
    printf "Copying $num_files files for $1...\n"
    cp -r "/mnt/data_backup/Complete/$1" "/plexmedia/tv"
    printf "Copy complete\n----------\n"
}

copydata "Evil (2019) - {tvdb-363955}"
copydata "Fringe (2008) - {tvdb-82066}"
copydata "His Dark Materials (2019) - {tvdb-360295}"
copydata "Jonathan Strange & Mr Norrell (2015) - {tvdb-268581}"
copydata "Loki (2021) - {tvdb-362472}"
copydata "Lost (2004) - {tvdb-73739}"
copydata "Marvel's Agents of S.H.I.E.L.D. (2013) - {tvdb-263365}"
copydata "Marvel's Daredevil (2015) - {tvdb-281662}"
copydata "Motherland - Fort Salem (2020) - {tvdb-364047}"
copydata "Obi-Wan Kenobi (2022) - {tvdb-393199}"
copydata "Secret Invasion (2023) - {tvdb-393203}"
copydata "Shadow and Bone (2021) - {tvdb-369844}"
copydata "Stargate Origins (2018) - {tvdb-339552}"
copydata "Strike Back (2010) - {tvdb-148581}"
copydata "The Nevers (2021) - {tvdb-364315}"
copydata "The Orville (2017) - {tvdb-328487}"
copydata "The Witcher (2019) - {tvdb-362696}"
copydata "Titans (2018) - {tvdb-341663}"
copydata "Westworld (2016) - {tvdb-296762}"