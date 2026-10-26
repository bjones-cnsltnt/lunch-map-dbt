-- Fails the build if any episode's rebuilt receipt disagrees with the displayed price label.
select *
from {{ ref('audit_receipt_reconciliation') }}
where reconciliation_status = 'mismatch'
