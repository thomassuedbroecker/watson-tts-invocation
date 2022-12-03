# Watson STT invocation

This project contains a bash script automation example for the IBM Cloud Watson Test to Speech service.

The automation contains two flows:

1. Basic usage to create a german audio based given text in a wav format
2. Customization of an existing voice model to speak german with a kind of palatinate dialect. Just for fun ;-) 

### Prerequsites

* [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started) installed
* A [Watson Text to Speech](https://cloud.ibm.com/apidocs/text-to-speech#introduction) service with an [Plus plan](https://cloud.ibm.com/docs/billing-usage?topic=billing-usage-changing&interface=ui) is created.
* Install the cURL command line on the local computer

Just execute following steps to run the example.

### Step 1: Clone the project

```sh
git clone https://github.com/thomassuedbroecker/watson-tts-invocation
cd watson-tts-invocation
```

### Step 2: Configure the `.env` file

```sh
cp ./code/.env-template ./code/.env
```

### Step 3: Set the correct values in the `.env` file

* [Create an IBM Cloud APIKEY](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=servers-creating-cloud-api-key)

```sh
ROOTFOLDER="YOUR_PATH"
RESOURCE_GROUP="default"
REGION="us-south"
APIKEY="YOUR_IBMCLOUD_APIKEY"
S2T_SERVICE_INSTANCE_NAME="YOUR_TTS_SERVICE_NAME"
```

### Step 4: Invoke the bash automation

```sh
sh code/use-test-to-speech.sh
```

* Example output

```sh
#*******************
# Customization flow
#*******************
#------------------
# Create a custom model with custom words
#------------------
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   142  100    61  100    81     36     48  0:00:01  0:00:01 --:--:--    85

customization_id: {"customization_id": "a31ab5a3-8dc2-41fb-a70d-e3f7719eba0b"}
{"customizations": [{
   "owner": "1539e1d6-4c73-4bb7-8978-6629216943a0",
   "customization_id": "a31ab5a3-8dc2-41fb-a70d-e3f7719eba0b",
   "created": "2022-12-02T17:52:09.247Z",
   "name": "Pfaelzer-1",
   "description": "Pfaelzer-1-demo",
   "language": "de-DE",
   "last_modified": "2022-12-02T17:52:09.247Z"
}]}{}{"words": [
   {
      "translation": "isch",
      "word": "ich"
   },
   {
      "translation": "isch",
      "word": "Ich"
   },
   {
      "translation": "babbel",
      "word": "rede"
   },
   {
      "translation": "än",
      "word": "ein"
   },
   {
      "translation": "kumm",
      "word": "komme"
   },
   {
      "translation": "dää",
      "word": "der"
   },
   {
      "translation": "Pallz",
      "word": "Pfalz"
   },
   {
      "translation": "Pällzer",
      "word": "Pfälzer"
   }
]}  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  145k    0  145k  100    70  94515     44  0:00:01  0:00:01 --:--:-- 95184
#------------------
# Verify the audio on your computer
# /... tts-invocation/code/pfaelzer_custom.wav
#------------------
#*******************
# Basic flow
#*******************
{
   "name": "de-DE_DieterV3Voice",
   "language": "de-DE",
   "gender": "male",
   "description": "Dieter: Standard German (Standarddeutsch) male voice. Dnn technology.",
   "customizable": true,
   "supported_features": {
      "custom_pronunciation": true,
      "voice_transformation": false
   },
   "url": "https://api.us-south.text-to-speech.watson.cloud.ibm.com/instances/1539e1d6-4c73-4bb7-8978-6629216943a0/v1/voices/de-DE_DieterV3Voice"
}  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  141k    0  141k  100    70  95367     46  0:00:01  0:00:01 --:--:-- 95965
```
### Additional information

List of used API calls:

* [voices](https://cloud.ibm.com/apidocs/text-to-speech#listvoices)
* [custom models](https://cloud.ibm.com/apidocs/text-to-speech#createcustommodel)
* [custom words](https://cloud.ibm.com/apidocs/text-to-speech#addwords)
* [API Documentations](https://watson-developer-cloud.github.io/swift-sdk/services/TextToSpeechV1/index.html)
* [Application Node.js example](https://github.com/watson-developer-cloud/speech-to-text-nodejs)


