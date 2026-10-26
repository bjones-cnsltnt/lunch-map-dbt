{#- Who ate: the host on every episode, plus named guests. -#}

with receipts as (

    select distinct
        r.diner_role,
        r.guest_name,
        r.guest_title
    from {{ ref('int_receipts') }} as r

)

select
    md5(r.diner_role || '|' || coalesce(r.guest_name, ''))  as diner_key,
    r.diner_role,
    case when r.diner_role = 'host' then 'Host' else r.guest_name end as diner_name,
    r.guest_title                                            as diner_title
from receipts as r
