# Kafka Connect JDBC Source

This image is a connect base that can holds any Kafka connector of type JDBC source
This image is not meant to be used as is in production. It is only a base that helps you into the creation of you connectors in production.
To use it, you have to create your own image and extends this one then configure it.

## Build on your local

Go to the **local** directory and run this command :

````shell
$ docker-compose up --build
````

This will build and run the kafka connect image in a kafka environment (kafka, zookeeper, schema registry, akhq).

## How to use it

This image helps you to create your connectors and configure the SSL part.

### Create/Update connectors

You need only to pass the connectors vault keys to as environment variable. Example of the K8s Manifest file :

````yaml
  env:
    - name: CONNECTORS_FILENAMES
      value: network-jdbc-connector.json
````

with multiple connectors :

````yaml
  env:
    - name: CONNECTORS_FILENAMES
      value: network-jdbc-connector.json,purchasemethod-jdbc-connector.json
````

**The image will use the file name (network-jdbc-connector or purchasemethod-jdbc-connector in the example) as the connector name**

It will also look for these files under **/vault/secrets**. So make sure to add a key to your Vault (network-jdbc-connector.json for example).

Don't forget to upload the file into your secret store :
````yaml
data:
  - secretKey: network-jdbc-connector.json
    remoteRef:
      key: jdbc-connectors/network-jdbc-connector/eu
      property: network-jdbc-connector.json
````

And to upload the secret store as volume (mounted on /vault/secrets) :

````yaml
- name: network-jdbc-connector-secret-volume
  readOnly: true
  mountPath: "/vault/secrets"
````

The Vault content must your connector description file in this format (as we said, we consider the vault key as the connector name) :
````json
{
    "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
    "tasks.max": 1,
    "mode": "timestamp",
    "timestamp.column.name" : "last_update_date",
    "query" : "",
    "connection.url":"jdbc:oracle:thin:@{YOUR_DATABASE_URL}:1532:orcl",
    "connection.user":"{YOUR_DATABASE_USER}",
    "connection.password":"{YOUR_DATABASE_PASSWORD}",
    "db.timezone" : "Europe/Paris",
    "numeric.mapping" : "best_fit"
}
````

### Generate certificates

**PN : You can upload your certificates and configure your connector if you want without using this feature**

If you want the image to handle the certificates generation, you have to pass these variables to the runtime.
Here's an example.

Activate the feature :

````yaml
- name: GENERATE_CERTIFICATES
  value: 'true'
````

You can debug certificates using this variable :
````yaml
- name: DISPLAY_CERTIFICATES
  value: 'true'
````

Make sure to load these files on your secret-store and to mount them under **/vault/secrets**:

````yaml
- name: CA_CERTIFICATE
  valueFrom:
    secretKeyRef:
      name: network-jdbc-connector-secret
      key: CA_CERTIFICATE
- name: USER_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: network-jdbc-connector-secret
      key: USER_ACCESS_KEY
- name: USER_ACCESS_CERTIFICATE
  valueFrom:
    secretKeyRef:
      name: network-jdbc-connector-secret
      key: USER_ACCESS_CERTIFICATE
- name: KAFKA_KEYSTORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: network-jdbc-connector-secret
      key: KAFKA_KEYSTORE_PASSWORD
- name: KAFKA_TRUSTSTORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: network-jdbc-connector-secret
      key: KAFKA_TRUSTSTORE_PASSWORD
````

- Don't modify the **name** part from the secret store (but you are free to modify them on the vault). The image looks for CA_CERTIFICATE, USER_ACCESS_KEY, USER_ACCESS_CERTIFICATE, KAFKA_KEYSTORE_PASSWORD and KAFKA_TRUSTSTORE_PASSWORD under **/vault/secrets**
- You don't need to pass these parameters as environment variables to the connector container
