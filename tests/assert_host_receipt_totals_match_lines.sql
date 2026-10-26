-- fct_episode host totals must equal the sum of fct_receipt_line for the host, to the cent.
with lines as (
    select episode_key, sum(item_price_usd) as line_subtotal_usd
    from {{ ref('fct_receipt_line') }}
    where diner_role = 'host'
    group by 1
)
select e.episode_key, e.host_subtotal_usd, l.line_subtotal_usd
from {{ ref('fct_episode') }} as e
left join lines as l on e.episode_key = l.episode_key
where abs(e.host_subtotal_usd - coalesce(l.line_subtotal_usd, 0)) >= 0.005
