WITH "customer_spendings_per_country" AS(
	SELECT
    	"invoice"."billing_country" AS "country",
		"customer"."customer_id",
		TRIM("customer"."first_name") AS "first_name",
		TRIM("customer"."last_name") AS "last_name",
		SUM(CAST("invoice"."total" AS DECIMAL)) AS "total_spendings",
		RANK() OVER(PARTITION BY "invoice"."billing_country" ORDER BY SUM("invoice"."total") DESC) AS "ranking"
	FROM "customer"
	LEFT OUTER JOIN "invoice"
    	ON "customer"."customer_id" = "invoice"."customer_id"
	GROUP BY "invoice"."billing_country", "customer"."customer_id", "customer"."first_name", "customer"."last_name"
)
SELECT
	"cspc"."country",
	"cspc"."first_name" AS "customer_first_name",
	"cspc"."last_name" AS "customer_last_name",
	"cspc"."total_spendings"
FROM "customer_spendings_per_country" AS "cspc"
WHERE "ranking" = 1
ORDER BY "total_spendings" DESC, "country" ASC;