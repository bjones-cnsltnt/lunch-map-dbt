{#- DuckDB struct type strings used to unpack the JSON arrays inside raw_spots.metadata.
    Kept in one place so staging models stay readable and the shape is versioned. -#}

{% macro order_item_type() -%}
'[{"item_name":"VARCHAR","ron_mods":"VARCHAR","item_price":"DOUBLE"}]'
{%- endmacro %}

{% macro guest_order_type() -%}
'[{"name":"VARCHAR","tax":"DOUBLE","items":[{"item_name":"VARCHAR","ron_mods":"VARCHAR","item_price":"DOUBLE"}]}]'
{%- endmacro %}

{% macro special_type() -%}
'[{"day":"VARCHAR","description":"VARCHAR","price":"DOUBLE"}]'
{%- endmacro %}
