-- Answer A1
with
    revenue as (select
                    extract(year from o.order_delivered_customer_date) as year -- final date for revenue & extraction to number for order data
                  , extract(month from o.order_delivered_customer_date) as month
                  , round(sum(op.payment_value)::decimal, 2) as total_revenue
                from orders o -- base table
                         left join order_payments op on o.order_id = op.order_id -- taking payment_value for revenue
                where o.order_status = 'delivered'
                group by 1, 2
                order by 1, 2 asc)
  , prev_revenue as (select
                         r.*
                       , coalesce(lag(total_revenue, 1) over (order by r.year, r.month asc),
                                  0) as prev_month_revenue -- taking previous month revenue
                     from revenue r)
select
    pr.year
  , pr.month
  , pr.total_revenue
  , pr.prev_month_revenue
  , coalesce(round(((pr.total_revenue - pr.prev_month_revenue) / nullif(pr.prev_month_revenue, 0) * 100)::decimal, 2),
             0) as mom_change_pct -- Getting MoM movement in percentage with handling err divided 0
from prev_revenue pr
order by 1, 2 asc
limit 10;


-- Answer A2
with
    category_metrics as (select
                             -- Menggunakan coalesce agar jika translasi Inggris tidak ketemu, tetap menampilkan nama asli
                             initcap(replace(coalesce(t.product_category_name_english, p.product_category_name), '_',
                                             ' ')) as product_category_name
                           , count(distinct o.order_id) as num_orders
                           , count(i.order_item_id) as total_items_sold
                           , sum(op.payment_value) as total_revenue
                         from orders o
                                  inner join order_items i on o.order_id = i.order_id
                                  inner join products p on i.product_id = p.product_id
                                  left join order_payments op on o.order_id = op.order_id
                                  left join product_category_name_translation t -- taking for product name in english
                                            on p.product_category_name = t.product_category_name
                         where o.order_status != 'canceled'
                           and p.product_category_name is not null
                         group by p.product_category_name, t.product_category_name_english)
select
    product_category_name
  , num_orders
  , total_items_sold
  , round(total_revenue::DECIMAL, 2) as total_revenue
  , round((total_revenue / num_orders)::DECIMAL, 2) as average_order_value -- calculate AOV
from category_metrics
order by total_revenue desc
limit 10;


-- Answer A3
/*
Goals
- cohort_month: The month in which a cohort of customers made their first purchase (acquisition month).
- cohort_size: The total number of new unique customers acquired in that month.
- retained_m1 (Month 1): The number of customers from that cohort who returned and made another purchase in the next month following their first purchase.
- retained_m2 (Month 2): The number of customers who returned in the two months after following their first purchase.
- retained_m3 (Month 3): The number of customers who returned in the three months after following their first purchase.
 */
with
    customer_revenue as ( -- taking all success trx per customer in every month
        select
            c.customer_unique_id
          , o.order_id
          , o.order_purchase_timestamp
          , date_trunc('month', o.order_purchase_timestamp) as order_month
        from orders o
                 left join customers c on o.customer_id = c.customer_id
        where o.order_status != 'canceled')
  , cohort_definition as ( -- taking the month of the first purchase (Acquisition Month) for each customer
    select
        customer_unique_id
      , MIN(order_month) as cohort_month
    from customer_revenue
    group by customer_unique_id)
  , cohort_sizes as ( -- calculate the total unique customers in each cohort (Cohort Size)
    select
        cohort_month
      , count(distinct customer_unique_id) as cohort_size
    from cohort_definition
    group by cohort_month)
  , retention_intervals as (-- calculate the number of months between the next purchase and the first month of shopping.
    select
        r.customer_unique_id
      , cd.cohort_month
      , (extract(year from r.order_month) - extract(year from cd.cohort_month)) * 12 +
        (extract(month from r.order_month) -
         extract(month from cd.cohort_month)) as months_next_order -- calculate months_next_order
    from customer_revenue r
             join cohort_definition cd on r.customer_unique_id = cd.customer_unique_id)
