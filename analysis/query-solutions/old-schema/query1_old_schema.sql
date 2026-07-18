WITH "cte_artist_earnings" AS (
    SELECT
        "ar"."artist_id",
        "ar"."name" AS "artist_name",
		SUM(CAST("il"."unit_price" * "il"."quantity" AS DECIMAL)) AS "total_earnings"
    FROM "invoice_line" AS "il"
    JOIN "track" AS "t"
        ON "il"."track_id" = "t"."track_id"
    JOIN "album" AS "al"
        ON "t"."album_id" = "al"."album_id"
    JOIN "artist" AS "ar"
        ON "al"."artist_id" = "ar"."artist_id"
    GROUP BY "ar"."artist_id"
),
"cte_top_selling_artist" AS (
    SELECT "artist_id"
    FROM "cte_artist_earnings"
    ORDER BY "total_earnings" DESC
    LIMIT 1
)
SELECT
    "c"."customer_id",
    TRIM("c"."last_name") || ' ' || TRIM("c"."first_name") AS "customer_name",
    "ar"."name" AS "artist_name",
    SUM(CAST("il"."unit_price" * "il"."quantity" AS DECIMAL)) AS "total_spent"
FROM "invoice" AS "i"
JOIN "customer" AS "c"
    ON "i"."customer_id" = "c"."customer_id"
JOIN "invoice_line" AS "il"
    ON "il"."invoice_id" = "i"."invoice_id"
JOIN "track" AS "t"
    ON "il"."track_id" = "t"."track_id"
JOIN "album" AS "al"
    ON "t"."album_id" = "al"."album_id"
JOIN "artist" AS "ar"
    ON "al"."artist_id" = "ar"."artist_id"
JOIN "cte_top_selling_artist" AS "tsa"
    ON "ar"."artist_id" = "tsa"."artist_id"
GROUP BY "c"."customer_id", "ar"."name"
ORDER BY "total_spent" DESC, "customer_name" ASC;