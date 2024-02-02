#!/bin/bash

# Definim la ubicació de l'arxiu amb els usuaris
USUARIS_TXT="/root/Downloads/usuaris.txt"

# Creem una llista amb els usuaris actuals del sistema
USUARIS_SISTEMA=$(cut -d: -f1 /etc/passwd)

# Creem una llista amb els usuaris de l'arxiu
USUARIS_ARXIU=$(awk -F '\t' '{print $1}' $USUARIS_TXT | sed 's/ //g' | sed 's/,/ /' | awk '{print tolower($2$1)}')

# Funció per crear directoris d'equip si no existeixen
crear_directoris_equip() {
    local grup=$1
    if [ ! -d "/home/$grup" ]; then
        mkdir -p "/home/$grup/grup"
        mkdir -p "/home/$grup/public"
    fi
}

# Alta d'usuaris
while IFS=$'\t' read -r linia equip
do
    # Ignorem la línia de capçalera
    if [[ $linia == Cognoms* ]]; then
        continue
    fi

    # Generem l'username i el grup
    lletra_nom=${username:0:1}
    cognom=${username#*, }


    username="$cognom$lletra_nom"
    grup=$(echo "$grup" | tr '[:upper:]' '[:lower:]')

    username=$(echo $linia | sed 's/ //g' | sed 's/,/ /' | awk '{print tolower($2$1)}')
    grup=$(echo $equip | awk '{print tolower($0)}')

    # Creem els directoris d'equip si no existeixen
    crear_directoris_equip $grup

    # Comprovem si l'usuari ja existeix
    if id "$username" &>/dev/null; then
        echo "L'usuari $username ja existeix."
    else
        # Creem l'usuari amb el seu directori i grup
	mkdir -p "/home/$grup/$username"
        useradd -m -d "/home/$grup/$username" -s /bin/bash -g $grup -p $(openssl passwd -1 $username) $username
        echo "Usuari $username creat."
    fi
done < "$USUARIS_TXT"

# Baixa d'usuaris
for usuari in $USUARIS_SISTEMA; do
    if ! grep -qw $usuari <<< $USUARIS_ARXIU; then
        userdel -r $usuari
        echo "Usuari $usuari eliminat."
    fi
done

# Neteja de directoris d'equip buits
for dir in /home/*; do
    if [ -d "$dir" ] && [ "$(ls -A $dir)" ]; then
        rmdir --ignore-fail-on-non-empty "$dir"
    fi
done