-- compile all data and pivot using case when
select
    to_char(cs.cohort_month, 'YYYY-MM') as cohort_month
  , cs.cohort_size
  , count(distinct case when ri.months_next_order = 1 then ri.customer_unique_id end) as retained_m1
  , count(distinct case when ri.months_next_order = 2 then ri.customer_unique_id end) as retained_m2
  , count(distinct case when ri.months_next_order = 3 then ri.customer_unique_id end) as retained_m3
from cohort_sizes cs
         left join retention_intervals ri on cs.cohort_month = ri.cohort_month
group by cs.cohort_month, cs.cohort_size
order by cs.cohort_month asc;


-- PART B
with
    payment_summary as (-- aggregate payment per order_id first to ensure no duplicate order_id causes order_items to be counted twice
        select
            order_id
          , sum(payment_value) filter (where payment_type = 'credit_card') as credit_card_revenue
          , sum(payment_value) filter (where payment_type = 'boleto') as boleto_revenue
        from order_payments
        group by order_id)
  , base_metrics as ( -- base CTE for joining to another CTE
    select
        t.product_category_name_english as category
      , count(distinct o.order_id) as total_orders
      , sum(oi.price) as total_revenue
      , sum(pay.credit_card_revenue) as credit_card_revenue
      , sum(pay.boleto_revenue) as boleto_revenue
        -- calculate late delivered
      , count(distinct case
                           when o.order_delivered_customer_date > o.order_estimated_delivery_date
                               then o.order_id end) as late_count
      , avg(case
                when o.order_delivered_customer_date > o.order_estimated_delivery_date
                    then EXTRACT(epoch from (o.order_delivered_customer_date - o.order_estimated_delivery_date)) /
                         86400.0
        end) as avg_days_late
    from order_items oi
             join products p on oi.product_id = p.product_id
             join product_category_name_translation t on t.product_category_name = p.product_category_name
             join orders o on o.order_id = oi.order_id
             left join payment_summary pay on pay.order_id = o.order_id
    where o.order_delivered_customer_date is not null
    group by t.product_category_name_english)
  , ranked_metrics as (-- Calculate rank and percentage
    select
        rank() over (order by total_revenue desc) as revenue_rank
      , category
      , total_orders
      , total_revenue
        -- Revise in this part: direct divide cause total_orders already fixed from previous CTE
      , round((total_revenue / NULLIF(total_orders, 0))::numeric, 2) as avg_order_value
      , credit_card_revenue
      , boleto_revenue
      , round((credit_card_revenue * 100.0 / NULLIF(credit_card_revenue + boleto_revenue, 0))::numeric,
              1) as credit_card_share_pct
      , late_count
      , round((late_count * 100.0 / NULLIF(total_orders, 0))::numeric, 1) as late_rate_pct
      , round(avg_days_late::numeric, 1) as avg_days_late
      , rank() over (order by (late_count * 100.0 / NULLIF(total_orders, 0)) desc) as late_rank
    from base_metrics)
select
    revenue_rank
  , category
  , total_orders
  , round(total_revenue::numeric, 2) as total_revenue
  , round((total_revenue * 100.0 / NULLIF(sum(total_revenue) over (), 0))::numeric, 2) as revenue_share_pct
  , round((sum(total_revenue) over (
    order by total_revenue desc
    rows between unbounded preceding and current row
    ) * 100.0 / NULLIF(sum(total_revenue) over (), 0))::numeric, 2) as cumulative_revenue_pct
  , avg_order_value
  , round(credit_card_revenue::numeric, 2) as credit_card_revenue
  , round(boleto_revenue::numeric, 2) as boleto_revenue
  , credit_card_share_pct
  , late_count
  , late_rate_pct
  , avg_days_late
  , late_rank
from ranked_metrics
order by revenue_rank;