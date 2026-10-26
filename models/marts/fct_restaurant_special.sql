{#- Advertised specials. Grain: one special at one restaurant. -#}

select
    md5(place_id || '|' || cast(special_number as varchar))  as special_key,
    md5(place_id)                                            as restaurant_key,
    special_number,
    day_raw,
    day_group,
    description,
    price_usd
from {{ ref('stg_lunch__specials') }}
