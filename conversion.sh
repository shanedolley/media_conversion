#!/bin/bash
webhook_auth="Authorization:76ba4bf5-f9d0-4639-a45d-31d6b3a1ffe8"
get_conversionStatus() {
    convStatus=$(curl -s 'https://api.dolley.cloud/webhook/convert-status' --header "$webhook_auth")
}
get_fileToConvert() {
    printf "Getting file information...\n"
    convFileName=$(curl -s 'https://api.dolley.cloud/webhook/media-conversion' --header "$webhook_auth")
    #set file variables
    f_format=$(mediainfo --inform="General;%Video_Format_List%" "$convFileName")
    f_folder=$(mediainfo --inform="General;%FolderName%" "$convFileName")
    f_filename=$(mediainfo --inform="General;%FileName%" "$convFileName")
    f_duration=$(mediainfo --inform="General;%Duration%" "$convFileName")
    f_filesize=$(mediainfo --inform="General;%FileSize%" "$convFileName")
    f_extension="${convFileName##*.}"
    nf_filename="$f_filename"".mp4"
}
get_transcodeFileDetails() {
    nf_filesize=$(mediainfo --inform="General;%FileSize%" "/conversions/$nf_filename")
    nf_duration=$(mediainfo --inform="General;%Duration%" "/conversions/$nf_filename")
    var_filesize=$((nf_filesize-f_filesize))
    var_duration=$((nf_duration-f_duration))
    min_duration=$(bc <<< "0.98*$f_duration/1")
    max_duration=$(bc <<< "1.02*$f_duration/1")
}
convertFile() {
    printf "Beginning transcode of "$f_filename "\n"
    ffmpeg -i "$convFileName" -c:v hevc_nvenc -c:a copy -stats -loglevel quiet -strict -2 -y "/conversions/$nf_filename"
    trans_code="$?"
}
process_convertedFile() {
    #check if transcoded file exists
    if [ -f "/conversions/$nf_filename" ]; then
        
        #check if transcode successful 
        if [ $trans_code = 0 ] && [ -f "/conversions/$nf_filename" ];
        then 
            printf "Transcode completed.\n"
            printf "Analysing transcoded file integrity...\n"

            #check transcoded file duration
            if [ "$nf_duration" -gt "$min_duration" ]; then
                if [ "$nf_duration" -lt "$max_duration" ]; then 
                    #check transcoded file size
                    if [ "$var_filesize" -lt 0 ]; then 
                        #copy file
                        printf "Renaming original file...\n"
                        mv "$f_folder/$f_filename.$f_extension" "$f_folder/$f_filename.bak"
                        printf "Copying transcoded file...\n"
                        cp -f "/conversions/$nf_filename" "$f_folder/$nf_filename"
                        copy1_result="$?"

                        #verify copy success
                        if [ $copy1_result = 0 ]; then 
                            printf "Cleaning up...\n"
                            rm -f "$f_folder/$f_filename.bak"
                            rm -f "/conversions/$nf_filename"
                            dataMessage="Success: File converted and copied"
                            curlCode="OK"
                        else 
                            printf "File copy unsuccessful. Trying again...\n"
                            rm -f "$f_folder/$nf_filename"
                            
                            #try copy again
                            cp -f "/conversions/$nf_filename" "$f_folder/$nf_filename"
                            copy2_result="$?"
                            
                            #verify copy success v2
                            if [ $copy2_result = 0 ]; then
                                printf "Cleaning up old files...\n"
                                rm -f "$f_folder/$f_filename.bak"
                                rm -f "/conversions/$nf_filename"
                                dataMessage="Success: File converted and copied on second try"
                                curlCode="OK"
                            else 
                                #ABORT - FILE COPY ERROR
                                printf "File copy unsuccessful again. Aborting...\n"
                                rm -f "$f_folder/$nf_filename"
                                mv "$f_folder/$f_filename.bak" "$f_folder/$f_filename.$f_extension"
                                dataMessage="Aborted: File copy failed"
                                curlCode="ERR"
                            fi
                        fi 
                    else 
                        #ABORT - NO DISKSPACE GAIN
                        printf "No disk space gain from transcoding. Aborting...\n"
                        rm -f "/conversions/$nf_filename"
                        curlCode="OK"
                        dataMessage="Aborted: No diskspace gained"
                    fi
                else 
                    #ERROR - DURATION DISCREPANCY
                    printf "ERROR: Large duration discrepancy 1. Aborting...\n"
                    curlCode="ERR"
                    dataMessage="ERROR: Large duration variance - transcode failed"
                fi 
            else 
                #ERROR - DURATION DISCREPANCY
                printf "ERROR: Large duration discrepancy 2. Aborting...\n"
                curlCode="ERR"
                dataMessage="ERROR: Large duration variance - transcode failed"
            fi
        else 
            printf "ERROR: Transcode failed\n"
            curlCode="ERR"
            dataMessage="ERROR: Transcode failed"
        fi 
    else 
        printf "ERROR: Transcoded file does not exist\n"
        curlCode="ERR"
        dataMessage="ERROR: Transcoded file does not exist"
    fi
}
update_conversionStatus() {
    curl -s --request POST 'https://api.dolley.cloud/webhook/convert-status?status='$1 --header "$webhook_auth"
    printf "\n"
}
update_masterList() {
    printf "Removing file from master list...\n"
    curl -s 'https://api.dolley.cloud/webhook/remove-file' --header "$webhook_auth"
    printf ".\n"
}
post_results() {
    if [ $curlCode = "OK" ]; then
        curl -s --request POST 'https://api.dolley.cloud/webhook/result' --header 'Content-Type: application/json' --header "$webhook_auth" --data '{"folder":"'"$f_folder"'","old_filename":"'"$convFileName"'","old_filesize":"'"$f_filesize"'","old_duration":"'"$f_duration"'","new_filename":"'"$nf_filename"'","new_filesize":"'"$nf_filesize"'","new_duration":"'"$nf_duration"'","var_filesize":"'"$var_filesize"'","var_duration":"'"$var_duration"'","result_code":"'"$trans_code"'","comment":"'"$dataMessage"'"}'
    fi 
    
    if [ $curlCode = "ERR" ]; then
        curl -s --request POST 'https://api.dolley.cloud/webhook/result' --header 'Content-Type: application/json' --header "$webhook_auth" --data '{"folder":"'"$f_folder"'","old_filename":"'"$convFileName"'","old_filesize":"'"$f_filesize"'","old_duration":"'"$f_duration"'","new_filename":"","new_filesize":"","new_duration":"","var_filesize":"","var_duration":"","result_code":"'"$trans_code"'","comment":"'"$dataMessage"'"}'
    fi
    printf ".\n"
}
pausemuch() {
    read -p "$1 Press enter to continue..."
}
reset_statuses() {
    unset curlCode unset convStatus unset convFileName f_format f_folder f_filename f_duration f_filesize f_extension nf_filename nf_filesize nf_duration var_filesize var_duration min_duration max_duration trans_code copy1_result copy2_result dataMessage
}

