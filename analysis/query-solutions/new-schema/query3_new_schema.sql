WITH "cte_top_customer_per_country" AS (
    SELECT
        "invoice"."billing_country" AS "country_of_origin",
	    "customer"."customer_last_name" || ', ' || "customer"."customer_first_name" AS "customer_full_name",
	    ROUND(SUM("invoice"."invoice_total_cents") / 100.0, 2) AS "rounded_customer_spendings",
	    RANK() OVER(PARTITION BY "invoice"."billing_country" ORDER BY SUM(invoice.invoice_total_cents) DESC) AS "rank"
    FROM "invoice"
    LEFT OUTER JOIN "customer"
        ON "invoice"."customer_id" = "customer"."customer_id"
    GROUP BY "invoice"."billing_country", "customer"."customer_last_name", "customer"."customer_first_name"
)
SELECT
    "country_of_origin",
	"customer_full_name",
	"rounded_customer_spendings"
FROM "cte_top_customer_per_country"
WHERE "rank" = 1
ORDER BY "rounded_customer_spendings" DESC;