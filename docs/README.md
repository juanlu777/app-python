#	Virtualización de Sistemas
#	Práctica 3
#	Juan Luis Sena Cárdenas

-	# Configuración personalizada de la imagen de Jenkins
	
    [Configuración Jenkins](Dockerfile)
    
    Para empezar explicaré cómo he configurado la imagen personalizada de Jenkins, en la primera línea está la imagen base que vamos a descargar de dockerhub (jenkins/jenkins) a partir de esta imagen podemos crear un contenedor que ejecuta una aplicación Jenkins, no obstante vamos a personalizar dicha imagen instalando algunas herramientas útiles, la segunda línea nos servirá para ejecutar comandos como usuario root ya que ejecutaremos comandos que requieren privilegios de administrador, la tercera línea es para ejecutar un comando que actualiza el sistema gestor de ficheros e instala la herramienta lsb-release que sirve para ofrecernos información sobre la distribución GNU/Linux que tiene la imagen, los siguientes 3 comandos que ejecutaremos serán necesarios para poder ejecutar comandos docker dentro del contenedor de Jenkins.
	En este punto hemos ejecutado todos los comandos que hacía falta ejecutar con privilegios de administrador, así que en la línea 11 cambiamos de root a un usuario de nombre jenkins y finalmente con el último comando instalamos la herramienta blueocean en nuestro contenedor Jenkins para poder observar la evolución del flujo de trabajo descrito en el pipeline desde la interfaz de blueocean

