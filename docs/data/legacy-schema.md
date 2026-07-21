# Legacy Schema – Technical Analysis

## Legacy Schema Documentation
This document provides a detailed breakdown of the original database schema, including its ERD diagram, table structures, field definitions, and sample rows.  
It serves as the technical reference for understanding the legacy system prior to normalization.

## Table of Contents
1. [Overview](#overview)
2. [Diagram](#diagram)
3. [Tables](#tables)
    * [album](#album)
    * [artist](#artist)
    * [media_type](#media_type)
    * [genre](#genre)
    * [track](#track)
    * [playlist](#playlist)
    * [playlist_track](#playlist_track)
    * [invoice](#invoice)
    * [invoice_line](#invoice_line)
    * [employee](#employee)
    * [customer](#customer) 

## Overview
The legacy database uses:
* denormalized tables
* weak or missing foreign keys
* free‑form text fields
* inconsistent data types
* limited referential integrity

This document captures the exact structure of the original schema for comparison with the redesigned model.

## Diagram
Below is the ERD of the original database schema.  
Note: The original diagram uses PascalCase (e.g. ArtistId), while the normalized PostgreSQL database uses snake_case (e.g. artist_id).  
This documentation reflects the real database schema.

![Original Database Diagram](images/database-diagrams/original_db_diagram.png)


## Tables
Each table is documented using the following format:
* Table name
* Field definitions (datatype, description, example, notes)
* Additional notes
* Sample rows
---
## album
```
| name      | datatype         | description                                                                    | example raw value | notes                                                                 |
| :-------- | :--------------- | :----------------------------------------------------------------------------- | :---------------- | :-------------------------------------------------------------------- |
| album_id  | VARCHAR(50) (PK) | Legacy primary key for each album                                              | 207               | Will be converted to INT (surrogate key) in the final schema          |
| title     | VARCHAR(120)     | Album title stored as a single-field value                                     | Mezmerize         | Will be expanded to VARCHAR(255) in the final schema                  |
| artist_id | VARCHAR(30)      | Identifier of the album’s artist/band, currently not enforced as a foreign key | 135               | Will be replaced by a artist_album junction table in the final schema |
```
Notes:
* `album_id` is stored as a VARCHAR in the legacy schema but represents numeric identifiers. It will be converted to an INT surrogate key.
* `title` will be expanded to VARCHAR(255) to support longer album names.
* The legacy `artist_id` column will be removed. Albums may have multiple artists, so the final schema introduces an artist_album junction table to model this many‑to‑many relationship.

Sample rows:
```
album_id,title,artist_id
"9","Plays Metallica By Four Cellos","7"
"10","Audioslave","8"
```
---
## artist
```
| name      | datatype         | description                                             | example raw value | notes                                                        |
| :-------- | :--------------- | :------------------------------------------------------ | :---------------- | :----------------------------------------------------------- |
| artist_id | VARCHAR(50) (PK) | Legacy primary key for each artist/band                 | 42                | Will be converted to INT (surrogate key) in the final schema |
| name      | VARCHAR(120)     | Full artist or band name stored as a single-field value | Milton Nascimento | Will be expanded to VARCHAR(255) in the final schema         |
```
Notes:
* `artist_id` will be converted from VARCHAR to an INT surrogate key.
* `name` will be expanded to VARCHAR(255) to support longer artist names.
* THe Artist–album relationships will be represented through the `artist_album` junction table in the final schema.

Sample rows:
```
artist_id,name
"100","Lenny Kravitz"
"101","Lulu Santos"
```
---
## media_type
```
| name          | datatype         | description                            | example raw value        | notes                                                        |
| :------------ | :--------------- | :------------------------------------- | :----------------------- | :----------------------------------------------------------- |
| media_type_id | VARCHAR(50) (PK) | Legacy primary key for each media type | 2                        | Will be converted to INT (surrogate key) in the final schema |
| name          | VARCHAR(120)     | Descriptive name of the media type     | Protected AAC audio file | Will be expanded to VARCHAR(255) in the final schema         |
```
Notes:
* `media_type_id` will be converted to an INT surrogate key.
* `name` will be expanded to VARCHAR(255) to support more descriptive mediatype names.

Sample rows:
```
media_type_id,name
"4","Purchased AAC audio file"
"5","AAC audio file"
```
---
## genre
```
| name     | datatype         | description                             | example raw value | notes                                                        |
| :------- | :--------------- | :-------------------------------------- | :---------------- | :----------------------------------------------------------- |
| genre_id | VARCHAR(50) (PK) | Legacy primary key for each music genre | 10                | Will be converted to INT (surrogate key) in the final schema |
| name     | VARCHAR(120)     | Descriptive name of the music genre     | Soundtrack        | Will be expanded to VARCHAR(255) in the final schema         |
```
Notes:
* `genre_id` will be converted to an INT surrogate key.
* `name` will be expanded to VARCHAR(255) to support longer genre descriptions.
* Tracks may belong to multiple genres, so the final schema introduces a `genre_track` junction table.

Sample rows:
```
genre_id,name
"1","Rock"
"2","Jazz"
```
---
## track
```
| name          | datatype         | description                                                                           | example raw value | notes                                                                                      |
| :------------ | :--------------- | :------------------------------------------------------------------------------------ | :---------------- | :----------------------------------------------------------------------------------------- |
| track_id      | INT (PK)         | Legacy primary key for each track                                                     | 891               | Will be converted to BIGINT (surrogate key) in the final schema                            |
| name          | VARCHAR(150)     | Track title                                                                           | Layla             | Will be expanded to VARCHAR(255) in the final schema                                       |
| album_id      | VARCHAR(50)      | Identifier of the album the track belongs to, currently not enforced as a foreign key | 72                | Will be replaced by a album_track junction table in the final schema                       |
| media_type_id | VARCHAR(50)      | Identifier of the track's media type, currently not enforced as a foreign key         | 1                 | Will become an INT FK referencing media_type(media_type_id) in the final schema            |
| genre_id      | VARCHAR(50)      | Identifier of the track's genre, currently not enforced as a foreign key              | 6                 | Will be replaced by a genre_track junction table in the final schema                       |
| composer      | VARCHAR(190)     | One or more composer names stored as a single delimited string                        | Clapton/Gordon    | Will be replaced by a composer table and composer_track junction table in the final schema |
| milliseconds  | INT              | Duration of track in milliseconds                                                     | 430733            | Will remain INT in the final schema                                                        |
| bytes         | INT              | Size of track in bytes                                                                | 14115792          | Will remain INT in the final schema                                                        |
| unit_price    | DOUBLE PRECISION | Price of track                                                                        | 0.99              | Will be converted to INT representing price in cents in the final schema                   |
```
Notes:
* `track_id` will be converted to a BIGINT surrogate key to accommodate large datasets.
* `name` will be expanded to VARCHAR(255) to support longer track titles.
* The legacy `album_id` and `genre_id` columns will be removed. Tracks may appear on multiple albums and belong to multiple genres, so these relationships will be modeled using the `album_track` and `genre_track` junction tables.
* The `composer` column violates 1NF by storing multiple names in a delimited string. The final schema introduces a `composer` table and a `composer_track` junction table to deal with this issue.
* `unit_price` will be stored as an INT representing price in cents to avoid floating‑point precision issues.

Sample rows:
```
track_id,name,album_id,media_type_id,genre_id,composer,milliseconds,bytes,unit_price
551,"The Rover","44","1","1","Jimmy Page/Robert Plant",337084,11011286,"0.99"
552,"In My Time Of Dying","44","1","1","John Bonham/John Paul Jones",666017,21676727,"0.99"
```
---
## playlist
```
| name        | datatype         | description                          | example raw value | notes                                                        |
| :---------- | :--------------- | :----------------------------------- | :---------------- | :----------------------------------------------------------- |
| playlist_id | VARCHAR(50) (PK) | Legacy primary key for each playlist | 11                | Will be converted to INT (surrogate key) in the final schema |
| name        | VARCHAR(120)     | Descriptive name of the playlist     | Brazilian Music   | Will be expanded to VARCHAR(255) in the final schema         |
```
Notes:
* `playlist_id` will be converted to an INT surrogate key.
* `name` will be expanded to VARCHAR(255) to support longer playlist names.

Sample rows:
```
playlist_id,name
"3","TV Shows"
"4","Audiobooks"
```

## playlist_track
```
| name        | datatype    | description                                                         | example raw value | notes                                                                       |
| :---------- | :---------- | :------------------------------------------------------------------ | :---------------- | :-------------------------------------------------------------------------- |
| playlist_id | VARCHAR(50) | Identifier of the playlist, currently not enforced as a foreign key | 8                 | Will become an INT FK referencing playlist(playlist_id) in the final schema |
| track_id    | INT         | Identifier of the track, currently not enforced as a foreign key    | 1550              | Will become an BIGINT FK referencing track(track_id) in the final schema    |
```
Notes:
* A new surrogate key `playlist_track_id` will be introduced to uniquely identify each row.
* `playlist_id` and `track_id` will become foreign keys referencing their respective tables.
* This table models the many‑to‑many relationship between the various playlists and tracks that are stored in the databases.

Sample rows:
```
playlist_id,track_id
"1",657
"1",650
```
---
## invoice
```
| name            | datatype                    | description                                                         | example raw value   |notes                                                                                               |
| :-------------- | :-------------------------- | :------------------------------------------------------------------ | :------------------ |:---------------------------------------------------------------------------------------------------|
| invoice_id      | INT (PK)                    | Legacy primary key for each invoice                                 | 21                  | Will remain as INT (surrogate key) in the final schema                                             |
| customer_id     | INT                         | Identifier of the customer, currently not enforced as a foreign key | 9                   | Will become an INT FK referencing customer(customer_id) in the final schema                        |
| invoice_date    | TIMESTAMP WITHOUT TIME ZONE | The date and time the invoice was created                           | 2017-02-07 00:00:00 | Will be converted to TIMESTAMPTZ in the final schema                                               |
| billing_address | VARCHAR(120)                | The billing street address of the customer at the time of purchase  | Sønder Boulevard 51 | Will be expanded to VARCHAR(255) in the final schema                                               |
| billing_city    | VARCHAR(30)                 | The billing city at the time of purchase                            | Copenhagen          | Will be expanded to VARCHAR(255) in the final schema                                               |
| billing_state   | VARCHAR(30)                 | The billing state/region at the time of purchase                    | None                | Will be replaced by billing_administrative_division & expanded to VARCHAR(255) in the final schema |
| billing_country | VARCHAR(30)                 | The billing country at the time of purchase                         | Denmark             | Will be expanded to VARCHAR(255) in the final schema                                               |
| billing_postal  | VARCHAR(30)                 | The billing postal code at the time of purchase                     | 1720                | Will be expanded to VARCHAR(255) in the final schema                                               |
| total           | DOUBLE PRECISION            | Total amount paid for the invoice                                   | 8.91                | Will be converted to INT representing price in cents in the final schema                           |
```
Notes:
* `invoice_id` remains an INT surrogate key.
* `invoice_date` will be converted to TIMESTAMPTZ so that the recorded purchase time stays accurate across different regions.
* Billing address fields remain denormalized by design, since invoices must preserve the customer’s address at the time of purchase.
* `total` will be stored as an INT representing price in cents to avoid floating‑point precision issues.

Sample rows:
```
invoice_id,customer_id,invoice_date,billing_address,billing_city,billing_state,billing_country,billing_postal,total
25,39,"2017-02-11 00:00:00","4, Rue Milton","Paris","None","France","75009","7.92"
26,55,"2017-02-15 00:00:00","421 Bourke Street","Sidney","NSW","Australia","2010","1.98"
```
---
## invoice_line
```
| name            | datatype         | description                                                        | example raw value | notes                                                                     |
| :-------------- | :--------------- | :----------------------------------------------------------------- | :---------------- | :------------------------------------------------------------------------ |
| invoice_line_id | VARCHAR(50) (PK) | Legacy primary key for each invoice line                           | 100               | Will be converted to INT (surrogate key) in the final schema              |
| invoice_id      | INT              | Identifier of the invoice, currently not enforced as a foreign key | 12                | Will become an INT FK referencing invoice(invoice_id) in the final schema |
| track_id        | INT              | Identifier of the track, currently not enforced as a foreign key   | 690               | Will become an BIGINT FK referencing track(track_id) in the final schema  |
| unit_price      | DOUBLE PRECISION | Price of the track at the time of purchase                         | 0.99              | Will be converted to INT representing price in cents in the final schema  |
| quantity        | DOUBLE PRECISION | Quantity purchased                                                 | 1                 | Will be converted to INT in the final schema                              |
```
Notes:
* `invoice_line_id` will be converted to an INT surrogate key.
* `invoice_id` and `track_id` will become foreign keys referencing their respective tables.
* `unit_price` will be stored as an INT representing price in cents.
* `quantity` will be converted to INT, as fractional quantities are not applicable to track purchases.

Sample rows:
```
invoice_line_id,invoice_id,track_id,unit_price, quantity
"1",1,1158,"0.99","1"
"2",1,1159,"0.99","1"
```

## employee
```
| name        | datatype                    | description                                                                   | example raw value     | notes                                                                                       |
| :---------- | :-------------------------- | :---------------------------------------------------------------------------- | :-------------------- | :--------------------------------------------------------------------------------------- |
| employee_id | VARCHAR(50) (PK)            | Legacy primary key for each employee                                          | 5                     | Will be converted to INT (surrogate key) in the final schema                             |
| last_name   | CHARACTER(50)               | Last name of the employee                                                     | Johnson               | Will be converted to VARCHAR(255) in the final schema                                    |
| first_name  | CHARACTER(50)               | First name of the employee                                                    | Steve                 | Will be converted to VARCHAR(255) in the final schema                                    |
| title       | VARCHAR(50)                 | Title of the employee                                                         | Sales Support Agent   | Will be replaced by employee_title_id referencing a new employee_title table             |
| reports_to  | VARCHAR(30)                 | Identifier of the employee's manager, currently not enforced as a foreign key | 2                     | Will become an INT FK referencing employee(employee_id) in the final schema              |
| levels      | VARCHAR(10)                 | Internal employee level or classification                                     | L1                    | Will be replaced by employee_level_id referencing a new employee_level table             |
| birthdate   | TIMESTAMP WITHOUT TIME ZONE | Employee's birthdate                                                          | 1965-03-03 00:00:00   | Will be converted to DATE in the final schema                                            |
| hire_date   | TIMESTAMP WITHOUT TIME ZONE | Employee's hiring date                                                        | 2017-10-17 00:00:00   | Will be converted to DATE in the final schema                                            |
| address     | VARCHAR(120)                | Employee's street address                                                     | 7727B 41 Ave          | Will be replaced by address_id referencing a new address table                           |
| city        | VARCHAR(50)                 | Employee's city                                                               | Calgary               | Will be removed since location will be handled by address_id and administrative_division |
| state       | VARCHAR(50)                 | Employee's state/district/region                                              | AB                    | Will be removed since location will be handled by address_id and administrative_division |
| country     | VARCHAR(30)                 | Employee's country                                                            | Canada                | Will be removed since location will be handled by address_id and administrative_division |
| postal_code | VARCHAR(30)                 | Employee's postal code                                                        | T3B 1Y7               | Will be normalized into a postal_zip_code table                                          |
| phone       | VARCHAR(30)                 | Employee's phone number                                                       | 1 (780) 836-9987      | Will be expanded to VARCHAR(255) in the final schema                                     |
| fax         | VARCHAR(30)                 | Employee's fax number                                                         | 1 (780) 836-9543      | Will be expanded to VARCHAR(255) in the final schema                                     |
| email       | VARCHAR(30)                 | Employee's email address                                                      | steve@chinookcorp.com | Will be expanded to VARCHAR(255) in the final schema                                     |
```

Notes:
* The datatype of the `last_name` and `first_name` columns (CHARACTER(50)) is fixed‑length and will be modernized.
* The `levels` column contains a small, predefined set of employee classification codes. To eliminate redundancy and enforce valid values, the final schema will introduce a separate `employee_level` table.
* The `title` column contains the titles assigned to employees based on their position. To eliminate redundancy and enforce valid values, the final schema will introduce a separate `employee_title` table.
* The new address table will store the street address and include a foreign key linking to the appropriate administrative division.
* The `city`, `state`, and `country` columns will be removed. In the final schema, all geographic information will be represented through `address_id`, which links to the `administrative_division` table.
This structure supports flexible hierarchical geographic data without introducing unnecessary NULL values.
* The `reports_to` column will be replaced by `manager_id`, a self‑referencing foreign key that points to `employee`.`employee_id`, allowing the schema to model organizational reporting hierarchies cleanly.

Sample rows:
```
employee_id,last_name,first_name,title,reports_to,levels,birthdate,hire_date,address,city,state,country,postal_code,phone,fax,email
"1","Adams","Andrew","General Manager","9","L6","1962-02-18 00:00:00","2016-08-14 00:00:00","11120 Jasper Ave NW","Edmonton","AB","Canada","T5K 2N1","+1 (780) 428-9482","+1 (780) 428-3457","andrew@chinookcorp.com"
"2","Edwards","Nancy","Sales Manager","1","L4","1958-12-08 00:00:00","2016-05-01 00:00:00","825 8 Ave SW","Calgary","AB","Canada","T2P 2T3","+1 (403) 262-3443","+1 (403) 262-3322","nancy@chinookcorp.com"
```
---
## customer
```
| name           | datatype      | description                                                                       | example raw value     | notes                                                                                    |
| :------------- | :------------ | :-------------------------------------------------------------------------------- | :-------------------- | :--------------------------------------------------------------------------------------- |
| customer_id    | INT (PK)      | Legacy primary key for each customer                                              | 3                     | Will remain as INT (surrogate key) in the final schema                                   |
| last_name      | CHARACTER(50) | Last name of the customer                                                         | François              | Will be converted to VARCHAR(255) in the final schema                                    |
| first_name     | CHARACTER(50) | First name of the customer                                                        | Tremblay              | Will be converted to VARCHAR(255) in the final schema                                    |
| company        | VARCHAR(120)  | Company of the customer                                                           | NULL                  | Will be expanded to VARCHAR(255) in the final schema                                     |
| address        | VARCHAR(120)  | Customer's home address                                                           | 1498 rue Bélanger     | Will be replaced by address_id referencing a new address table                           |
| city           | VARCHAR(50)   | Customer's city                                                                   | Montréal              | Will be removed since location will be handled by address_id and administrative_division |
| state          | VARCHAR(50)   | Customer's state/district/region                                                  | QC                    | Will be removed since location will be handled by address_id and administrative_division |
| country        | VARCHAR(50)   | Customer’s country                                                                | Canada                | Will be removed since location will be handled by address_id and administrative_division |
| postal_code    | VARCHAR(50)   | Customer’s postal code                                                            | H2G 1A7               | Will be normalized into a postal_zip_code table                                          |
| phone          | VARCHAR(50)   | Customer’s phone number                                                           | +1 (514) 721-4711     | Will be expanded to VARCHAR(255) in the final schema                                     |
| fax            | VARCHAR(50)   | Customer’s fax number                                                             | NULL                  | Will be expanded to VARCHAR(255) in the final schema                                     |
| email          | VARCHAR(50)   | Customer’s email address                                                          | ftremblay@gmail.com   | Will be expanded to VARCHAR(255) in the final schema                                     |
| support_rep_id | INT           | Identifier of the support representative, currently not enforced as a foreign key | 3                     | Will become an INT FK referencing employee(employee_id)                                  |
```
Notes:
* Any fields that may be missing in the source data (such as company or fax) are preserved as NULL.
* `last_name` and `first_name` will be modernized from fixed‑length CHARACTER to VARCHAR(255).
* The `address`, `city`, `state`, and `country` columns will be removed. Customers will reference the normalized address table through `address_id`.
* `postal_code` will be normalized into the `postal_zip_code` table.
* `company`, `phone`, `fax`, and `email` will be expanded to VARCHAR(255) to support longer values.
* `support_rep_id` will become a foreign key referencing `employee`.`employee_id`, modeling the relationship between customers and their assigned support representatives.

Sample rows:
```
customer_id,first_name,last_name,company,address,city,state,country,postal_code,phone,fax,email,support_rep_id
1,"Luís","Gonçalves","Embraer - Empresa Brasileira de Aeronáutica S.A.","Av. Brigadeiro Faria Lima, 2170","São José dos Campos","SP","Brazil","12227-000","+55 (12) 3923-5555","+55 (12) 3923-5566","luisg@embraer.com.br",3
2,"Leonie","Köhler",NULL,"Theodor-Heuss-Straße 34","Stuttgart",NULL,"Germany","70174","+49 0711 2842222",NULL,"leonekohler@surfeu.de",5
```
