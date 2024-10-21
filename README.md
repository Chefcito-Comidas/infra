# Utilizacion de Kubernetes

### Algunas restricciones

Este repositorio tiene las definiciones para desplegar los servicios de *chefcito*. Sin embargo,
no tiene definiciones de las bases de datos del sistema.
Las mismas son actualmente externas y se utiliza por defecto las bases de datos desplegadas
en Azure.

### Arquitectura del despliegue

Los servicios de chefcito se despliegan por defecto con una replica para cada uno
utilizando deployments de kubernetes y un *container registry* propio del cluster 
sobre el cual se despliegan los servicios.
Cada deployment tiene asociado un Node Port para su exposicion desde el cluster. Sin
embargo se debe exponer unicamente el deployment de gateway. 

### Variables a definir para ejecutar el codigo

1. *db_string* => String de conexion con la base de datos relacional (Postgresql)
2. *mongo_string* => String de conexion con la base de datos MongoDB
3. *twilio_sid* => Id de la cuenta de twilio a utilizar
3. *twilio_token* => Token de la cuenta de twilio
4. *firebase_key* => API key del proyecto de firebase
5. *vertex_key* => Credenciales de la cuenta de servicio de GCP codificadas en base 64
6. *vertex_key_id* => Id de las credenciales de Vertex

> Para saber como obtener cada uno de estos datos, se puede tomar como referencia la rama main de este repositorio.

### Desplegando el sistema utilizando Minikube

1. En primer lugar, se debe instalar *Minikube*. Para ello se puede seguir [esta guia](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download)
2. Una vez instalado minikube, se debe ejecutar el siguiente comando:
```bash
minikube start
```
3. Las imagenes de los servicios de chefcito se tienen que subir al registry de *Minikube*, eso se puede hacer de la siguiente manera:
```bash
eval $(minikube docker-env) && chefcito build
```
> Este comando se debe ejecutar parado en el root del proyecto de chefcito.
4. Con las imagenes de chefcito desplegadas en el cluster local. Ejecutar el siguiente comando:
```bash
tofu apply --auto-approve
```

### Desplegando el sistema en otro cluster de *Kubernetes*

Para desplegar el sistema de chefcito en un cluster de kubernetes
que no sea el minikube local, se puede modificar el archivo **~/.kube/config**
para que apunte al cluster correspondiente y utilice las credenciales adecuadas.

