{#- Restaurant dimension. One row per place_id (Google Place ID is the natural key). -#}

with spots as (

    select * from {{ ref('stg_lunch__spots') }}

)

select
    md5(place_id)                              as restaurant_key,
    place_id,
    spot_id,
    restaurant_name,
    cuisine_raw,
    {{ cuisine_group('cuisine_raw') }}         as cuisine_group,
    address,
    city,
    state_code,
    postal_code,
    latitude,
    longitude,
    drive_miles,
    drive_minutes,
    case
        when drive_minutes is null then 'unknown'
        when drive_minutes < 15 then 'under 15 min'
        when drive_minutes < 30 then '15-29 min'
        when drive_minutes < 45 then '30-44 min'
        else '45+ min'
    end                                        as drive_time_bucket,
    has_menu_data,
    has_secret_menu,
    has_photo,
    specials_note,
    description
from spots