-	# Configuración de la infraestructura
	
    [Configuración infraestructura](resources.tf)
    [Variables de entorno](variables.tf)
    
    A continuación se describirá la configuración de la infraestructura (configuración del contenedor Jenkins, configuración contenedor dind, redes, volúmenes...) definida en el fichero resources.tf, en el fichero variables.tf están definidas las variables de entorno que se utilizarán en la configuración.
    - Herramientas
    
    	Primero definimos cuáles serán las herramientas requeridas para construir la infraestructura, en este caso la creamos con la herramienta docker, y especificamos también la ruta donde se encuentra la herramienta docker dentro de la máquina que nos proveerá de  la herramienta (en source) y especificamos también la versión de Docker que utilizaremos (en version) [líneas 1-8].
    
    - Proveedor
    	
        Posteriormente ponemos la máquina que nos proveerá de la herramienta Docker (en host) [líneas 10-12].
    
    - Red
    	
        Crearemos un contenedor Jenkins y un contenedor que ejecute Docker para que el contenedor Jenkins pueda ejecutar comandos Docker ya que los entornos donde se ejecutarán las diferentes etapas del flujo de trabajo descrito en el pipeline serán contenedores Docker, así que para que se puedan enviar mensajes entre el contenedor Jenkins y el que ejecuta Docker necesitamos definir una red a la que se conectarán ambosy así poder comunicarse entre ellos, dicha red es la definida en [líneas 14-16].
    
    - Volúmenes
    	
        Necesitamos también crear 2 volúmenes, uno donde se almacenará la información correspondiente a los certificados TLS que servirán para proteger los datos enviados de un contenedor a otro, cifrándolos y guardando información sobre qué contenedores son los únicos que tienen acceso a dichos datos, el otro volumen será para almacenar todos aquellos datos necesarios en la aplicación Jenkins como nombre y contraseña de todos los usuarios registrados, información sobre los proyectos que se han creado..., con esto conseguimos que a pesar de que eliminemos los contenedores Jenkins y dind (contenedor que almacena Docker) no perdamos esta información [líneas 18-24].
    
    - Imagen dind
    	
        Lo siguiente será declarar cuál será la imagen desde la que crearemos el contenedor dind [líneas 26-29].
    Y por último definimos la configuración de los contenedores Jenkins y dind
    
    -	Contenedor dind
    	
        Especificamos cuál será la imagen a partir de la cual crearemos el contenedor dind (en image), dicha imagen será la que especificamos anteriormente (docker:dind), luego elegimos el nombre que tendrá el contenedor (en name), marcamos los campos rm y provileged a true para que así una vez paremos la ejecución del contenedor éste se elimine (rm=true) y para poder tener todos los privilegios necesarios para ejecutar comandos dentro del contenedor (privileged=true).
        Luego en networks_advanced especificamos en el campo name el nombre de la red a la que se conectará el contenedor dind (la red que configuramos anteriormente) y en aliases ponemos la lista de alias que tendrá el contenedor dind dentro de la red, de esta manera el resto de contenedores pertenecientes a la red podrán identificar al contenedor dind mediante estos alias, solamente pondremos un alias que es el que le asignamos a la variable de entorno alias_network_docker (ver variables.tf).
        En env ponemos la lista de variables de entorno que tendrá el contenedor dind, en este caso solo pondremos una, (DOCKER_TLS_CERTDIR), donde se almacenará la ruta dentro del contenedor donde se encuentran los certificados TLS, dicha ruta la especificamos en una variable de entorno llamada ruta_cont_TLS así que se lo asignaremos a DOCKER_TLS_CERTDIR.
        Declaramos ahora los volúmenes que utilizará este contenedor para guardar tanto los certificados TLS como los datos de Jenkins, para los certificados TLS  utilizamos el volumen que creamos para almacenarlos para ello en volumes ponemos en el campo volume_name el nombre de dicho volumen y en container_path la ruta dentro del contenedor de la que el volumen leerá los certificados y en la que los escribirá cuando se elimine y se vuelva a crear el contenedor, dicha ruta la tenemos almacenada en ruta_cont_TLS mencionada anteriormente, dentro de esta ruta se creará el directorio client que es donde se almacenarán los certificados.
        En otra sección volumes declaramos el volumen donde almacenamos los datos de Jenkins, así que en volume_name especificamos el nombre de dicho volumen y en container_path la ruta dentro del contenedor donde el volumen leerá los datos de Jenkins y los escribirá cuando el contenedor se elimine y se vuelva a crear, dicha ruta está especificada en una variable de entorno llamada ruta_datos_jenkins (en variables.tf)
        Por último en la sección ports especificamos el puerto que se expondrá del contenedor dind, en este caso para que el contenedor Jenkins pueda enviar peticiones a dind exponemos el puerto 2376.

	- Contenedor Jenkins
		
        Configuramos ahora el contenedor Jenkins, lo crearemos a partir de la imagen que personalizamos en el Dockerfile anterior, así que a image le asignamos el nombre de esa imagen (importante, al crear la imagen con el comando docker build le pondremos un nombre, ese mismo nombre es el que hay que asignarle a image), en name le asignamos un nombre al contenedor Jenkins, al campo restart le asignamos la cadena "on-failure" para que se reinicie el contenedor en caso de fallo.
        En networks_advanced especificamos la red a la que conectaremos el contenedor Jenkins que será la misma a la que conectamos el contenedor dind.
        En env declaramos la lista de variables de entorno del contenedor Jenkins, que serán:
        - DOCKER_HOST: donde se especifica el socket de la máquina que contiene los certificados TLS (el contenedor dind) que está compuesto por (alias_network_docker:2376, alias del contenedor dind dentro de la red y el puerto donde escucha las peticiones) delante ponemos que se utiliza el protocolo tcp para transmitir datos entre Jenkins y dind 
         
        - DOCKER_CERT_PATH: donde especificamos la ruta dentro del contenedor Jenkins donde se guardarán los certificados TLS (misma que la del contenedor dind).
        
        - DOCKER_TLS_VERIFY: le asignamos 1 para que se verifiquen los certificados TLS
        
     	En las secciones ports exponemos los puertos del contenedor Jenkins, en este caso el 8080 que lo mapearemos al 8081 de la máquina local para poder acceder desde el navegador a la página de Jenkins, y el 50000.
     	Por último declaramos los volúmenes que utilizaremos para almacenar los certificados TLS y los datos de Jenkins (mismos volúmenes y rutas que en el contenedor dind)
     