# check for stopped status
get_conversionStatus
if [ $convStatus = "stopped" ]; then 
    #printf "Conversion is currently disabled. Please enable to begin conversion process.\n"
    #exit 
    printf "\nConversion is currently disabled.\nWould you like to enable conversion and proceed?\n\n"
    select yn in "Yes" "No"; do 
        case $yn in
            Yes ) update_conversionStatus waiting; break;;
            No ) exit;;
        esac 
    done 
fi 

# begin conversion process
get_conversionStatus
if [ $convStatus != "stopped" ]; then 
    update_conversionStatus converting
    while [ $convStatus != "stopped" ]
        do 
            get_conversionStatus
            if [ $convStatus != "stopped" ]; then 
                get_fileToConvert
                #pausemuch "Last chance to cancel. You sure?"
                if [ -f "$convFileName" ]; then 
                    convertFile
                    get_transcodeFileDetails
                    process_convertedFile
                    post_results
                else 
                    curlCode = "MISS"
                    printf = "File does not exist. Transcode process skipped."
                fi 
                update_masterList
                echo '--==|| Conversion Process Complete ||==--'
                printf "\n\n"
            else 
                printf "Conversion has been disabled. Ending process...\n"
                exit
            fi
            reset_statuses
        done
    update_conversionStatus waiting
fi 