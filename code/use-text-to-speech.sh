#!/bin/bash

# **************** Global variables

source ./code/.env

echo "RESOURCE_GROUP: $RESOURCE_GROUP"

export OAUTHTOKEN=""
export IBMCLOUD_APIKEY=$APIKEY
export T_RESOURCEGROUP=$RESOURCE_GROUP
export T_REGION=$REGION
export TTS_APIKEY=""
export TTS_URL=""
export CUSTOM_MODEL_JSON=mymodel-1.json
export CUSTOM_MODEL_ID_JSON=customization_id.json
export PFAELZER_JSON=pfaelzer.json
export PFAELZER_WORDS=pfaelzer-words.json
export PFAELZER_AUDIO_DEFAULT=pfaelzer_default.wav
export PFAELZER_AUDIO_CUSTOM=pfaelzer_custom.wav

# **********************************************************************************
# Functions definition
# **********************************************************************************

function loginIBMCloud () {
    ibmcloud login  --apikey $IBMCLOUD_APIKEY
    echo "T_RESOURCEGROUP: $T_RESOURCEGROUP"
    echo "T_REGION: $T_REGION"
    ibmcloud target -r $T_REGION -g $T_RESOURCEGROUP
    ibmcloud target
}

function getAPIKey() {
    TEMPFILE=temp-tts.json
    REQUESTMETHOD=POST
    
    ibmcloud resource service-keys --instance-name $TTS_SERVICE_INSTANCE_NAME
    ibmcloud resource service-keys --instance-name $TTS_SERVICE_INSTANCE_NAME --output json
    ibmcloud resource service-keys --instance-name $TTS_SERVICE_INSTANCE_NAME --output json > $ROOTFOLDER/code/$TEMPFILE
    export TTS_APIKEY=$(cat $ROOTFOLDER/code/$TEMPFILE | jq '.[0].credentials.apikey' | sed 's/"//g')
    export TTS_URL=$(cat $ROOTFOLDER/code/$TEMPFILE | jq '.[0].credentials.url' | sed 's/"//g')
}

#***************
# Basic
#***************

function getAllSpeakerModels () {
   echo "Command: curl -X GET -u 'apikey:$TTS_APIKEY' '$TTS_URL/v1/speakers'"
   echo ""
   curl -X GET -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/speakers"
}

function getAllVoices () {
   echo "Command: curl -X GET -u 'apikey:$TTS_APIKEY' '$TTS_URL/v1/voices'"
   echo ""
   curl -X GET -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/voices"
}

function getDEDieterV3Voice () {
   curl -X GET -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/voices/de-DE_DieterV3Voice"
}

function getDefaultAudio () {
   curl -X POST -u "apikey:$TTS_APIKEY" --header "Content-Type: application/json" --header "Accept: audio/wav" --data @"$ROOTFOLDER/code/$PFAELZER_JSON" --output "$ROOTFOLDER/code/$PFAELZER_AUDIO_DEFAULT"  "$TTS_URL/v1/synthesize?voice=de-DE_DieterV3Voice"
}

#*********************************
#        Customized models
#*********************************

function getAllCustomizedModels () {
   curl -X GET -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/customizations"
}

# -------------------------
# Create a custom model by extending an existing model
# "de-DE_DieterV3Voice"
# -------------------------

function createCustomModel () {
    export customization_id=$(curl -X POST -u "apikey:$TTS_APIKEY" --header "Content-Type: application/json" --data  @$ROOTFOLDER/code/$CUSTOM_MODEL_JSON "$TTS_URL/v1/customizations")
    echo ""
    echo "customization_id: $customization_id"
    echo $customization_id > $ROOTFOLDER/code/$CUSTOM_MODEL_ID_JSON
}

function deleteCustomModel () {
    export CUSTOM_MODEL_ID_JSON=customization_id.json
    export customization_id=$(cat $ROOTFOLDER/code/$CUSTOM_MODEL_ID_JSON | jq '.customization_id' | sed 's/"//g')
    echo ""
    echo  "Delete 'customization_id': $customization_id"
    curl -X DELETE -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/customizations/$customization_id"
}

#*********************************
#        Custom Word
#*********************************

function createWords () {
    export customization_id=$(cat $ROOTFOLDER/code/$CUSTOM_MODEL_ID_JSON | jq '.customization_id' | sed 's/"//g')
    curl -X POST -u "apikey:$TTS_APIKEY" --header "Content-Type: application/json" --data @"$ROOTFOLDER/code/$PFAELZER_WORDS"  "$TTS_URL/v1/customizations/$customization_id/words"

    STATUS='being_processed'
    TIME=10
}

