### Listeners configuration

- each broker sets up listeners:<br>
  `KAFKA_LISTENERS: 'INTERNAL://:9092,EXTERNAL://:19092'`
    - INTERNAL://:9092 - listens for incoming connection inside docker network
    - EXTERNAL://:19092 - listens for incoming connections from outside of docker network

- each broker remaps security protocols: <br>
  `KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: 'CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT'`
  so that external protocol EXTERNAL is mapped to PLAINTEXT

- each broker sets up advertised listeners (to be used on client side to connect to kafka):<br>
  `KAFKA_ADVERTISED_LISTENERS: 'INTERNAL://<LOCAL_NAME>:19092,EXTERNAL://<EXTERNAL_NAME>:<EXTERNAL_PORT>'`
    - INTERNAL://<LOCAL_NAME>:9092 - to be used by clients within cluster, where <LOCAL_NAME> is FQDN within a cluster
    - EXTERNAL://<EXTERNAL_NAME>:<EXTERNAL_PORT> - to be used outside of a cluster network.
  ! <EXTERNAL_PORT> should be mapped to 19092 container port
  <EXTERNAL_NAME> either host IP or hostname or FQDN or etc (e.g `localhost`, or minikube IP)

e.g.
```
    container_name: kafka-1
    environment:
     ...
      KAFKA_LISTENERS: 'PLAINTEXT://:9092,EXTERNAL://:19092'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: 'PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT'
      KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka-1:19092,EXTERNAL://<host_ip>:30000'
     ...
   ___
    and somewhere in service:
      type: NodePort
    ports:
      - name: tcp-broker
        port: 19092
        nodePort: 30000
        protocol: TCP
        targetPort: 19092
```