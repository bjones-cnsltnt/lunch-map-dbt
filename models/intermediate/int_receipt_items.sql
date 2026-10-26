{#- Host and guest line items on one grain: a line on a receipt at an episode. -#}

with host_items as (

    select
        spot_id,
        place_id,
        diner_role,
        0                        as guest_number,
        cast(null as varchar)    as guest_name,
        line_number,
        item_name,
        modifications,
        item_price_usd
    from {{ ref('stg_lunch__host_order_items') }}

),

guest_items as (

    select
        spot_id,
        place_id,
        diner_role,
        guest_number,
        guest_name,
        line_number,
        item_name,
        modifications,
        item_price_usd
    from {{ ref('stg_lunch__guest_order_items') }}

),

unioned as (

    select * from host_items
    union all
    select * from guest_items

)

select
    spot_id,
    place_id,
    diner_role,
    guest_number,
    guest_name,
    line_number,
    item_name,
    modifications,
    item_price_usd
from unioned
