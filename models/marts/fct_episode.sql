{#- Episode fact. Grain: one restaurant featured on one date. Measures are the host's receipt
    plus flags for guests and specials. -#}

with spots as (

    select * from {{ ref('stg_lunch__spots') }}

),

host_receipt as (

    select * from {{ ref('int_receipts') }} as r where r.diner_role = 'host'

),

guest_totals as (

    select
        r.spot_id,
        count(*)            as guest_count,
        sum(r.total_usd)    as guest_total_usd
    from {{ ref('int_receipts') }} as r
    where r.diner_role = 'guest'
    group by 1

)

select
    md5(s.place_id || '|' || cast(s.featured_date as varchar))  as episode_key,
    md5(s.place_id)                                             as restaurant_key,
    cast(strftime(s.featured_date, '%Y%m%d') as integer)        as date_key,
    s.featured_date,
    s.youtube_video_id,
    s.video_url,
    s.price_label,
    s.price_label_usd,
    h.item_count                                                as host_item_count,
    h.subtotal_usd                                              as host_subtotal_usd,
    h.tax_usd                                                   as host_tax_usd,
    h.total_usd                                                 as host_total_usd,
    coalesce(g.guest_count, 0)                                  as guest_count,
    coalesce(g.guest_count, 0) > 0                              as has_guest,
    g.guest_total_usd,
    s.specials_count,
    s.drive_miles,
    s.drive_minutes,
    s.extracted_at
from spots as s
left join host_receipt as h on s.spot_id = h.spot_id
left join guest_totals as g on s.spot_id = g.spot_id
