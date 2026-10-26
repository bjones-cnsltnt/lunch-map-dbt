{#- One row per line item on the host's receipt. -#}

with source as (

    select
        r.id        as spot_id,
        r.place_id,
        from_json(cast(r.metadata as json) -> '$.ron_order', {{ order_item_type() }}) as items
    from {{ ref('raw_spots') }} as r

),

exploded as (

    select
        s.spot_id,
        s.place_id,
        generate_subscripts(s.items, 1) as line_number,
        unnest(s.items)                 as item
    from source as s

)

select
    e.spot_id,
    e.place_id,
    'host'                                          as diner_role,
    e.line_number,
    e.item.item_name                                as item_name,
    nullif(trim(e.item.ron_mods), '')               as modifications,
    cast(e.item.item_price as decimal(8, 2))        as item_price_usd
from exploded as e
