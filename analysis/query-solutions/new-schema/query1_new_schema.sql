WITH "cte_artist_earnings" AS (
    SELECT
        "a"."artist_id",
        "a"."artist_name",
        ROUND(SUM("il"."unit_price_cents" * "il"."quantity"), 2) AS "total_earnings_cents"
    FROM "artist" AS "a"
    JOIN "artist_album" AS "aa"
        ON "a"."artist_id" = "aa"."artist_id"
    JOIN "album" AS "al"
        ON "aa"."album_id" = "al"."album_id"
    JOIN "album_track" AS "at"
        ON "al"."album_id" = "at"."album_id"
    JOIN "track" AS "t"
        ON "at"."track_id" = "t"."track_id"
    JOIN "invoice_line" AS "il"
        ON "t"."track_id" = "il"."track_id"
    GROUP BY "a"."artist_id"
),
"cte_top_selling_artist" AS (
    SELECT "artist_id"
    FROM "cte_artist_earnings"
    ORDER BY "total_earnings_cents" DESC
    LIMIT 1
)
SELECT
    "c"."customer_id",
    "c"."customer_last_name" || ' ' || "c"."customer_first_name" AS "customer_name",
    "a"."artist_name",
    ROUND(SUM("il"."unit_price_cents" * "il"."quantity") / 100.0, 2) AS "total_spent"
FROM "artist" AS "a"
JOIN "artist_album" AS "aa"
    ON "a"."artist_id" = "aa"."artist_id"
JOIN "album" AS "al"
    ON "aa"."album_id" = "al"."album_id"
JOIN "album_track" AS "at"
    ON "al"."album_id" = "at"."album_id"
JOIN "track" AS "t"
    ON "at"."track_id" = "t"."track_id"
JOIN "invoice_line" AS "il"
    ON "t"."track_id" = "il"."track_id"
JOIN "invoice" AS "i"
    ON "il"."invoice_id" = "i"."invoice_id"
JOIN "customer" AS "c"
    ON "i"."customer_id" = "c"."customer_id"
JOIN "cte_top_selling_artist" AS "tsa"
    ON "a"."artist_id" = "tsa"."artist_id"
GROUP BY "c"."customer_id", "a"."artist_name"
ORDER BY "total_spent" DESC, "customer_name" ASC;