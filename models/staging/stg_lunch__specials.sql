{#- One row per advertised special at a restaurant. The "day" field is free text; see special_day_group(). -#}

with source as (

    select
        r.id        as spot_id,
        r.place_id,
        from_json(cast(r.metadata as json) -> '$.restaurant_specials', {{ special_type() }}) as specials
    from {{ ref('raw_spots') }} as r

),

exploded as (

    select
        s.spot_id,
        s.place_id,
        generate_subscripts(s.specials, 1) as special_number,
        unnest(s.specials)                 as special
    from source as s

)

select
    e.spot_id,
    e.place_id,
    e.special_number,
    e.special.day                                   as day_raw,
    {{ special_day_group('e.special.day') }}        as day_group,
    e.special.description                           as description,
    cast(e.special.price as decimal(8, 2))          as price_usd
from exploded as e
