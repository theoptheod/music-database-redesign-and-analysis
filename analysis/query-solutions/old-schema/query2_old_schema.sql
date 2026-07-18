WITH "earnings_cte" AS(
    SELECT
        "invoice"."billing_country" AS "country",
		"genre"."genre_id",
	    "genre"."name" AS "genre_name",
         SUM("invoice_line"."unit_price" * "invoice_line"."quantity") AS "revenue_per_genre"
    FROM "invoice"
    LEFT OUTER JOIN "invoice_line"
        ON "invoice"."invoice_id" = "invoice_line"."invoice_id"
    LEFT OUTER JOIN "track"
        ON "invoice_line"."track_id" = "track"."track_id"
    LEFT OUTER JOIN "genre"
        ON "track"."genre_id" = "genre"."genre_id"
    GROUP BY "invoice"."billing_country", "genre"."genre_id", "genre"."name"
),
"ranked_country_earnings_cte" AS(
SELECT
    "earnings_cte"."country",
	"earnings_cte"."genre_name",
	"earnings_cte"."revenue_per_genre",
	RANK() OVER(PARTITION BY "earnings_cte"."country" ORDER BY "earnings_cte"."revenue_per_genre" DESC) AS "ranking"
FROM "earnings_cte"
)
SELECT
    "ranked_country_earnings_cte"."country",
	"ranked_country_earnings_cte"."genre_name"
FROM "ranked_country_earnings_cte"
WHERE "ranked_country_earnings_cte"."ranking" = 1;