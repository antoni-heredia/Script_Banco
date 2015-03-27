#!/bin/bash
function ComprobarNumero(){
	local NUMERO=$1
	local CADENA='^[0-9]+$'	
	if [[ $NUMERO =~ $CADENA ]];then
		return 0
	else
		return 1
	fi
}
function RutaBanco(){
	local line
	local ARCHIVO=banco.config
	local RUTAS
	local RUTA	
	while read line;do
		RUTAS=$(echo $line | cut -d = -f 1)
		if [ "$RUTAS" = "DIR_BANCO" ];then
			RUTA=$(echo $line | cut -d = -f 2)
			echo $RUTA
			return 0	
		fi	
	done < banco.config
}
function RutaCuenta(){
	local NUMEROCUENTA=$1
	local RUTABANCO=$(RutaBanco)
	local RUTACUENTA
	RUTACUENTA=$RUTABANCO/"c"$NUMEROCUENTA".cue"
	echo $RUTACUENTA
}
function DevolverUsuarios(){
	local line
	local ELEGIDO=$1
	local APELLIDOS
	local APELLIDO1
	local APELLIDO2
	local NOMBRE
	local NOMBRE1
	local NOMBRE2
	local NUMERO
	local FILE=$(RutaBanco)/clientes.conf
	while read line;do
		APELLIDOS=$(echo $line | cut -d : -f 2)
		NOMBRE=$(echo $line | cut -d : -f 3)
		NUMERO=$(echo $line | cut -d : -f 1)
		APELLIDO1=$(echo $APELLIDOS | cut -d " " -f 1)
		APELLIDO2=$(echo $APELLIDOS | cut -d " " -f 2)
		NOMBRE1=$(echo $NOMBRE | cut -d " " -f 1)
		NOMBRE2=$(echo $NOMBRE | cut -d " " -f 2)
		if [ "$APELLIDO1" = "$ELEGIDO" -o "$APELLIDO2" = "$ELEGIDO" -o "$NOMBRE1" = "$ELEGIDO" -o "$NOMBRE2" = "$ELEGIDO" ];then
			echo "$NOMBRE $APELLIDOS":"$NUMERO"	
		fi
	done < $FILE
}
function CrearCuenta(){
	local RUTA=$(RutaBanco)
	local FILE=$RUTA/clientes.conf
	local SALDOINICIAL
	local NOMBRE
	local APELLIDOS
	local LASTNUM
	local NUMERO
	local DESCUBRIMIENTO=0
	local CONTROL=0
	local FECHA=$(date +"%d/%m/%Y")
	echo "----------------------Crear cuenta----------------------"
	while [ $CONTROL = 0 ];do
		read -p "¿Cual es el saldo inicial? " SALDOINICIAL
		if  ComprobarNumero $SALDOINICIAL;then
			CONTROL=1
		else
			echo "El saldo introducido es incorrecto"
		fi
	done
	read -p  "¿Cuales son los apellidos? " APELLIDOS
	read -p  "¿Cuales es el nombre? " NOMBRE
	read -p  "¿Cual es la cantidad de descubirmiento? " DESCUBRIMIENTO
	if [ "$DESCUBRIMIENTO" = "" ];then
		DESCUBRIMIENTO=0
	else
		DESCUBRIMIENTO="-"$DESCUBRIMIENTO
	fi
	while read line;do
		LASTNUM=$(echo $line | cut -d ":" -f 1)
	done < $FILE
	let NUMERO=$LASTNUM+1
	echo "El numero de cuenta sera: $NUMERO"
	sed -i '$a '"$NUMERO:$APELLIDOS:$NOMBRE:$FECHA:$DESCUBRIMIENTO"'' $FILE
	local FICHEROCUENTA=$(RutaCuenta $NUMERO)
	touch $FICHEROCUENTA
	echo "I:$SALDOINICIAL:$FECHA" > $FICHEROCUENTA
}
function ComprobarCuenta(){
	local NUMEROC=$1
	local RUTA=$(RutaBanco)
	local FICHEROCUENTA=$(RutaCuenta $NUMEROC)
	if [ -e $FICHEROCUENTA ];then
		return 0
	else
		return 1
	fi
}
function SaldoCuenta(){
	local NUMERO=$1
	local RUTA=$(RutaBanco)
	local FICHEROCUENTA=$(RutaCuenta $NUMERO)
	local SALDO=""
	while read line;do
		local TIPO=$(echo $line | cut -d ":" -f 1)
		local CANTIDAD=$(echo $line | cut -d ":" -f 2)
		if [ $TIPO = "I" ];then
			let SALDO=$SALDO+$CANTIDAD
		else
			let SALDO=$SALDO-$CANTIDAD
		fi
	done < $FICHEROCUENTA
	echo $SALDO 
}
function NivelDescubierto(){
	local RUTA=$(RutaBanco)
	local FILE=$RUTA/clientes.conf	
	local NUMEROCUENTA=$1
	let NUMEROCUENTA++
	local DESCUBIERTO=$(sed -n "$NUMEROCUENTA"p $FILE | cut -d ":" -f 5)
	echo $DESCUBIERTO
}
function PagarRecibo(){
	local NUMERO
	local CANTIDAD
	local CONTROL=1
	local RUTA=$(RutaBanco)
	local FECHA=$(date +"%d/%m/%Y")
	echo "----------------------Pagar recibo----------------------"
	while [ $CONTROL = 1 ];do
		read -p "Por favor ingrese numero de cuenta: " NUMERO	
		if ComprobarCuenta $NUMERO;then
			while true;do
				read -p "De que cantidad es el recibo: " CANTIDAD
				if ComprobarNumero $CANTIDAD;then
					local FICHEROCUENTA=$(RutaCuenta $NUMERO)
					local SALDO=$(SaldoCuenta $NUMERO)
					local DESCUBIERTO=$(NivelDescubierto $NUMERO)
					let SALDO=SALDO-CANTIDAD
					if [ $SALDO -lt $DESCUBIERTO ];then
						echo "No hay suficiente saldo para realizar la operación."
					else
						echo "El saldo actual de la cuenta es: $SALDO"
						sed -i '$a '"R:$CANTIDAD:$FECHA"'' $FICHEROCUENTA
					fi
					break
				else
					echo "Cantidad introducida no valida."
				fi
			done
			CONTROL=0
		else
			echo "La cuenta no existe."
		fi
	done
}
function RealizarIngreso(){
	local NUMERO
	local CANTIDAD
	local CONTROL=1
	local RUTA=$(RutaBanco)
	local FECHA=$(date +"%d/%m/%Y")
	echo "----------------------Realizar Ingreso----------------------"
	while [ $CONTROL = 1 ];do
		read -p "Por favor ingrese numero de cuenta: " NUMERO
		if ComprobarCuenta $NUMERO;then
			while true;do
				read -p "Que cantidad desea ingresar: " CANTIDAD
				if ComprobarNumero $CANTIDAD;then
					local FICHEROCUENTA=$(RutaCuenta $NUMERO)
					local SALDO=$(SaldoCuenta $NUMERO)
					let SALDO=SALDO+CANTIDAD
					echo "El saldo actual de la cuenta es: $SALDO"
					sed -i '$a '"I:$CANTIDAD:$FECHA"'' $FICHEROCUENTA
					break
				else
					echo "Numero no valido."				
				fi
			done
			CONTROL=0
		else
			echo "El numero de cuenta no existe."
		fi
	done
}
function Extracto(){
	local NUMERO
	local RUTA=$(RutaBanco)
	local FILE=$RUTA/clientes.conf
	local CONT=0
	local CONTROL=1
	echo "----------------------Extracto----------------------"
	while [ $CONTROL = 1 ];do	
		read -p "Por favor ingrese numero de cuenta: " NUMERO
		if ComprobarCuenta $NUMERO;then
			local FICHEROCUENTA=$(RutaCuenta $NUMERO)
			echo "----------------------Datos cuenta----------------------"
			echo "Cuenta nº: $NUMERO"
			local LINEACUENTA
			let LINEACUENTA=NUMERO+1
			local APELLIDOS=$(sed -n "$LINEACUENTA"p $FILE | cut -d ":" -f 2)	
			local NOMBRE=$(sed -n $LINEACUENTA"p" $FILE | cut -d ":" -f 3)
			echo "Titular de la cuenta: $NOMBRE $APELLIDOS"
			local FECHAC=$(sed -n $LINEACUENTA"p" $FILE | cut -d ":" -f 4)
			echo "Fecha creación: $FECHAC"
			echo "----------------------Movimientos----------------------"
			echo "Tipo	Cantidad	Fecha		Saldo Acumulado"
			local ACUMULADO="";
			while read line;do
				local TIPO=$(echo $line | cut -d ":" -f 1)
				local CANTIDAD=$(echo $line | cut -d ":" -f 2)
				local FECHA=$(echo $line | cut -d ":" -f 3)
				if [ $TIPO = "I" ];then
					let ACUMULADO=ACUMULADO+CANTIDAD
				else
					let ACUMULADO=ACUMULADO-CANTIDAD
				fi	
				echo "$TIPO	$CANTIDAD		$FECHA	$ACUMULADO"
			done < $FICHEROCUENTA
			local SALDO=$(SaldoCuenta $NUMERO)
			echo "Saldo total actual: $SALDO"
			CONTROL=0
		else
			echo "El numero de cuenta no existe."
		fi
	done
}
function CantidadDescubiertos(){
	local RUTA=$(RutaBanco)
	local FILE=$RUTA/clientes.conf
	local NUMERODECUENTAS=$(tail -n 1 $FILE | cut -d ":" -f 1)
	local CUENTAACTUAL=1
	local CONTADOR=0
	local LINEACUENTA=2
	while [ $CUENTAACTUAL -le $NUMERODECUENTAS ];do
		if [ $(SaldoCuenta $CUENTAACTUAL) -lt 0 ];then
			local NOMBRE=$(sed -n "$LINEACUENTA"p $FILE | cut -d ":" -f 2)
			local APELLIDO=$(sed -n "$LINEACUENTA"p $FILE | cut -d ":" -f 3)
			echo "La cuenta numero $CUENTAACTUAL, con propietario $NOMBRE $APELLIDO, esta en descubierto"
			let CONTADOR++		

		fi
		let CUENTAACTUAL++
		let LINEACUENTA++
	done
	echo "La cantidad de cuentas descubiertas es: $CONTADOR"
}
function ModificarDescubierto(){
	local RUTA=$(RutaBanco)
	local FILE=$RUTA/clientes.conf
	local NUEVODESCUBIERTO
	local NUMERO
	read -p "¿Que cuenta desea modificar? " NUMERO
	read -p "¿Cual va a ser el nuevo descubierto? " NUEVODESCUBIERTO
	sed -i 's/^\('$NUMERO':.*:.*:.*:\)\(.*\)/\1-'$NUEVODESCUBIERTO'/g' $FILE
}
function Menu(){
	local OPCION
	while true;do
		echo "----------------------Menu----------------------"
		echo "Hora del sistema: "$(date +"%R")
		echo "Elija una de las siguientes opciones: "
		echo "1-Crear cuenta"
		echo "2-Pagar recibo"
		echo "3-Realizar Ingreso"
		echo "4-Extracto"
		echo "5-Cantidad De Descubiertos"
		echo "6-Modificar Descubierto"
		echo "7-Salir"
		read -n 1 -p "Cual es su eleccion: " OPCION
		echo ""
		case	$OPCION in
			1)CrearCuenta;;
			2)PagarRecibo;;
			3)RealizarIngreso;;
			4)Extracto;;
			5)CantidadDescubiertos;;
			6)ModificarDescubierto;;
			7)echo "Que tenga un buen dia."
			  exit;;
			*)echo "Opcion no valida";;
		esac
	done
}
function CopiaSeguridad(){
	local CONF=banco.config
	local FECHA=$(date +"%d%m%Y")
	local RUTAS
	local RUTA
	local RUTAB=$(RutaBanco)
	local ARCHIVOS=$(ls $RUTA)
	while read line;do
		RUTAS=$(echo $line | cut -d = -f 1)
		if [ "$RUTAS" = "DIR_BACKU" ];then
			RUTA=$(echo $line | cut -d = -f 2)/banco_$FECHA.tar
		fi	
	done < $CONF
	if [ "$RUTA" = "" ];then
		read -p "Introduzca una ruta para hacer la copia de seguridad: " RUTA
		RUTA=$RUTA/banco_$FECHA.tar
	fi
	local ARCHIVOS=$(ls $RUTAB)
	tar -v -c -f  $RUTA -C $RUTAB $ARCHIVOS
}
