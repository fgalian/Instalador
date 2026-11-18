# Instalador

## ¿Qué es?

Este proyecto es una herramienta para preparar equipos con Windows 11. Ofrece una interfaz gráfica desde la que se pueden seleccionar e instalar varias aplicaciones y componentes habituales en una sola operación, sin tener que ejecutar cada instalador por separado.

## ¿Para qué sirve?

Está pensado para agilizar la configuración inicial de un equipo, por ejemplo, después de instalar Windows o al preparar un ordenador para un nuevo usuario. Agrupa el software por categorías y permite elegir aplicaciones individualmente o usar perfiles de selección. Antes de instalar, detecta los elementos que ya están presentes; las instalaciones se realizan en secuencia y se registra su resultado en archivos de log.

El catálogo incluye aplicaciones de ofimática, multimedia, utilidades, administración y desarrollo, además de la pestaña `Frameworks`, que ofrece Microsoft Visual C++ Redistributable 2015-2022 x64/x86, .NET Desktop Runtime 8 y 10, y la opción de habilitar .NET Framework 3.5. La mayoría de los paquetes se instala mediante `winget`, que viene con App Installer. Si no está disponible, el programa intenta registrar App Installer y muestra un botón para abrir su ficha oficial de Microsoft Store. Tras instalarlo, pulsa `Actualizar detección`. .NET Framework 3.5 se habilita mediante las características de Windows.

## Cómo ejecutarlo

Ejecuta `instalar.bat` para abrir el selector de aplicaciones. El lanzador solicita permisos de administrador mediante UAC y usa `-ExecutionPolicy Bypass` solo para el proceso de PowerShell que ejecuta el instalador; no cambia la politica permanente del equipo.

Debes aceptar el aviso de UAC y disponer de una cuenta con permisos de administrador. Una politica impuesta por la organizacion puede impedir la ejecucion incluso con este lanzador.

En las versiones modernas de Windows 11, .NET Framework 4.8.1 ya forma parte del sistema. El instalador no lo agrega como paquete independiente.