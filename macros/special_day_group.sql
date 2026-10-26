{#- Specials carry a free-text "day" ("Daily", "Wed", "Tuesday", "Mon-Fri", "Veterans Day"). Normalize it. -#}
{% macro special_day_group(column) -%}
case
    when lower(trim({{ column }})) in ('daily', 'every day', 'everyday', 'all week') then 'daily'
    when lower(trim({{ column }})) in ('weekdays', 'mon-fri', 'monday-friday', 'weekday') then 'weekdays'
    when lower(trim({{ column }})) in ('weekend', 'weekends', 'sat-sun') then 'weekends'
    when lower(trim({{ column }})) in ('mon', 'monday') then 'mon'
    when lower(trim({{ column }})) in ('tue', 'tues', 'tuesday') then 'tue'
    when lower(trim({{ column }})) in ('wed', 'wednesday') then 'wed'
    when lower(trim({{ column }})) in ('thu', 'thur', 'thurs', 'thursday') then 'thu'
    when lower(trim({{ column }})) in ('fri', 'friday') then 'fri'
    when lower(trim({{ column }})) in ('sat', 'saturday') then 'sat'
    when lower(trim({{ column }})) in ('sun', 'sunday') then 'sun'
    else 'other'
end
{%- endmacro %}
