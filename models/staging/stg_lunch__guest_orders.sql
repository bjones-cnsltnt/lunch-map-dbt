{#- One row per guest receipt (a guest joined the host on some episodes). -#}

with source as (

    select
        r.id        as spot_id,
        r.place_id,
        from_json(cast(r.metadata as json) -> '$.guest_orders', {{ guest_order_type() }}) as guest_orders
    from {{ ref('raw_spots') }} as r
    where json_array_length(cast(r.metadata as json) -> '$.guest_orders') > 0

),

exploded as (

    select
        s.spot_id,
        s.place_id,
        generate_subscripts(s.guest_orders, 1) as guest_number,
        unnest(s.guest_orders)                 as guest_order
    from source as s

)

select
    e.spot_id,
    e.place_id,
    e.guest_number,
    e.guest_order.name                              as guest_name,
    cast(e.guest_order.tax as decimal(8, 2))        as guest_tax_usd,
    e.guest_order.items                             as items
from exploded as e
