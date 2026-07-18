SELECT
    "sq"."country",
	"sq"."top_genre/s"
FROM (SELECT
	      "inv_2"."billing_country" AS "country",
	      "genre"."genre_name" AS "top_genre/s",
	      ROUND(SUM((CAST("invoice_line"."unit_price_cents" AS DECIMAL) * "invoice_line"."quantity") / 100), 2) AS "rounded_earnings_per_genre",
	      RANK() OVER(PARTITION BY "inv_2"."billing_country" ORDER BY "inv_2"."billing_country" ASC, ROUND(SUM((CAST("invoice_line"."unit_price_cents" AS DECIMAL) * "invoice_line"."quantity") / 100), 2) DESC) AS "rank"
      FROM "invoice" AS "inv_2"
      INNER JOIN "invoice_line"
          ON "inv_2"."invoice_id" = "invoice_line"."invoice_id"
      INNER JOIN "track"
          ON "invoice_line"."track_id" = "track"."track_id"
      INNER JOIN "genre_track"
          ON "track"."track_id" = "genre_track"."track_id"
      INNER JOIN "genre"
          ON "genre_track"."genre_id" = "genre"."genre_id"
      GROUP BY "genre"."genre_id", "inv_2"."billing_country") AS "sq"
WHERE "rank" = 1;