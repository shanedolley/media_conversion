#!/bin/bash

total_count=$(wc -l < /conversions/tv.txt)
line_count="$(($total_count + 0))"

while [ $line_count -gt 0 ];
do 
    #SET ORIGINAL FILE VARIABLES
    f2c=$(head -n 1 /conversions/tv.txt)
    f_format=$(mediainfo --inform="General;%Video_Format_List%" "$f2c")
    f_folder=$(mediainfo --inform="General;%FolderName%" "$f2c")
    f_filename=$(mediainfo --inform="General;%FileName%" "$f2c")
    f_duration=$(mediainfo --inform="General;%Duration%" "$f2c")
    f_filesize=$(mediainfo --inform="General;%FileSize%" "$f2c")
    f_extension="${f2c##*.}"
    nf_filename="$f_filename"".mp4"
    #format details for database
    db_folder="${f_folder//\'/\'\'}"
    db_filename="${f_filename//\'/\'\'}"
    db_newfilename="${nf_filename//\'/\'\'}"

    #BEGIN TRANSCODING FILE
    flatpak run --command=HandBrakeCLI fr.handbrake.ghb --preset-import-file "/conversions/H265.json" -Z "H265" -O -i "$f2c" -o "/conversions/converted/$f_filename.mp4" --encopts="gpu=any"
    trans_code="$?"

    #SET TRANSCODED FILE VARIABLES
    nf_filesize=$(mediainfo --inform="General;%FileSize%" "/conversions/converted/$nf_filename")
    nf_duration=$(mediainfo --inform="General;%Duration%" "/conversions/converted/$nf_filename")
    var_filesize=$((nf_filesize-f_filesize))
    var_duration=$((nf_duration-f_duration))
    min_duration=$(bc <<< "0.98*$f_duration/1")
    max_duration=$(bc <<< "1.02*$f_duration/1")

    #CHECK IF TRANSCODE SUCCEEDED
    if [ $trans_code = 0 ];
    then 
        echo "Analysing transcoded file integrity..."

        #CHECK TRANSCODED FILE DURATION
        if [ "$nf_duration" -gt "$min_duration" ]; then
            if [ "$nf_duration" -lt "$max_duration" ]; then

                #CHECK TRANSCODED FILE SIZE
                if [ "$var_filesize" -lt 0 ]; then 

                    #COPY FILE
                    echo "Renaming original file..."
                    mv "$f_folder/$f_filename.$f_extension" "$f_folder/$f_filename.bak"
                    echo "Copying transcoded file..."
                    cp -f "/conversions/converted/$nf_filename" "$f_folder/$nf_filename"
                    copy1_result="$?"

                    #VERIFY COPY SUCCESS
                    if [ $copy1_result = 0 ]; then 
                        echo "Cleaning up old files..."
                        rm -f "$f_folder/$f_filename.bak"
                        rm -f "/conversions/converted/$nf_filename"
                        psql -c "insert into transcoding_results values ('$db_folder','$db_filename.$f_extension','$f_filesize','$f_duration','$db_newfilename','$nf_filesize','$nf_duration','$var_filesize','$var_duration','$trans_code','Success: File converted and copied.')" postgres://postgres.ckmjhueoqmogtqfkruzq:Omega47.blue!@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres
                    else 
                        echo "File copy unsuccessful. Trying again..."
                        rm -f "$f_folder/$nf_filename"
                        
                        #TRY COPY AGAIN
                        cp -f "/conversions/converted/$nf_filename" "$f_folder/$nf_filename"
                        copy2_result="$?"
                        
                        #VERIFY COPY SUCCESS v2
                        if [ $copy2_result = 0 ]; then
                            echo "Cleaning up old files..."
                            rm -f "$f_folder/$f_filename.bak"
                            rm -f "/conversions/converted/$nf_filename"
                            psql -c "insert into transcoding_results values ('$db_folder','$db_filename.$f_extension','$f_filesize','$f_duration','$db_newfilename','$nf_filesize','$nf_duration','$var_filesize','$var_duration','$trans_code','Success: File converted and copied on second try.')" postgres://postgres.ckmjhueoqmogtqfkruzq:Omega47.blue!@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres
                        else 
                            #ABORT - FILE COPY ERROR
                            echo "File copy unsuccessful again. Aborting..."
                            rm -f "$f_folder/$nf_filename"
                            mv "$f_folder/$f_filename.bak" "$f_folder/$f_filename.$f_extension"
                            psql -c "insert into transcoding_results values ('$db_folder','$db_filename.$f_extension','$f_filesize','$f_duration','$db_newfilename','$nf_filesize','$nf_duration','$var_filesize','$var_duration','$trans_code','Aborted: File copy failed.')" postgres://postgres.ckmjhueoqmogtqfkruzq:Omega47.blue!@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres
                        fi
                    fi 
                else 
                    #ABORT - NO DISKSPACE GAIN
                    echo "No disk space gain from transcoding. Aborting..."
                    rm -f "/conversions/converted/$nf_filename"
                    psql -c "insert into transcoding_results values ('$db_folder','$db_filename.$f_extension','$f_filesize','$f_duration','$db_newfilename','$nf_filesize','$nf_duration','$var_filesize','$var_duration','$trans_code','Aborted: No diskspace gained.')" postgres://postgres.ckmjhueoqmogtqfkruzq:Omega47.blue!@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres
                fi
            else 
                #ERROR - DURATION DISCREPANCY
                echo "ERROR: Large duration discrepancy. Aborting..."
                psql -c "insert into transcoding_results values ('$db_folder','$db_filename.$f_extension','$f_filesize','$f_duration','$db_newfilename','$nf_filesize','$nf_duration','$var_filesize','$var_duration','$trans_code','ERROR: Large duration variance - transcode failed')" postgres://postgres.ckmjhueoqmogtqfkruzq:Omega47.blue!@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres
            fi 
        else 
            #ERROR - DURATION DISCREPANCY
            echo "ERROR: Large duration discrepancy. Aborting..."
            psql -c "insert into transcoding_results values ('$db_folder','$db_filename.$f_extension','$f_filesize','$f_duration','$db_newfilename','$nf_filesize','$nf_duration','$var_filesize','$var_duration','$trans_code','ERROR: Large duration variance - transcode failed')" postgres://postgres.ckmjhueoqmogtqfkruzq:Omega47.blue!@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres
        fi
    else 
        psql -c "insert into transcoding_results values ('$db_folder','$db_filename.$f_extension','$f_filesize','$f_duration','$db_newfilename','$nf_filesize','$nf_duration','$var_filesize','$var_duration','$trans_code','ERR: Transcode failed')" postgres://postgres.ckmjhueoqmogtqfkruzq:Omega47.blue!@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres
    fi 

    #REMOVE FROM MASTER LIST
    echo "Removing file from conversion master list..."
    tail -n +2 "/conversions/tv.txt" > "/conversions/tv_temp.txt" && mv "/conversions/tv_temp.txt" "/conversions/tv.txt"
  
    line_count=$((line_count-1));
done
