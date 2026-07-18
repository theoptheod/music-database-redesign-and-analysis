SELECT
    "album"."title" AS "album_title",
    "artist"."name" AS "artist_name",
    SUM("invoice_line"."unit_price" * "invoice_line"."quantity") AS "total_revenue"
FROM "invoice_line"
JOIN "track"
    ON "invoice_line"."track_id" = "track"."track_id"
JOIN "album"
    ON "track"."album_id" = "album"."album_id"
JOIN "artist"
    ON "album"."artist_id" = "artist"."artist_id"
GROUP BY "album"."album_id", "album"."title", "artist"."name"
ORDER BY "total_revenue" DESC
LIMIT 10;