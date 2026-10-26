{#- One row per receipt: the host's receipt at every episode, plus one per guest. -#}

with spots as (

    select * from {{ ref('stg_lunch__spots') }}

),

host_receipts as (

    select
        spot_id,
        place_id,
        'host'                 as diner_role,
        0                      as guest_number,
        cast(null as varchar)  as guest_name,
        cast(null as varchar)  as guest_title,
        host_tax_usd           as tax_usd
    from spots

),

guest_receipts as (

    select
        g.spot_id,
        g.place_id,
        'guest'                as diner_role,
        g.guest_number,
        g.guest_name,
        s.guest_title,
        g.guest_tax_usd        as tax_usd
    from {{ ref('stg_lunch__guest_orders') }} as g
    left join spots as s on g.spot_id = s.spot_id

),

receipts as (

    select * from host_receipts
    union all
    select * from guest_receipts

),

line_totals as (

    select
        i.spot_id,
        i.diner_role,
        i.guest_number,
        count(*)                 as item_count,
        sum(i.item_price_usd)    as subtotal_usd
    from {{ ref('int_receipt_items') }} as i
    group by 1, 2, 3

)

select
    r.spot_id,
    r.place_id,
    r.diner_role,
    r.guest_number,
    r.guest_name,
    r.guest_title,
    coalesce(l.item_count, 0)                                   as item_count,
    coalesce(l.subtotal_usd, 0)                                 as subtotal_usd,
    coalesce(r.tax_usd, 0)                                      as tax_usd,
    coalesce(l.subtotal_usd, 0) + coalesce(r.tax_usd, 0)        as total_usd
from receipts as r
left join line_totals as l
    on r.spot_id = l.spot_id
    and r.diner_role = l.diner_role
    and r.guest_number = l.guest_number
