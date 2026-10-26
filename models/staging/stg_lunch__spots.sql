{#- One row per restaurant as stored by the app. Unpacks the scalar fields of the
    metadata JSON blob and parses the typed columns the marts need. -#}

with source as (

    select * from {{ ref('raw_spots') }}

),

typed as (

    select
        id                                         as spot_id,
        place_id,
        name                                       as restaurant_name,
        price_label,
        try_cast(replace(price_label, '$', '') as decimal(8, 2)) as price_label_usd,
        lat                                        as latitude,
        lng                                        as longitude,
        cast(metadata as json)                     as meta,
        extracted_at
    from source

),

parsed as (

    select
        spot_id,
        place_id,
        restaurant_name,
        price_label,
        price_label_usd,
        latitude,
        longitude,

        meta ->> '$.address'                                   as address,
        nullif(regexp_extract(meta ->> '$.address', ', ([^,]+), ([A-Z]{2}) (\d{5})', 1), '') as city,
        nullif(regexp_extract(meta ->> '$.address', ', ([^,]+), ([A-Z]{2}) (\d{5})', 2), '') as state_code,
        nullif(regexp_extract(meta ->> '$.address', ', ([^,]+), ([A-Z]{2}) (\d{5})', 3), '') as postal_code,

        nullif(trim(meta ->> '$.cuisine'), '')                 as cuisine_raw,
        try_cast(meta ->> '$.featured_date' as date)           as featured_date,
        meta ->> '$.video_url'                                 as video_url,
        nullif(regexp_extract(meta ->> '$.video_url', 'youtube\.com/watch\?v=([A-Za-z0-9_-]{11})', 1), '') as youtube_video_id,

        try_cast(meta ->> '$.tax' as decimal(8, 2))            as host_tax_usd,
        try_cast(meta ->> '$.drive_miles' as double)           as drive_miles,
        try_cast(meta ->> '$.drive_minutes' as integer)        as drive_minutes,
        nullif(trim(meta ->> '$.specials_note'), '')           as specials_note,
        nullif(trim(meta ->> '$.description'), '')             as description,

        meta ->> '$.guest.name'                                as guest_name,
        meta ->> '$.guest.title'                               as guest_title,

        coalesce(json_array_length(meta -> '$.ron_order'), 0)            as host_item_count,
        coalesce(json_array_length(meta -> '$.restaurant_specials'), 0)  as specials_count,
        coalesce(json_array_length(meta -> '$.guest_orders'), 0)         as guest_order_count,
        (meta -> '$.menu_data') is not null                    as has_menu_data,
        (meta -> '$.secret_menu') is not null                  as has_secret_menu,
        (meta ->> '$.photo_url') is not null                   as has_photo,

        extracted_at
    from typed

)

select * from parsed
