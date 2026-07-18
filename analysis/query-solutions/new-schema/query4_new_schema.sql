SELECT
    "album"."album_title",
    STRING_AGG(DISTINCT "artist"."artist_name", ', ' ORDER BY "artist"."artist_name") AS "artist_names",
    ROUND(SUM("invoice_line"."unit_price_cents" * "invoice_line"."quantity") / 100.0, 2) AS "total_revenue"
FROM "invoice_line"
JOIN "track"
    ON "invoice_line"."track_id" = "track"."track_id"
JOIN "album_track"
    ON "track"."track_id" = "album_track"."track_id"
JOIN "album"
    ON "album_track"."album_id" = "album"."album_id"
JOIN "artist_album"
    ON "album"."album_id" = "artist_album"."album_id"
JOIN "artist"
    ON "artist_album"."artist_id" = "artist"."artist_id"
GROUP BY "album"."album_id", "album"."album_title"
ORDER BY "total_revenue" DESC
LIMIT 10;