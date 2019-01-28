<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:param name="namespace" />
    <xsl:param name="cf" />

    <xsl:template match="indexer">

        <indexer table="{$namespace}:{table_name}"
                 mapping-type="row"
                 table-name-field="unit_type">

            <!-- Mandatory fields -->
            <field name="unit_id" value="{$cf}:{unit_id}" source="value" type="string"/>
            <field name="name" value="{$cf}:name" source="value" type="string"/>
            <field name="trading_style" value="{$cf}:trading_style" source="value" type="string"/>
            <field name="address1" value="{$cf}:address1" source="value" type="string"/>
            <field name="address2" value="{$cf}:address2" source="value" type="string"/>
            <field name="address3" value="{$cf}:address3" source="value" type="string"/>
            <field name="address4" value="{$cf}:address4" source="value" type="string"/>
            <field name="address5" value="{$cf}:address5" source="value" type="string"/>
            <field name="postcode" value="{$cf}:postcode" source="value" type="string"/>
            <field name="region" value="{$cf}:region" source="value" type="string"/>
            <field name="sic07" value="{$cf}:sic07" source="value" type="string"/>
            <field name="employees" value="{$cf}:employees" source="value" type="int"/>

            <!-- Common fields -->
            <xsl:apply-templates select="parent_unit_id"/>
            <xsl:apply-templates select="idbr_id"/>
            <xsl:apply-templates select="legal_status"/>
            <xsl:apply-templates select="turnover"/>
            <xsl:apply-templates select="prn"/>

            <!-- Bespoke fields -->
            <xsl:apply-templates select="field"/>
        </indexer>
    </xsl:template>

    <xsl:template match="parent_unit_id">
        <field name="parent_unit_id" value="{$cf}:{.}" source="value" type="string"/>
    </xsl:template>

    <xsl:template match="idbr_id">
        <field name="idbr_id" value="{$cf}:{.}" source="value" type="string"/>
    </xsl:template>

    <xsl:template match="legal_status">
        <field name="legal_status" value="{$cf}:{.}" source="value" type="string"/>
    </xsl:template>

    <xsl:template match="turnover">
        <field name="turnover" value="{$cf}:{.}" source="value" type="int"/>
    </xsl:template>

    <xsl:template match="prn">
        <field name="prn" value="{$cf}:{.}" source="value" type="long"/>
    </xsl:template>

    <xsl:template match="field">
        <field name="{@solr_field}" value="{$cf}:{@hbase_column}" source="value" type="{@type}"/>
    </xsl:template>

</xsl:stylesheet>