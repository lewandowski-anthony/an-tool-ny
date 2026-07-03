# Kafka Connect JDBC Source

This image is a Kafka Connect base image for JDBC source connectors. It is not intended to be used directly in production. Instead, create your own image from this one, add your connector configuration, and extend it for your deployment needs.

## Build on your local

Go to the **local** directory and run this command:

````shell
$ docker-compose up --build
````

This builds and runs the Kafka Connect image in a local Kafka environment (Kafka, Zookeeper, Schema Registry, and AKHQ).

## How to use it

Use this image as a base for creating connectors and configuring SSL support.

### Create/Update connectors

Pass the connector Vault keys as an environment variable. Example Kubernetes manifest:

````yaml
  env:
    - name: CONNECTORS_FILENAMES
      value: network-jdbc-connector.json
````

With multiple connectors:

````yaml
  env:
    - name: CONNECTORS_FILENAMES
      value: network-jdbc-connector.json,purchasemethod-jdbc-connector.json
````

**The image will use the file name (network-jdbc-connector or purchasemethod-jdbc-connector in the example) as the connector name**

It will also look for these files under **/vault/secrets**. Make sure to add a matching key to your Vault, such as network-jdbc-connector.json.

Don't forget to upload the file into your secret store:
````yaml
data:
  - secretKey: network-jdbc-connector.json
    remoteRef:
      key: jdbc-connectors/network-jdbc-connector/eu
      property: network-jdbc-connector.json
````

And mount the secret store as a volume on **/vault/secrets**:

````yaml
- name: network-jdbc-connector-secret-volume
  readOnly: true
  mountPath: "/vault/secrets"
````

The Vault content must contain your connector description file in this format. As noted above, the Vault key is used as the connector name:
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

**Note:** You can upload your certificates and configure your connector without using this feature.

If you want the image to handle certificate generation, pass these variables at runtime. Here's an example.

Activate the feature:

````yaml
- name: GENERATE_CERTIFICATES
  value: 'true'
````

You can debug certificates using this variable:
````yaml
- name: DISPLAY_CERTIFICATES
  value: 'true'
````

Make sure to load these files on your secret store and mount them under **/vault/secrets**:

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

- Do not modify the **name** part from the secret store, although you can change the Vault-side names. The image looks for CA_CERTIFICATE, USER_ACCESS_KEY, USER_ACCESS_CERTIFICATE, KAFKA_KEYSTORE_PASSWORD and KAFKA_TRUSTSTORE_PASSWORD under **/vault/secrets**.
- You do not need to pass these parameters as environment variables to the connector container.
