{{ config(severity = 'warn') }}

-- Warns (does not fail) when source records need attention. See audit_record_quality.
select *
from {{ ref('audit_record_quality') }}
