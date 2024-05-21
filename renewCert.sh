cat renewCert.sh 
#!/bin/bash

certbot_command="sudo certbot"
cert_name="domain_name-0001"
cert_path="/etc/letsencrypt/live/$cert_name"
key_path="/website_path_key/"

# Obtener la fecha de la última renovación del certificado
last_renewal_date=$(date -r "$cert_path/fullchain.pem" "+%s" 2>/dev/null)

# Obtener la fecha actual
current_date=$(date "+%s")

# Calcular los días transcurridos desde la última renovación
days_since_last_renewal=$(( (current_date - last_renewal_date) / 86400 ))

# Función para renovar el certificado
renew_certificate() {
    $certbot_command renew
    # Actualizar la fecha de la última renovación
    last_renewal_date=$(date -r "$cert_path/fullchain.pem" "+%s")
}

# Función para cambiar el dominio del certificado
change_domain() {
    echo "Ingresa el nuevo dominio:"
    read new_domain
    $certbot_command certonly --cert-name $cert_name -d $new_domain
}

# Función para forzar la renovación del certificado
force_renewal() {
    $certbot_command renew --force-renewal
    # Actualizar la fecha de la última renovación
    last_renewal_date=$(date -r "$cert_path/fullchain.pem" "+%s")
}

# Función para cambiar el tipo de llave y certificado
change_key_and_cert_type() {
    echo "Selecciona el nuevo tipo de llave y certificado:"
    echo "1. RSA (default)"
    echo "2. ECC"
    read cert_type_option

    case $cert_type_option in
        1)
            $certbot_command certonly --cert-name $cert_name --rsa-key-size 2048
            ;;
        2)
            $certbot_command certonly --cert-name $cert_name --elliptic-curve secp384r1
            ;;
        *)
            echo "Opción no válida"
            ;;
    esac
}

echo "Selecciona una operación:"
echo "1. Obtener nuevo certificado"
echo "2. Renovar certificado"
echo "3. Forzar renovación del certificado"
echo "4. Cambiar dominio del certificado"
echo "5. Cambiar tipo de llave y certificado"

read opcion

case $opcion in
    1)
        $certbot_command certonly --cert-name $cert_name
        ;;
    2)
        if [ -z "$last_renewal_date" ] || [ $days_since_last_renewal -gt 87 ]; then
            renew_certificate
        else
            echo "Faltan más de 3 días para la renovación máxima permitida."
        fi
        ;;
    3)
        force_renewal
        ;;
    4)
        change_domain
        ;;
    5)
        change_key_and_cert_type
        ;;
    *)
        echo "Opción no válida"
        exit 1
        ;;
esac

# Copiar archivos necesarios
sudo cp "$cert_path/cert.pem" "$key_path"
sudo cp "$cert_path/privkey.pem" "$key_path"
sudo cp "$cert_path/fullchain.pem" "$key_path"
