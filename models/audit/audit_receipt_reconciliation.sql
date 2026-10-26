{#- Reconcile the stored price label (what the app displays) against the receipt we can
    rebuild from line items plus tax. Any 'mismatch' row fails the build. -#}

with episodes as (

    select * from {{ ref('fct_episode') }}

),

restaurants as (

    select d.restaurant_key, d.restaurant_name from {{ ref('dim_restaurant') }} as d

)

select
    e.episode_key,
    r.restaurant_name,
    e.featured_date,
    e.price_label,
    e.price_label_usd,
    e.host_subtotal_usd,
    e.host_tax_usd,
    e.host_total_usd,
    e.price_label_usd - e.host_total_usd                       as variance_usd,
    case
        when e.price_label_usd is null then 'unparsed_label'
        when e.host_item_count = 0 then 'no_line_items'
        when abs(e.price_label_usd - e.host_total_usd) < 0.005 then 'match'
        when abs(e.price_label_usd - e.host_total_usd) <= 0.50 then 'match_rounded'
        else 'mismatch'
    end                                                        as reconciliation_status
from episodes as e
left join restaurants as r on e.restaurant_key = r.restaurant_key
