# Repositorio de infraestructura en Azure de Chefcito

### Introduccion

En este repositorio se encuentran definidos los servicios que se utilizan para realizar el despliegue del
sistema de Back-End, Front end web de locales y de reservas de *Chefcito*.

#### Front end Web

El Front end Web tanto de reservas como de locales se encuentra desplegado utilizando el servicio de 
*Static Web App* de Azure. El despliegue de la Web App se realiza utilizando este repositorio, pero el 
despliegue de la aplicacion Web se realiza desde [este repositorio](https://github.com/Chefcito-Comidas/ReactApp).

#### Back End

El sistema de Back end de chefcito se despliega utilizando *Container Apps* de la siguiente manera:

1. Un *Container App Environment* para alojar todos los servicios de Chefcito
2. Un *Container App* por cada uno de los servicios de Chefcito
3. Un *Container Registry* para alojar las imagenes de contenedores de cada uno de los servicios.

Ademas, las bases de datos, tanto Mongo como Postgresql se encuentran desplegadas en Azure utilizando
los siguientes servicios:

1. Para Postgresql se utiliza *Azure Database for PostgreSQL*
2. Para MongoDB se utiliza *Azure Cosmos DB for MongoDB*

Finalmente, los secretos sencibles del sistema se protejen utilizando *Azure Key Vault*


### Instructivo de uso de este repositorio

#### Pasos previos

##### Creacion de una cuenta de GCP (Google Cloud Provider)

En primer lugar, es necesario tener una cuenta de GCP para poder realizar
el despliegue del sistema sobre Azure. Esto se debe a que Chefcito utiliza
*Firebase* por un lado, para realizar la gestion de los usuarios y la persistencia
de imagenes utilizadas por la aplicacion y por otro lado, el sistema utiliza *Vertex*
para realizar los resumenes de opiniones.

Para realizar la configuracion por consola en GCP necesaria para tener acceso a *Vertex* se tienen que seguir los siguientes pasos:

1. Crear un proyecto para el sistema.
2. Buscar el servicio de *Vertex* y activarlo para el proyecto de chefcito 
3. Ir a la consola de *IAM y administracion*
4. Seleccionar *Cuentas de servicio* y *Crear cuenta de servicio*
5. En la creacion de la cuenta de servicio, otorgarle el rol de *Agente de servicio de Vertex AI*
6. Seleccionar *Administrar Claves* para la cuenta de servicio creada.
7. Crear una nueva clave de tipo JSON.

> Es necesario guardar dos cosas, por un lado, la clave recien creada (que se debe codificar a base 64) y por otro lado el Id de la misma.

##### Creacion de un proyecto de Firebase

En primer lugar, se debe ingresar a la consola de *Firebase* y crear un nuevo proyecto.
Una vez creado el proyecto de firebase, se puede obtener la API key (necesaria para realizar el despliegue de infraestructura)
de la siguiente manera:

1. Ir a la consola del proyecto en *Firebase*.
2. En *Descripcion general* seleccionar configuracion del proyecto.

##### Creacion de una cuenta de Twilio

1. Crear una cuenta de twilio
2. Guardar el SID de la cuenta (referido en un futuro como TWILIO_KEY_ID)
3. Guardar el token de autenticacion de la cuenta (referido en un futuro como TWILIO_KEY)

##### Creacion de una cuenta de servicio de Azure

Se debe seguir el [siguiente instructivo](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal)
y asignarle al service principal creado permisos de contributor sobre la subscripcion donde
se desplegara el sistema.

Del service principal es necesario guardarse el *Client Id* y el *Client Secret*

#### Despliegue en Azure utilizando github actions

1. Se deben definir las siguientes variables open tofu, las mismas se tienen que definir como secretos de github actions de la siguiente manera:
-   firebase_key (requerida), se debe definir como un secreto de nombre *FIREBASE_KEY* 
-   db_password  (requerida), se debe definir como un secreto de nombre *DB_PASSWORD* (puede ser cualquier string utf-8, es la clave que utilizara la base de datos Postgresql)
-   db_username  (requerida), se debe definir como un secreto de nombre *DB_USERNAME* (puede ser cualquier string utf-8, es el nombre de usuairo de la base de datos)
-   vertex_key   (requerida), se debe definir como un secreto de nombre *VERTEX_KEY* (esta variable tiene que ser la key de un usuario de GCP con permisos necesarios para acceder al servicio de Vertex Garden, la clave debe estar codificada en base 64)
-   vertex_key_id (requerida), se debe definir como un secreto de nombre *VERTEX_KEY_ID* (es el id de la clave del usuario de vertex)
-   twilio_key  (requerida), se debe definir como un secreto de nombre *TWILIO_KEY* (es la API Key de twilio que se utiliza para enviar notificaciones a utilizando WhatsApp)
-   twilio_key_id (requerida), se debe definir como un secreto de nombre *TWILIO_KEY_ID* (es el id de la API Key de twilio)

2. Se deben definir los siguientes secretos de github actions:
-   ARM_CLIENT_ID, Id del usuario de IAM de Azure creado para realizar los despliegues utilizando Open Tofu
-   ARM_CLIENT_SECRET, Secreto del usuario de Azure
-   ARM_SUBSCRIPTION_ID, ID de la subscripcion sobre la que se quiere desplegar los servicios.
-   ARM_TENANT_ID, Id del tenant de Azure.

3. Una vez completados los puntos anteriores, el pipeline se puede ejecutar desde 
la rama *main* del repositorio.
> Cada vez que se realiza un push al repositorio de github, el mismo ejecuta el pipeline de Open Tofu para realizar los cambios que correspondan a la infraestructura en nube

Al ejecutar el pipeline por primera vez, el mismo fallara. Esto se debe a que en el *Container Registry* creado
no existen imagenes aun. Para ello se tiene que ejecutar el pipeline de deploy de [este repositorio](https://github.com/Chefcito-Comidas/chefcito-back).
Una vez ejecutado el otro pipeline, puede volver a ejecutarse este pipeline para finalizar el despliegue del sistema.

