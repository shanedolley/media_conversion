#!/bin/bash

webhook_auth="Authorization:76ba4bf5-f9d0-4639-a45d-31d6b3a1ffe8"

convStatus=$(curl -s 'https://api.dolley.cloud/webhook/convert-status' --header "$webhook_auth")
convFileName=$(curl -s 'https://api.dolley.cloud/webhook/media-conversion' --header "$webhook_auth")

if [ $convStatus = "stopped" ]; then 
    echo "Conversion is currently disabled. Please enable to begin conversion process."
    exit 
fi 

while [ $convStatus != "stopped" ]
    do
        echo "Getting file information..."
        
        #set file variables
        f_format=$(mediainfo --inform="General;%Video_Format_List%" "$convFileName")
        f_folder=$(mediainfo --inform="General;%FolderName%" "$convFileName")
        f_filename=$(mediainfo --inform="General;%FileName%" "$convFileName")
        f_duration=$(mediainfo --inform="General;%Duration%" "$convFileName")
        f_filesize=$(mediainfo --inform="General;%FileSize%" "$convFileName")
        f_extension="${convFileName##*.}"
        nf_filename="$f_filename"".mp4"
        
        #begin transcode
        echo "Beginning transcode..."
        curl -s --request POST 'https://api.dolley.cloud/webhook/convert-status?status=converting' --header "$webhook_auth"
        flatpak run --command=HandBrakeCLI fr.handbrake.ghb --preset-import-file "/conversions/H265.json" -Z "H265" -O -i "$f2c" -o "/conversions/converted/$f_filename.mp4" --encopts="gpu=any"
        trans_code="$?"
        echo " Conversion code is $trans_code" 

        #set transcoded file variables
        nf_filesize=$(mediainfo --inform="General;%FileSize%" "/conversions/converted/$nf_filename")
        nf_duration=$(mediainfo --inform="General;%Duration%" "/conversions/converted/$nf_filename")
        var_filesize=$((nf_filesize-f_filesize))
        var_duration=$((nf_duration-f_duration))
        min_duration=$(bc <<< "0.98*$f_duration/1")
        max_duration=$(bc <<< "1.02*$f_duration/1")

        #check if transcoded file exists
        if [ -f "/conversions/converted/$nf_filename" ]; then
            
            #check if transcode successful 
            if [ $trans_code = 0 ] && [ -f "/conversions/converted/$nf_filename" ];
            then 
                echo "Analysing transcoded file integrity..."

                #check transcoded file duration
                if [ "$nf_duration" -gt "$min_duration" ]; then
                    if [ "$nf_duration" -lt "$max_duration" ]; then 
                        #check transcoded file size
                        if [ "$var_filesize" -lt 0 ]; then 
                            #copy file
                            echo "Renaming original file..."
                            mv "$f_folder/$f_filename.$f_extension" "$f_folder/$f_filename.bak"
                            echo "Copying transcoded file..."
                            cp -f "/conversions/converted/$nf_filename" "$f_folder/$nf_filename"
                            copy1_result="$?"

                            #verify copy success
                            if [ $copy1_result = 0 ]; then 
                                echo "Cleaning up old files..."
                                rm -f "$f_folder/$f_filename.bak"
                                rm -f "/conversions/converted/$nf_filename"
                                dataMessage="Success: File converted and copied"
                            else 
                                echo "File copy unsuccessful. Trying again..."
                                rm -f "$f_folder/$nf_filename"
                                
                                #try copy again
                                cp -f "/conversions/converted/$nf_filename" "$f_folder/$nf_filename"
                                copy2_result="$?"
                                
                                #verify copy success v2
                                if [ $copy2_result = 0 ]; then
                                    echo "Cleaning up old files..."
                                    rm -f "$f_folder/$f_filename.bak"
                                    rm -f "/conversions/converted/$nf_filename"
                                    dataMessage="Success: File converted and copied on second try"
                                else 
                                    #ABORT - FILE COPY ERROR
                                    echo "File copy unsuccessful again. Aborting..."
                                    rm -f "$f_folder/$nf_filename"
                                    mv "$f_folder/$f_filename.bak" "$f_folder/$f_filename.$f_extension"
                                    dataMessage="Aborted: File copy failed"
                                fi
                            fi 
                        else 
                            #ABORT - NO DISKSPACE GAIN
                            echo "No disk space gain from transcoding. Aborting..."
                            rm -f "/conversions/converted/$nf_filename"
                            curlCode="OK"
                            dataMessage="Aborted: No diskspace gained"
                        fi
                    else 
                        #ERROR - DURATION DISCREPANCY
                        echo "ERROR: Large duration discrepancy 1. Aborting..."
                        curlCode="ERR"
                        dataMessage="ERROR: Large duration variance - transcode failed"
                    fi 
                else 
                    #ERROR - DURATION DISCREPANCY
                    echo "ERROR: Large duration discrepancy 2. Aborting..."
                    curlCode="ERR"
                    dataMessage="ERROR: Large duration variance - transcode failed"
                fi
            else 
                echo "ERROR: Transcode failed"
                curlCode="ERR"
                dataMessage="ERROR: Transcode failed"
            fi 
        else 
            echo "ERROR: Transcoded file does not exist"
            curlCode="ERR"
            dataMessage="ERROR: Transcoded file does not exist"
        fi 

        #post results
        echo "$curlCode"

        if [ $curlCode = "OK" ]; then
            curl -s --request POST 'https://api.dolley.cloud/webhook/result' --header 'Content-Type: application/json' --header "$webhook_auth" --data '{"folder":"'"$f_folder"'","old_filename":"'"$convFileName"'","old_filesize":"'"$f_filesize"'","old_duration":"'"$f_duration"'","new_filename":"'"$nf_filename"'","new_filesize":"'"$nf_filesize"'","new_duration":"'"$nf_duration"'","var_filesize":"'"$var_filesize"'","var_duration":"'"$var_duration"'","result_code":"'"$trans_code"'","comment":"'"$dataMessage"'"}'
        fi 
        
        if [ $curlCode = "ERR" ]; then
            curl -s --request POST 'https://api.dolley.cloud/webhook-test/result' --header 'Content-Type: application/json' --header "$webhook_auth" --data '{"folder":"'"$f_folder"'","old_filename":"'"$convFileName"'","old_filesize":"'"$f_filesize"'","old_duration":"'"$f_duration"'","new_filename":"","new_filesize":"","new_duration":"","var_filesize":"","var_duration":"","result_code":"'"$trans_code"'","comment":"'"$dataMessage"'"}'

        fi 

        #remove from master list
        echo "Removing file from master list..."
        #curl -s 'https://api.dolley.cloud/webhook/remove-file' --header "$webhook_auth"
        
        #update conversion status
        convStatus="stopped"
    done
    convStatus="stopped"

curl -s --request POST 'https://api.dolley.cloud/webhook/convert-status?status=waiting' --header "$webhook_auth"
