{#- Receipt line fact. Grain: one line item on one diner's receipt at one episode. -#}

with items as (

    select * from {{ ref('int_receipt_items') }}

),

spots as (

    select s.spot_id, s.place_id, s.featured_date from {{ ref('stg_lunch__spots') }} as s

)

select
    md5(s.place_id || '|' || i.diner_role || '|' || cast(i.guest_number as varchar) || '|' || cast(i.line_number as varchar)) as receipt_line_key,
    md5(s.place_id || '|' || cast(s.featured_date as varchar))              as episode_key,
    md5(s.place_id)                                                         as restaurant_key,
    md5(i.diner_role || '|' || coalesce(i.guest_name, ''))                  as diner_key,
    cast(strftime(s.featured_date, '%Y%m%d') as integer)                    as date_key,
    i.diner_role,
    i.line_number,
    i.item_name,
    i.modifications,
    i.item_price_usd
from items as i
inner join spots as s on i.spot_id = s.spot_id
