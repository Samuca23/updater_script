#!/bin/bash

# URL da API
API_URL="https://registry.unidavi.edu.br/service/rest/v1/search?docker.imageName=atos-front"
# Arquivo para armazenar o lastModified
LAST_MODIFIED_FILE="ambiente-minha-unidavi/dev/last_modified/last_modified_front_end.txt"
# Localização do jq do Snap
JQ="/snap/bin/jq"
# Caminho completo para o docker-compose
DOCKER_COMPOSE="/usr/local/bin/docker-compose"

# Função para obter o lastModified da API
get_last_modified() {
    echo "Obtendo lastModified da API..."
    # Executa o comando curl para obter os dados da API
    curl_output=$(curl -sSf -u bitbucket:2025@bitUni_nexus "$API_URL")
    if [ $? -ne 0 ]; then
        echo "Erro ao obter dados da API."
        current_datetime=$(date '+%Y-%m-%d %H:%M:%S')
        echo "Data e hora da atualização: $current_datetime"
        exit 1
    fi
    # Usa o jq para extrair o lastModified do JSON
    last_modified=$("$JQ" -r '.items[] | select(.version == "stage") | .assets[].lastModified' <<< "$curl_output")
    # Retorna o lastModified
    echo "$last_modified"
}

# Função para verificar se o lastModified mudou
check_last_modified() {
    # Obtém o lastModified atual passado como argumento
    current_last_modified="$1"
    # Verifica se o arquivo last_modified.txt existe
    if [ -f "$LAST_MODIFIED_FILE" ]; then
        # Obtém o lastModified salvo no arquivo
        last_saved_last_modified=$(cat "$LAST_MODIFIED_FILE")
        # Compara o lastModified atual com o último salvo
        if [ "$current_last_modified" != "$last_saved_last_modified" ]; then
            # Se forem diferentes, uma nova versão foi encontrada
            echo "--------------- INICIO ---------------"
            echo "Nova versão encontrada!"
            current_datetime=$(date '+%Y-%m-%d %H:%M:%S')
            echo "Data e hora da atualização: $current_datetime"
            # Atualiza o arquivo last_modified.txt com o novo lastModified
            echo "$current_last_modified" > "$LAST_MODIFIED_FILE"
            # Reinicia o contêiner do Docker com a nova versão
            echo "Reiniciando contêiner do Docker..."
            "$DOCKER_COMPOSE" -f /home/docker/ambiente-minha-unidavi/dev/docker-compose.yml kill atos-front
            "$DOCKER_COMPOSE" -f /home/docker/ambiente-minha-unidavi/dev/docker-compose.yml pull atos-front
            "$DOCKER_COMPOSE" -f /home/docker/ambiente-minha-unidavi/dev/docker-compose.yml up -d atos-front
            echo "Contêiner reiniciado com Sucesso!"
            echo "--------------- FIM ---------------"
        fi
    else
        # Se o arquivo last_modified.txt não existir, cria-o com o lastModified atual
        echo "Arquivo inexistente! Será criado em seguida"
        echo "$current_last_modified" > "$LAST_MODIFIED_FILE"
        echo "Arquivo last_modified_front_end.txt criado com o lastModified atual."
        echo "--------------- FIM ---------------"
    fi
}

# Obtém o lastModified atual
current_last_modified=$(get_last_modified)
if [ -z "$current_last_modified" ]; then
    echo "Erro: não foi possível obter o lastModified."
    current_datetime=$(date '+%Y-%m-%d %H:%M:%S')
    echo "Data e hora da atualização: $current_datetime"
    exit 1
fi

# Verifica se houve alguma alteração
check_last_modified "$current_last_modified"
