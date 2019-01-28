#!/usr/bin/env bash

INDEX_NAME="br"
DROP_INDEX="false"
ZK_ENSEMBLE="localhost:2181"
SCHEMA_XML_FILE="schema.xml"

# read options
while getopts "n:d:z:f:" option; do
    case "${option}" in
    n ) INDEX_NAME="$OPTARG";;
    d ) DROP_INDEX="$OPTARG";;
    z ) ZK_ENSEMBLE="$OPTARG";;
    f ) SCHEMA_XML_FILE="$OPTARG";;
    *)
    esac
done

echo ""
echo "Creating index with name '${INDEX_NAME}' (drop existing index = '${DROP_INDEX}')"
echo ""

if [[ "${DROP_INDEX}" = "true" ]]; then
	if [[ -d "${INDEX_NAME}" ]]; then
        echo "Dropping existing index within name '${INDEX_NAME}'..."
        solrctl --zk ${ZK_ENSEMBLE}/solr collection --delete "${INDEX_NAME}"
        solrctl --zk ${ZK_ENSEMBLE}/solr instancedir --delete "${INDEX_NAME}"
        rm -rf "${INDEX_NAME}"
    fi
fi

echo ""

if [[ -d "${INDEX_NAME}" ]]; then
    echo "The '${INDEX_NAME}' index exists, updating..."
    cp "${SCHEMA_XML_FILE}" "${INDEX_NAME}/conf"
    solrctl --zk ${ZK_ENSEMBLE}/solr instancedir --update "${INDEX_NAME}" "${INDEX_NAME}"
    solrctl --zk ${ZK_ENSEMBLE}/solr collection --reload "${INDEX_NAME}"
    echo "'${INDEX_NAME}' index successfully updated"
    echo ""
else
    echo "The '${INDEX_NAME}' index does not exist, creating..."
    solrctl instancedir --generate "${INDEX_NAME}"
    cp "${SCHEMA_XML_FILE}" "${INDEX_NAME}/conf"
    solrctl --zk ${ZK_ENSEMBLE}/solr instancedir --create "${INDEX_NAME}" "${INDEX_NAME}"
    solrctl --zk ${ZK_ENSEMBLE}/solr collection --create "${INDEX_NAME}"
    echo "'${INDEX_NAME}' index successfully created"
    echo ""
fi




