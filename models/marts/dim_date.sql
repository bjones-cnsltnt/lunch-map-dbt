{#- Calendar covering every featured date, one row per day. -#}

with bounds as (

    select
        cast(date_trunc('year', min(s.featured_date)) as date)                                        as start_date,
        cast(date_trunc('year', max(s.featured_date)) + interval 1 year - interval 1 day as date)      as end_date
    from {{ ref('stg_lunch__spots') }} as s

),

days as (

    select cast(unnest(generate_series(b.start_date, b.end_date, interval 1 day)) as date) as date_day
    from bounds as b

)

select
    cast(strftime(d.date_day, '%Y%m%d') as integer)  as date_key,
    d.date_day,
    year(d.date_day)                                 as year_number,
    quarter(d.date_day)                              as quarter_number,
    month(d.date_day)                                as month_number,
    monthname(d.date_day)                            as month_name,
    weekofyear(d.date_day)                           as week_of_year,
    isodow(d.date_day)                               as day_of_week,
    dayname(d.date_day)                              as day_name,
    isodow(d.date_day) in (6, 7)                     as is_weekend
from days as d
