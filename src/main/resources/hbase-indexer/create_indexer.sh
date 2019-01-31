#!/usr/bin/env bash

INDEXER_NAME_PREFIX="br_"
INDEX_NAME="br"
ZK_ENSEMBLE="localhost:2181"
CONFIG_DIR="indexer"
DROP_INDEXER="false"

# read options
while getopts "n:i:z:c:d:" option; do
    case "${option}" in
    n ) INDEXER_NAME_PREFIX="$OPTARG";;
    i ) INDEX_NAME="$OPTARG";;
    z ) ZK_ENSEMBLE="$OPTARG";;
    c ) CONFIG_DIR="$OPTARG";;
    d ) DROP_INDEXER="$OPTARG";;
    *)
    esac
done

# delete and indexer
delete_indexer() {
NAME=$1
ZK=$2

echo "Deleting indexer '${NAME}'..."
hbase-indexer delete-indexer --name ${NAME} --zookeeper ${ZK_ENSEMBLE}

}

# create an indexer
create_indexer() {
NAME=$1
COLLECTION=$2
ZK=$3
CONFIG_XML=$4

echo "Creating indexer '${NAME}'..."
hbase-indexer add-indexer --name ${NAME} --indexer-conf ${CONFIG_XML} --connection-param solr.zk=${ZK_ENSEMBLE}/solr --connection-param solr.collection=${COLLECTION} --zookeeper ${ZK_ENSEMBLE}

}

# array of indexer names
    declare -a indexers=("paye" "vat")

     if [[ "${DROP_INDEXER}" = "true" ]]; then
        # drop indexers
	    echo ""
        echo "Dropping existing indexers for Solr index '${INDEX_NAME}'..."
        for indexer in "${indexers[@]}"; do
            delete_indexer "${INDEXER_NAME_PREFIX}_${indexer}" "${ZK_ENSEMBLE}"
        done
    fi

    # create indexers
    echo ""
    echo "Creating indexers for Solr index '${INDEX_NAME}'..."
    for indexer in "${indexers[@]}"; do
        create_indexer "${INDEXER_NAME_PREFIX}_${indexer}" "${INDEX_NAME}" "${ZK_ENSEMBLE}" "${CONFIG_DIR}/${indexer}-indexer.xml"
    done

echo
    hbase-indexer list-indexers --zookeeper "${ZK_ENSEMBLE}"

echo "Success"
exit 0
