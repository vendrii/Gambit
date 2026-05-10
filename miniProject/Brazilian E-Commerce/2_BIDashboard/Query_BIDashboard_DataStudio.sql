WITH order_level_reviews AS (
    SELECT
        order_id,
        MAX(review_score) AS review_score
    FROM public.order_reviews
    GROUP BY 1
)
SELECT
    o.order_id,
    CAST(o.order_purchase_timestamp AS DATE) AS purchase_date,
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS purchase_month,
    o.customer_id,
    c.customer_state,
    c.customer_city,
    i.product_id,
    (i.price + i.freight_value) AS total_sales_value,
    i.freight_value,
    COALESCE(pt.product_category_name_english, 'Unknown') AS product_category,
    EXTRACT(EPOCH FROM (CAST(o.order_delivered_customer_date AS TIMESTAMP) - CAST(o.order_estimated_delivery_date AS TIMESTAMP))) / 86400 AS delivery_delay_days,
    CASE
        WHEN CAST(o.order_delivered_customer_date AS TIMESTAMP) > CAST(o.order_estimated_delivery_date AS TIMESTAMP) THEN 'Late'
        ELSE 'On-Time'
    END AS delivery_status,
    r.review_score
FROM public.orders o
JOIN public.customers c
    ON o.customer_id = c.customer_id
JOIN public.order_items i
    ON o.order_id = i.order_id
LEFT JOIN public.products p
    ON i.product_id = p.product_id
LEFT JOIN public.product_category_name_translation pt
    ON p.product_category_name = pt.product_category_name
LEFT JOIN order_level_reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';