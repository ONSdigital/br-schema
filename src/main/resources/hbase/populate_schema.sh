#!/bin/bash

# read namespace
NAMESPACE=$1
DIRECTORY=$2

# DIRECTORY=$(cd `dirname $0` && pwd)

#bin/hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.columns=a,b,c <tablename> <hdfs-inputdir>

#LEGAL_UNIT
#hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.columns=d:ubrn,HBASE_ROW_KEY,d:ern,d:crn,d:name,d:trading_style,d:address1,d:address2,d:address3,d:address4,d:address5,d:postcode,d:sic07,d:paye_jobs,d:turnover,d:legal_status,d:trading_status,d:birth_date,d:death_date,d:death_code,d:uprn -Dimporttsv.separator=, $NAMESPACE:LEGAL_UNIT $DIRECTORY/Legal_Unit.csv

#VAT
hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.columns=d:vatref,HBASE_ROW_KEY,d:ubrn,d:sic,d:turnover,d:record_type,d:legalstatus,d:nameline1,d:tradstyle1,d:address1,d:address2,d:address3,d:address4,d:address5,d:postcode -Dimporttsv.separator=, ${NAMESPACE}:VAT ${DIRECTORY}/VAT.csv

#PAYE
hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.columns=d:payeref,HBASE_ROW_KEY,d:ubrn,d:dec_jobs,d:mar_jobs,d:june_jobs,d:sept_jobs,d:jobs_lastupd,d:legalstatus,d:stc,d:nameline1,d:tradstyle1,d:address1,d:address2,d:address3,d:address4,d:address5,d:postcode -Dimporttsv.separator=, ${NAMESPACE}:PAYE ${DIRECTORY}/PAYE.csv

echo ""
echo ""
hbase shell <<-EOT
    count '${NAMESPACE}:VAT'
    count '${NAMESPACE}:PAYE'
	exit
EOT
