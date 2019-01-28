#!/bin/bash

# This shell script will create all HBase tables for the
# Business Register.
# All HBase daemons must be running before you execute this.
# The script is idempotent, as we check for (and delete) any
# existing tables, after which new tables are created.

# check for an existing table, and delete it if one exists
drop_table() {
NAMESPACE=$1
NAME=$2
local TABLE_NAME="${NAMESPACE}:${NAME}"

if echo "exists '$TABLE_NAME'" | hbase shell 2>/dev/null | grep -q 'does exist'; then
	echo ""
	echo "Removing existing table '$TABLE_NAME'"
	hbase shell <<-EOT
		disable '$TABLE_NAME'
		drop '$TABLE_NAME'
		exit
	EOT
else
echo "The $TABLE_NAME' table does not exist, skipping..."
fi
}

# check for an existing table, and create it if it does not exist
create_namespace() {
NAMESPACE=$1
if echo "list_namespace_tables '$NAMESPACE'" | hbase shell 2>/dev/null | grep -q 'ERROR'; then
	# Attempt to create namespace if not existing
    echo "The namespace '$NAMESPACE' does not exist, creating..."
	hbase shell <<-EOT
		create_namespace "${NAMESPACE}"
		exit
	EOT
fi
}

# check for an existing table, and create it if it does not exist
create_table() {
NAMESPACE=$1
NAME=$2
local TABLE_NAME="${NAMESPACE}:${NAME}"

if echo "exists '$TABLE_NAME'" | hbase shell 2>/dev/null | grep -q 'does not exist'; then
	echo "Creating the table '$TABLE_NAME'"
	hbase shell <<-EOT
		create '$TABLE_NAME', {NAME => 'd', REPLICATION_SCOPE => 1}, {NAME => 'h', REPLICATION_SCOPE => 1}
		exit
	EOT
else
   echo "The $TABLE_NAME' table already exists, skipping..."
fi
}

NAMESPACE="br"
DROP_TABLES="false"

# read options
while getopts "n:d:" option; do
    case "${option}" in
    n ) NAMESPACE="$OPTARG";;
    d ) DROP_TABLES="$OPTARG";;
    *)
    esac
done

echo ""
echo "Creating schema within namespace '${NAMESPACE}' (drop existing tables = '${DROP_TABLES}')"
echo ""

create_namespace "${NAMESPACE}"
if echo "list_namespace_tables '$NAMESPACE'" | hbase shell 2>/dev/null | grep -q 'ERROR'; then
	exit 1
else
	echo "The namespace '$NAMESPACE' exists"
fi

# array of table names
    declare -a tables=("ENTERPRISE_GROUP" "ENTERPRISE" "LOCAL_UNIT" "REPORTING_UNIT" "LEGAL_UNIT" "VAT" "PAYE" "CH")

    if [[ "${DROP_TABLES}" = "true" ]]; then
        # drop tables
	echo ""
        echo "Dropping existing tables within namespace '${NAMESPACE}'..."
        for table in "${tables[@]}"; do
            drop_table "${NAMESPACE}" "${table}"
        done
    fi

    # create tables
    echo ""
    echo "Creating tables within namespace '${NAMESPACE}'..."
    for table in "${tables[@]}"; do
        create_table "${NAMESPACE}" "${table}"
    done

echo "Success"
exit 0