function listWords () {
    export customization_id=$(cat $ROOTFOLDER/code/$CUSTOM_MODEL_ID_JSON | jq '.customization_id' | sed 's/"//g')
    curl -X GET -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/customizations/$customization_id/words"
}

function deleteWords () {
    export customization_id=$(cat $ROOTFOLDER/code/$CUSTOM_MODEL_ID_JSON | jq '.customization_id' | sed 's/"//g')
    echo ""
    echo "Delete 'customization_id' 'word': $customization_id ich"
    curl -X DELETE -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/customizations/$customization_id/words/ich"
}

#********************************
#  Use custom words
#********************************

function getCustomAudio () {
   export customization_id=$(cat $ROOTFOLDER/code/$CUSTOM_MODEL_ID_JSON | jq '.customization_id' | sed 's/"//g')
   curl -X POST -u "apikey:$TTS_APIKEY" --header "Content-Type: application/json" --header "Accept: audio/wav" --data @"$ROOTFOLDER/code/$PFAELZER_JSON" --output "$ROOTFOLDER/code/$PFAELZER_AUDIO_CUSTOM"  "$TTS_URL/v1/synthesize?voice=de-DE_DieterV3Voice&customization_id=$customization_id"
}

#*********************************
#        Train the model
#  Information: https://cloud.ibm.com/docs/speech-to-text?topic=speech-to-text-languageCreate#trainModel-language
#*********************************

function trainCustomLanguageModel () {
    export customization_id=$(cat $ROOTFOLDER/code/$CUSTOM_MODEL_ID_JSON | jq '.customization_id' | sed 's/"//g')
    echo ""
    echo "Train ..."

    curl -X POST -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/customizations/$customization_id/train"
    
    STATUS='pending'
    TIME=10

    while [ "$STATUS" != 'available' ]; do
        sleep 10
        RESPONSE=$(curl -X GET -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/customizations/$customization_id")
        echo "Response: $RESPONSE"
        STATUS=$(echo $RESPONSE | sed -e 's/.*\"status\": \"\([^\"]*\)\".*/\1/')
        echo "Status ($STATUS)"
        echo "Status: %-15s ( %d )\n" "$STATUS" $TIME
        let "TIME += 10"
    done

    curl -X GET -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/customizations/$customization_id/words"
    curl -X GET -u "apikey:$TTS_APIKEY" "$TTS_URL/v1/customizations/$customization_id"
}

#*********************************
#       Verify the model
#*********************************

function verifyCustomLanguageModel () {
   export customization_id=$(cat $ROOTFOLDER/code/$CUSTOM_MODEL_ID_JSON | jq '.customization_id' | sed 's/"//g')
   export basic_model=$(cat $ROOTFOLDER/code/$CUSTOM_MODEL_JSON | jq '.base_model_name' | sed 's/"//g')
   
   echo "customization_id: $customization_id"
   echo "basic_model: $basic_model"
   echo ""
   echo "Test audio ..."
   curl -X POST -u "apikey:$TTS_APIKEY" --header "Content-Type: audio/flac" --data-binary @"$ROOTFOLDER/code/$DRUMS_AUDIO" "$TTS_URL/v1/recognize?model=${basic_model}&language_customization_id=$customization_id"
}

#*********************************
#       Flows
#*********************************

function customizationFlow() {

    echo "#------------------"
    echo "# Create and train a Custom Language Model"
    echo "#------------------"
    createCustomLanguageModel
    getAllCustomizedModels
    createCorpora
    listCorpora
    trainCustomLanguageModel
    echo "#------------------"
    echo "# Verify a trained model by using an audio"
    echo "#------------------"
    verifyCustomLanguageModel

}

function basicFlow() {

  sendDefaultAudio
  getEnUSBroadbandModel

}

function deleteAll () {
   deleteCorpora
   deleteCustomLanguageModel
   rm $ROOTFOLDER/code/$CUSTOM_MODEL_ID_JSON
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "#*******************"
echo "# Connect to IBM Cloud and"
echo "# get the Text to Speach API key"
echo "#*******************"

loginIBMCloud
getAPIKey

deleteCustomModel

#getAllSpeakerModels
#getAllVoices
#getDEDieterV3Voice
getDefaultAudio
createCustomModel
getAllCustomizedModels
createWords
listWords
getCustomAudio
deleteWords
deleteCustomModel
getAllCustomizedModels

echo ""
echo "#*******************"
echo "# Delete the created customizations"
echo "#*******************"

# deleteAll

echo "#*******************"
echo "# Customization flow"
echo "#*******************"

# customizationFlow

echo "#*******************"
echo "# Basic flow"
echo "#*******************"

# basicFlow




