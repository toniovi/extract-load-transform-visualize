---
title: Jaffle Shop Data — Analyzing Customers & Orders
---

### Customers data summary

<DataTable
  data="{customers_summary}"
  search="true">
<Column id= "customer_id"/>
<Column id= "customer_name"/>
<Column id= "count_lifetime_orders"/>
<Column id= "first_ordered_at"/>
</DataTable>


<Details title="Definitions">

```sql customers_summary
select
  *
from databricks.jaffle_shop_customers

```

</Details>