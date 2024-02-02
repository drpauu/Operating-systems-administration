#!/bin/bash

# Comprovar si es proporciona el nom de l'arxiu com a paràmetre
if [ $# -eq 0 ]; then
    echo "No s'ha proporcionat el nom de l'arxiu. Ús: ./nomscript.sh usuaris.txt"
    exit 1
fi

arxiu_usuaris=$1

# Si es passa /dev/null com a paràmetre, esborrar usuaris
if [ "$2" == "/dev/null" ]; then
    while IFS=',' read -r surname name team
    do
        # Eliminar espais
        surname=${surname// /}
        name=${name// /}
        team=${team// /}

        # Comprovar si l'usuari existeix
        if id -u "$surname" >/dev/null 2>&1; then
            # Esborrar usuari
            userdel "$surname"
            echo "Usuari $surname esborrat."

            # Esborrar directori de l'usuari
            if [ -d "/home/$team/$surname" ]; then
                rm -r "/home/$team/$surname"
                echo "Directori de l'usuari /home/$team/$surname esborrat."
            fi

            # Esborrar directori de l'equip si està buit
            if [ ! "$(ls -A /home/$team)" ]; then
                rm -r "/home/$team"
                echo "Directori de l'equip /home/$team esborrat."
            fi
        else
            echo "L'usuari $surname no existeix. S'omet."
        fi
    done < "$arxiu_usuaris"
else
    declare -A membres_equip

    while IFS=',' read -r surname name team
    do
        # Eliminar espais
        surname=${surname// /}
        name=${name// /}
        team=${team// /}

        # Comprovar si l'usuari ja existeix
        if id -u "$surname" >/dev/null 2>&1; then
            echo "L'usuari $surname ja existeix. S'omet."
        else
            # Crear usuari sense directori personal
            useradd "$surname"
            echo "Usuari $surname creat."

            # Establir la contrasenya de l'usuari com a surname
            echo "$surname:$surname" | chpasswd
            echo "Contrasenya per a l'usuari $surname establerta com $surname."

            # Crear directori de l'equip si no existeix
            if [ ! -d "/home/$team" ]; then
                mkdir "/home/$team"
                mkdir "/home/$team/grup"
                mkdir "/home/$team/public"
                echo "Directori /home/$team creat."
            fi

            # Afegir usuari al grup de l'equip
            groupadd -f "$team"
            usermod -a -G "$team" "$surname"
            echo "Usuari $surname afegit al grup $team."

            # Establir permisos per al directori de l'equip
            chown :"$team" "/home/$team/grup"
            chmod 770 "/home/$team/grup"
            chmod 777 "/home/$team/public"

            # Crear directori de l'usuari dins del directori de l'equip
            mkdir "/home/$team/$surname"
            chown "$surname":"$surname" "/home/$team/$surname"
            chmod 700 "/home/$team/$surname"
            echo "Directori de l'usuari /home/$team/$surname creat."

            # Afegir usuari a l'array de membres de l'equip
            membres_equip["$team"]="$surname ${membres_equip[$team]}"
        fi
    done < "$arxiu_usuaris"

    # Esborrar directoris d'equips si estan buits
    for team in "${!membres_equip[@]}"; do
        if [ -z "${membres_equip[$team]}" ]; then
            rm -r "/home/$team"
            echo "Directori /home/$team esborrat."
        fi
    done
fi

