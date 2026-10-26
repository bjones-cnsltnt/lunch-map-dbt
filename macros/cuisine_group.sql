{#- Collapse free-text cuisine written by the extraction pipeline into a small, reportable set. -#}
{% macro cuisine_group(column) -%}
case
    when {{ column }} is null then 'Unknown'
    when lower({{ column }}) like '%bbq%' or lower({{ column }}) like '%barbe%' then 'BBQ'
    when lower({{ column }}) like '%mex%' or lower({{ column }}) like '%taco%' then 'Mexican'
    when lower({{ column }}) like '%pizza%' then 'Pizza'
    when lower({{ column }}) like '%burger%' then 'Burger'
    when lower({{ column }}) like '%asian%' or lower({{ column }}) like '%thai%' or lower({{ column }}) like '%chinese%'
        or lower({{ column }}) like '%vietnam%' or lower({{ column }}) like '%japan%' or lower({{ column }}) like '%sushi%' then 'Asian'
    when lower({{ column }}) like '%deli%' or lower({{ column }}) like '%sandwich%' or lower({{ column }}) like '%sub%' then 'Sandwich & Deli'
    when lower({{ column }}) like '%mediterr%' or lower({{ column }}) like '%leban%' or lower({{ column }}) like '%greek%' then 'Mediterranean'
    when lower({{ column }}) like '%american%' or lower({{ column }}) like '%diner%' or lower({{ column }}) like '%cafe%' then 'American'
    else 'Other'
end
{%- endmacro %}
