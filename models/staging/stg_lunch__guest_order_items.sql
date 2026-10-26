{#- One row per line item on a guest's receipt. -#}

with guest_orders as (

    select * from {{ ref('stg_lunch__guest_orders') }}

),

exploded as (

    select
        g.spot_id,
        g.place_id,
        g.guest_number,
        g.guest_name,
        generate_subscripts(g.items, 1) as line_number,
        unnest(g.items)                 as item
    from guest_orders as g

)

select
    e.spot_id,
    e.place_id,
    'guest'                                         as diner_role,
    e.guest_number,
    e.guest_name,
    e.line_number,
    e.item.item_name                                as item_name,
    nullif(trim(e.item.ron_mods), '')               as modifications,
    cast(e.item.item_price as decimal(8, 2))        as item_price_usd
from exploded as e
