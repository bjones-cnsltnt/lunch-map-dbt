{#- One row per (restaurant, issue). Nothing here blocks the build; it is the worklist
    for fixing source records, surfaced the same way the app's admin reconciliation view does. -#}

with spots as (

    select * from {{ ref('stg_lunch__spots') }}

),

issues as (

    select
        s.spot_id,
        s.place_id,
        s.restaurant_name,
        'missing_cuisine'                   as issue,
        cast(null as varchar)               as detail
    from spots as s
    where s.cuisine_raw is null

    union all

    select
        s.spot_id,
        s.place_id,
        s.restaurant_name,
        'address_not_parsed'                as issue,
        s.address                           as detail
    from spots as s
    where s.city is null or s.state_code is null or s.postal_code is null

    union all

    select
        s.spot_id,
        s.place_id,
        s.restaurant_name,
        'state_not_ok'                      as issue,
        s.state_code                        as detail
    from spots as s
    where s.state_code is not null and s.state_code <> 'OK'

    union all

    select
        s.spot_id,
        s.place_id,
        s.restaurant_name,
        'video_not_youtube'                 as issue,
        s.video_url                         as detail
    from spots as s
    where s.youtube_video_id is null

    union all

    select
        s.spot_id,
        s.place_id,
        s.restaurant_name,
        'zero_price_label'                  as issue,
        s.price_label                       as detail
    from spots as s
    where s.price_label_usd is not null and s.price_label_usd <= 0

    union all

    select
        s.spot_id,
        s.place_id,
        s.restaurant_name,
        'no_host_items'                     as issue,
        cast(s.host_item_count as varchar)  as detail
    from spots as s
    where s.host_item_count = 0

)

select
    md5(i.place_id || '|' || i.issue) as issue_key,
    i.spot_id,
    i.place_id,
    i.restaurant_name,
    i.issue,
    i.detail
from issues as i
