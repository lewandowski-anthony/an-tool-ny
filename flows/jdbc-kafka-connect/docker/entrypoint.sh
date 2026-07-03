#!/bin/sh

HOME=/home/appuser
VAULT_HOME=/vault/secrets

exit_if_file_does_not_exist () {
  if [ ! -f "$1" ]; then
    echo "$1 does not exist" 1>&2
    exit 4
  fi
}

echo 'Start creating/updating your kafka connectors'
if [ -z "$CONNECTORS_FILENAMES" ];then
  echo "Error : CONNECTORS_FILENAMES variable is empty" 1>&2
  exit 1
fi

if ! [[ "$CONNECTORS_FILENAMES" =~ ^([A-Za-z][A-Za-z_-]+\.json,){0,10}([A-Za-z][A-Za-z_-]+\.json)$ ]];then
  echo "Sorry, but you are not respecting the CONNECTORS_FILENAMES regex. Here's the rules :"
  echo "Regex : ^([A-Za-z][A-Za-z_-]+\.json,){0,10}([A-Za-z][A-Za-z_-]+\.json)$"
  echo "Your input must start with a letter"
  echo "Your input must end with .json"
  echo "You can introduce multiple connectors filenames and separate them with commas"
  echo "Each filename must end with .json"
  echo "Each filename will be considered as the connector name"
  echo "You can use letters and the characters _ or - in your filename"
  echo "You can introduce from 1 to 11 connectors"
  echo "Error : CONNECTORS_FILENAMES variable does not respect the regex" 1>&2
  exit 2
fi

if [ ${GENERATE_CERTIFICATES,,} = "true" ]; then #Ignore the case

    echo 'Start generating KEYSTORE and TRUSTSTORE'

    CA_CERTIFICATE_PATH=$VAULT_HOME"/"CA_CERTIFICATE
    USER_ACCESS_KEY_PATH=$VAULT_HOME"/"USER_ACCESS_KEY
    USER_ACCESS_CERTIFICATE_PATH=$VAULT_HOME"/"USER_ACCESS_CERTIFICATE
    KAFKA_KEYSTORE_PASSWORD_PATH=$VAULT_HOME"/"KAFKA_KEYSTORE_PASSWORD
    KAFKA_TRUSTSTORE_PASSWORD_PATH=$VAULT_HOME"/"KAFKA_TRUSTSTORE_PASSWORD

    exit_if_file_does_not_exist $CA_CERTIFICATE_PATH
    exit_if_file_does_not_exist $USER_ACCESS_KEY_PATH
    exit_if_file_does_not_exist $USER_ACCESS_CERTIFICATE_PATH
    exit_if_file_does_not_exist $KAFKA_KEYSTORE_PASSWORD_PATH
    exit_if_file_does_not_exist $KAFKA_TRUSTSTORE_PASSWORD_PATH

    #Generate KEYSTORE and TRUSTSTORE
    mkdir -p /kafka/.pki/
    cd /kafka/.pki/

    echo 'Moving certificates files'
    cp $CA_CERTIFICATE_PATH certificate.pem
    cp $USER_ACCESS_KEY_PATH user-access.key
    cp $USER_ACCESS_CERTIFICATE_PATH user-access.cert
    kafka_keystore_password=$(cat $KAFKA_KEYSTORE_PASSWORD_PATH)
    kafka_truststore_password=$(cat $KAFKA_TRUSTSTORE_PASSWORD_PATH)

    if [ ${DISPLAY_CERTIFICATES,,} = "true" ]; then
      ls -ltr
      echo 'CA_CERTIFICATE | Broker Certificate | certificate.pem'
      cat certificate.pem
      echo 'USER_ACCESS_KEY | Private Key | user-access.key'
      cat user-access.key
      echo 'USER_ACCESS_CERTIFICATE | Public Key | user-access.cert'
      cat user-access.cert
    fi

    echo 'Generating the keystore'
    openssl pkcs12 -export -inkey user-access.key -in user-access.cert -out kafka.keystore.p12 -name service_key -password pass:$kafka_keystore_password
    echo 'Generating the truststore'
    keytool -import -file certificate.pem -alias CA -keystore kafka.truststore.jks  -storepass $kafka_truststore_password -noprompt
fi

user_connectors=($(echo $CONNECTORS_FILENAMES | tr "," "\n"))
echo 'Start iterating ...'
for user_connector_file in "${user_connectors[@]}";
do
  echo "Connector file name : '"$user_connector_file"' file"
  user_connector_name=$(echo $user_connector_file | cut -d '.' -f 1)
  user_connector_file_path=$VAULT_HOME"/"$user_connector_file
  echo "Connector name : '"$user_connector_name"'"
  echo "Connector path : '"$user_connector_file_path"'"
  echo $(ls -ltr $user_connector_file_path)
  echo "Building the connector json creation file"
  user_connector_create_file_path=${HOME}"/"${user_connector_name}_create.json
  echo "{
  \"name\": \"${user_connector_name}\",
  \"config\": $(cat ${user_connector_file_path})
}" > $user_connector_create_file_path
  cat $user_connector_create_file_path
  echo "Showing your json update file"
  cat $user_connector_file_path
  while true;
    do code=$(curl -s -o /dev/null -w "%{http_code}" -H "Accept:application/json" -H "Content-Type:application/json" $HOSTNAME:8083/);
      if [[ $code -eq 200 ]]; then
        echo "Kafka connect is ready"
        echo "Waiting for connectors to be initialized if it exists"
        sleep 10
        echo "Checking if the connector ${user_connector_name} exists"
        curl -X GET -H "Accept:application/json" -H "Content-Type:application/json" $HOSTNAME:8083/connectors/
        curl -i -s -X GET -H "Accept:application/json" -H "Content-Type:application/json" $HOSTNAME:8083/connectors/ | grep "$user_connector_name"
        if ! [[ $? -eq 0 ]]; then
          echo "Connector "$user_connector_name" does not exist yet"
          curl -s -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" $HOSTNAME:8083/connectors/ --data @$user_connector_create_file_path
        else
          echo "Connector "$user_connector_name" already exists - updating"
          curl -s -i -X PUT -H "Accept:application/json" -H "Content-Type:application/json" $HOSTNAME:8083/connectors/$user_connector_name/config --data @$user_connector_file_path
        fi
        break
      else
        sleep 1
      fi
    done
done &

if [ ${USE_PROXYCHAINS,,} = "false" ]; then
  /etc/confluent/docker/run
else
  proxychains4 -f /etc/proxychains/proxychains.conf -q /etc/confluent/docker/run
fi