- #	Crear contenedores y ejecutar pipeline en Jenkins

	Lo primero que haremos será crear la imagen personalizada de Jenkins, para ello nos ubicamos desde la terminal en el directorio donde se encuentre el Dockerfile y ejecutamos el siguiente comando: docker build -t [nombre_imagen] . (importante que el nombre que le pongamos a la imagen sea el mismo que especificamos en el campo image de la configuración del contenedor Jenkins).
    Luego nos ubicamos en el directorio donde se encuentren los ficheros resources.tf y variables.tf y ejecutamos terraform init seguido de terraform apply para que de este manera se creen todos los recursos que formarán parte de la infrestructura (contenedores Jenkins y dind, red y volúmenes).
    Como mapeamos el puerto 8080 del contenedor Jenkins al 8081 de nuestra máquina local, introducimos en el navegador http://localhost:8081 y nos aparecerá el asistente de configuración que nos pedirá una contraseña para poder iniciar la configuración inicial de Jenkins, nos mostrará una ruta dentro del contenedor de Jenkins que es el fichero donde se encuentra dicha contraseña, así que accedemos a la terminal del contenedor y nos movemos a dicha ruta e imprimimos por pantalla el contenido del fichero, copiamos la contraseña y la introducimos en la barra de la página del asistente:
    - docker exec -it [id_contenedor_jenkins] bash: para acceder a la terminal del contenedor Jenkins
    
    - cat [ruta_indicada]: para imprimir por pantalla la contraseña

	A continuación seleccionamos la opción Instalar plugins sugeridas y esperamos a que se instalen las plugins, luego nos aparecerá un formulario para que nos creemos nuestro primer usuario administrador (rellenamos el formulario con los datos que nos piden), por último nos piden que introduzcamos la URL para acceder a la web de Jenkins, la dejamos igual para que solo tengamos que poner en el navegador http://localhost:8081 para volver a acceder a la página de Jenkins.

	Por último ejecutaremos el pipeline que aparece en el Jenkinsfile en la carpeta jenkins del repositorio, para compilar, testear y desplegar la aplicación python del tutorial, como en el tutorial viene ya explicado el pipeline no es necesario que lo vuelva a explicar en este fichero. Para ejecutar el pipeline seleccionamos la opción Nueva tarea a la izquierda de la página Jenkins, introducimos el nombre del proyecto y seleccionamos Pipeline y le damos a OK. Nos aparecerá otro formulario, en la sección Pipeline: 
    - En Definition seleccionamos Pipeline script from SCM 
    - En SCM seleccionamos Git
    - En Repository URL introducimos la URL del repositorio en el que se encuentra el Jenkinsfile 
    - En Credentials no introducimos nada ya que se trata de un repositorio público
    - En Branch Specifier introducimos la rama main del repositorio que es en la que tenemos configurado el Jenkinsfile y demás.
    - En Script Path ponemos la ruta en la que se encuentra el Jenkinsfile dentro del repositorio
    - Por último le damos a Apply y Guardar
    
	Ahora que tenemos nuestro proyecto Jenkins enlazado al repositorio donde se encuentra el Pipeline, seleccionamos la opción Construir ahora que aparece a la izquierda para que se ejecute el flujo de trabajo definido en dicho Pipeline, cada ejecución que hagamos del pipeline queda identificado por un número que podemos ver en la esquina inferior izquierda, una vez haya finalizado el flujo de trabajo (se indica con un tick verde al lado de dicho número) tendremos el ejecutable de la aplicación en el contenedor Jenkins en la ruta var/jenkins_home/workspace/app_python/[num_ejecución_pipeline]/sources/dist, nos movemos a dicha ruta desde la terminal del contenedor y ejecutamos la aplicación:
    
    - docker exec -it [id_contenedor_jenkins] bash: para acceder a la terminal del contenedor Jenkins
    - cd var/jenkins_home/workspace/app_python/[num_ejecución_pipeline]/sources/dist para desplazarnos al directorio donde se encuentra el ejecutable
    - ./add2vals [primer_param] [segundo_param] para ejecutar la aplicación pasándole los 2 parámetros desde la terminal.

