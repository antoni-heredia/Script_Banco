#!/bin/bash
source FuncionesBanco.sh
RUTA=$(RutaBanco)
CLIENTES="$RUTA/clientes.conf"
case $1 in
	-u)DevolverUsuarios $2
	   exit;;
	-b)CopiaSeguridad
	   exit;;
esac
echo "----------------------------Bienvenido a Banco Terobo----------------------------"
echo "Fecha de hoy: "$(date)
if ! [ -e $CLIENTES ];then
	touch $CLIENTES
	echo "NumeroCuenta:Apellidos:Nombre:Fecha" > $CLIENTES
fi
Menu
