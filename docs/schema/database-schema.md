# New Database Schema - Technical Specification

## Summary
This document provides a complete reference for every entity in the normalized PostgreSQL database.  
It describes each table’s purpose, key attributes, relationships and integrity rules,  
covering the entire music catalog, geographic hierarchy, customer/employee subsystem, and invoice model.  
It also outlines the constraints, indexes, and cascading behaviors that ensure data quality and predictable joins across the schema.  

## Table of Contents
- [Album](#--album--)
- [Artist](#--artist--)
- [ArtistAlbum](#--artistalbum--)
- [Composer](#--composer--)
- [Genre](#--genre--)
- [MediaType](#--mediatype--)
- [Playlist](#--playlist--)
- [Track](#--track--)
- [AlbumTrack](#--albumtrack--)
- [ComposerTrack](#--composertrack--)
- [GenreTrack](#--genretrack--)
- [PlaylistTrack](#--playlisttrack--)
- [Country](#--country--)
- [PostalZipCode](#--postalzipcode--)
- [AdministrativeDivision](#--administrativedivision--)
- [City](#--city--)
- [Address](#--address--)
- [Customer](#--customer--)
- [EmployeeLevel](#--employeelevel--)
- [EmployeeTitle](#--employeetitle--)
- [Employee](#--employee--)
- [Invoice](#--invoice--)
- [InvoiceLine](#--invoiceline--)

## Entity Documentation of the Normalized Database

### --Album--
Represents a published music album.  
Each album stores its title and connects to artists through the `artist_album` association table and to tracks through the `album_track` association table.

#### Responsibilities
* Store album information
* Maintain associations with contributing artists and related tracks
* Provide read‑only access to related artists and tracks

#### Attributes
* `album_id`: Primary key of the entity
* `album_title`: The title of the album

#### Relationships
* artist_albums: One‑to‑many collection of ArtistAlbum rows
* album_tracks: One‑to‑many collection of AlbumTrack rows
* artists: Read‑only many‑to‑many view of related Artist objects via `artist_album`
* tracks: Read‑only many‑to‑many view of related Track objects via `album_track`

#### Integrity & Performance
* Indexed `album_title`
* Check constraint prevents empty or whitespace‑only titles
* Foreign keys referencing `album_id` use RESTRICT, preventing deletion when linked to artists or tracks
* Association rows are protected from cascading deletes, so that albums cannot be deleted while referenced anywhere in the system

### --Artist--
Represents a musical artist or group.  
Artists may appear on multiple albums, and each association is stored explicitly in the `artist_album` table.

#### Responsibilities
* Store artist names
* Maintain associations with albums
* Provide read‑only access to related albums

#### Attributes
* `artist_id`: Primary key of the entity
* `artist_name`: Name of the artist or group

#### Relationships
* artist_albums: One‑to‑many collection of ArtistAlbum rows
* albums: Read‑only many‑to‑many view of related Album objects via `artist_album`

#### Integrity & Performance
* Indexed `artist_name`
* Check constraint prevents empty or whitespace‑only names
* Foreign keys referencing `artist_id` use RESTRICT, preventing deletion when linked to albums
* Association rows are protected from cascading deletes, so that artists cannot be deleted while referenced anywhere in the system

### --ArtistAlbum--
Association/Junction table linking artists and albums.

#### Responsibilities
* Represent the relationship between an artist and an album
* Enforce uniqueness of artist–album pairs
* Serve as the link between the two entities

#### Attributes
* `artist_album_id`: Primary key of the juction table
* `artist_id`: Foreign key referencing `artist`.`artist_id`
* `album_id`: Foreign key referencing `album`.`album_id`

#### Relationships
* artist: Many‑to‑one link to the Artist entity
* album: Many‑to‑one link to the Album entity

#### Integrity & Performance
* Indexes on both foreign keys
* Unique composite index on (`artist_id`, `album_id`) to prevent duplicates
* Cascading deletes are not allowed, so that all artist–album associations remain intact to protect historical catalog and invoice data

### --Composer--
Represents a musical composer or group.  
A composer may be credited on many tracks, and each association is stored explicitly in the `composer_track` table.

#### Responsibilities
* Store composer names
* Maintain associations with tracks
* Provide read‑only access to related tracks

#### Attributes
* `composer_id`: Primary key of the entity
* `composer_name`: Name of the composer or group

#### Relationships
* composer_tracks: One‑to‑many collection of ComposerTrack rows
* tracks: Read‑only many‑to‑many view of related Track objects via `composer_track`

#### Integrity & Performance
* Indexed `composer_name`
* Check constraint prevents empty or whitespace‑only names
* Delete cascades are intentionally disabled to preserve historical track and invoice relationships

### --Genre--
Represents a musical genre. Tracks may belong to multiple genres, and each link is represented by a GenreTrack row.

#### Responsibilities
* Store genre names
* Maintain associations with tracks
* Provide read‑only access to related tracks

#### Attributes
* `genre_id`: Primary key of the entity
* `genre_name`: Name of the genre

#### Relationships
* genre_tracks: One‑to‑many collection of GenreTrack rows
* tracks: Read‑only many‑to‑many view of related Track objects via `genre_track`

#### Integrity & Performance
* Unique constraint on `genre_name`
* Check constraint prevents empty or whitespace‑only names
* Delete cascades are intentionally disabled to preserve historical genre–track relationships

### --MediaType--
Represents a classification of how a track’s media is stored or delivered (e.g. MPEG audio, AAC, etc).  
Each media type may be associated with many tracks.

#### Responsibilities
* Store media type names
* Maintain the one‑to‑many relationship with tracks
* Enforce uniqueness and validity of media type names

#### Attributes
* `media_type_id`: Primary key of the entity
* `media_type_name`: Name of the media type

#### Relationships
tracks: One‑to‑many collection of related Track objects via `media_type_id`

#### Integrity & Performance
* Unique constraint ensures no duplicate media type names
* Check constraint prevents empty or whitespace‑only names
* Delete cascades are intentionally disabled, so that media types cannot be removed automatically when linked to tracks

### --Playlist--
Represents a user‑defined playlist.  
A playlist may contain many tracks, and each membership is represented by a PlaylistTrack row.

#### Responsibilities
* Store playlist names
* Maintain associations with tracks
* Provide read‑only access to playlist contents

#### Attributes
* `playlist_id`: Primary key of the entity
* `playlist_name`: Name of the playlist

#### Relationships
playlist_tracks: One‑to‑many collection of PlaylistTrack rows  
tracks: Read‑only many‑to‑many view of related Track objects via `playlist_track`

#### Integrity & Performance
* Check constraint prevents empty or whitespace‑only names
* Delete cascades are intentionally disabled, so that playlist–track links are preserved and not removed automatically

### --Track--
Represents an individual audio track.  
Tracks have a media type and may be associated with composers, genres, playlists, and albums through their respective association tables.

#### Responsibilities
* Store track information
* Link tracks to composers, genres, playlists, albums and invoice lines
* Provide read‑only many‑to‑many access to related entities

### Attributes
* `track_id`: Primary key of the entity
* `media_type_id`: Foreign key referencing `media_type`.`media_type_id`
* `track_name`: Name of the track
* `duration_milliseconds`: Duration of the track
* `size_bytes`: Size of the track in bytes
* `unit_price_cents`: Cost of the track converted into cents

#### Relationships
* media_type: Many‑to‑one link to MediaType
* composer_tracks: One‑to‑many collection of ComposerTrack rows
* genre_tracks: One‑to‑many collection of GenreTrack rows
* playlist_tracks: One‑to‑many collection of PlaylistTrack rows
* album_tracks: One‑to‑many collection of AlbumTrack rows
* composers: Read‑only many‑to‑many view via `composer_track`
* genres: Read‑only many‑to‑many view via `genre_track`
* playlists: Read‑only many‑to‑many view via `playlist_track`
* albums: Read‑only many‑to‑many view via `album_track`
* invoice_lines: One‑to‑many collection of InvoiceLine rows

#### Integrity & Performance
* Multiple indexes for efficient filtering
* Check constraints enforce valid numeric ranges and non‑empty names
* Foreign keys referencing `track_id` use RESTRICT, preventing deletion when any related invoice or catalog relationship exists
* Association rows are protected from cascading deletes, so that Tracks cannot be deleted when referenced by any invoice or catalog relationship
* Tracks form the core of catalog and financial history, and therefore are deletion‑protected

### --AlbumTrack--
Association/Junction table linking albums and tracks.

#### Responsibilities
* Represent the relationship between an album and a track
* Enforce uniqueness of album–track pairs
* Serve as the link between the two entities

#### Attributes
* `album_track_id`: Primary key of the juction table
* `album_id`: Foreign key referencing `album`.`album_id`
* `track_id`: Foreign key referencing `track`.`track_id`

#### Relationships
* album: Many‑to‑one link to the Album entity
* track: Many‑to‑one link to the Track entity

#### Integrity & Performance
* Indexes on both foreign keys
* Unique composite index on (`album_id`, `track_id`) to prevent duplicates
* Foreign keys use RESTRICT, preventing deletion of albums or tracks when linked
* Association rows are protected from cascading deletes

### --ComposerTrack--
Association/Junction table linking composers and tracks.

#### Responsibilities
* Represent the relationship between composer and track
* Enforce uniqueness of composer–track pairs
* Serve as the link between the two entities

#### Attributes
* `composer_track_id`: Primary key of the juction table
* `composer_id`: Foreign key referencing `composer`.`composer_id`
* `track_id`: Foreign key referencing `track`.`track_id`

#### Relationships
* composer: Many‑to‑one link to Composer
* track: Many‑to‑one link to Track

#### Integrity & Performance
* Indexes on both foreign keys
* Unique composite index on (`composer_id`, `track_id`) to prevent duplicates
* Foreign keys use RESTRICT, preventing deletion of composers or tracks when linked
* Association rows are protected from cascading deletes

### --GenreTrack--
Association/Junction table linking genres and tracks.

#### Responsibilities
* Represent the relationship between music genre and track
* Enforce uniqueness of genre-track pairs
* Serve as the link between the two entities

#### Attributes
* `genre_track_id`: Primary key of the juction table
* `genre_id`: Foreign key referencing `genre`.`genre_id`
* `track_id`: Foreign key referencing `track`.`track_id`

#### Relationships
* genre: Many‑to‑one link to Genre
* track: Many‑to‑one link to Track

#### Integrity & Performance
* Indexes on both foreign keys
* Unique composite index on (`genre_id`, `track_id`) to prevent duplicates
* Foreign keys use RESTRICT, preventing deletion of genres or tracks when linked
* Association rows are protected from cascading deletes

### --PlaylistTrack--
Association/Junction table linking playlists and tracks.

#### Responsibilities
* Represent the relationship between a playlist and a track
* Enforce uniqueness of playlist-track pairs
* Serve as the link between the two entities

#### Attributes
* `playlist_track_id`: Primary key of the juction table
* `playlist_id`: Foreign key referencing `playlist`.`playlist_id`
* `track_id`: Foreign key referencing `track`.`track_id`

#### Relationships
* playlist: Many‑to‑one link to Playlist
* track: Many‑to‑one link to Track

#### Integrity & Performance
* Indexes on both foreign keys
* Unique composite index on (`playlist_id`, `track_id`) to prevent duplicates
* Foreign keys use RESTRICT, preventing deletion of playlists or tracks when linked
* Association rows are protected from cascading deletes

### --Country--
Represents a sovereign nation and functions as the root of the geographic hierarchy.

#### Responsibilities
* Store country information
* Enforce ISO code format
* Parent entity for postal codes and administrative divisions

#### Attributes
* `country_id`: Primary key of the entity
* `country_name`: Name of the country
* `country_iso_code`: ISO code of the country

#### Relationships
* postal_zip_codes: One‑to‑many link to PostalZipCode
* administrative_divisions: One‑to‑many link to AdministrativeDivision

#### Integrity & Performance
* Index on `country_name`
* Unique constraint on `country_iso_code`
* Check constraints enforce format and cleanliness
* Foreign keys in child tables use RESTRICT, preventing deletion of a country when referenced by postal codes or administrative divisions
* Association rows are protected from cascading deletes

### --PostalZipCode--
Represents postal or ZIP codes.

#### Responsibilities
* Store postal/zip codes
* Link postal codes to countries and addresses

#### Attributes
* `postal_zip_code_id`: Primary key of the entity
* `country_id`: Foreign key referencing `country`.`country_id`
* `code`: The postal/zip code

#### Relationships
* country: Many‑to‑one link to Country
* addresses: One‑to‑many link to Address

#### Integrity & Performance
* Index on `code`
* Unique constraint on `country_id` and `code`to prevent duplicates
* Check constraint prevents whitespace‑only codes
* Foreign keys use RESTRICT, preventing deletion of countries or postal codes when referenced
* Association rows are protected from cascading deletes

### --AdministrativeDivision--
Represents first‑level administrative regions (states, provinces, regions, etc.).

#### Responsibilities
* Store division names and types
* Group cities

#### Attributes
* `administrative_division_id`: Primary key of the entity
* `country_id`: Foreign key referencing `country`.`country_id`
* `division_name`: Name of the administrative division
* `division_type`: Type of the administrative division

#### Relationships
* country: Many‑to‑one link to Country
* cities: One‑to‑many link to CIty

##### Integrity & Performance
* Index on `division_name`
* Unique constraint on (`country_id`, `division_name`) to prevent duplicates
* Check constraints prevents empty or whitespace‑only names or types
* Foreign keys use RESTRICT, preventing deletion of a country when divisions exist
* Association rows are protected from cascading deletes

### --City--
Represents a city or municipality.

#### Responsibilities
* Store city names
* Group addresses

#### Attributes
* `city_id`: Primary key of the entity
* `administrative_division_id`: Foreign key referencing `administrative_division`.`administrative_division_id`
* `city_name`: Name of the city

#### Relationships
* administrative_division: Many‑to‑one link to AdministrativeDivision
* addresses: One‑to‑many link to Address

#### Integrity & Performance
* Index on `city_name`
* Unique constraint on (`administrative_division_id`, `city_name`) to prevent duplicates
* Check constraints prevents empty or whitespace‑only names
* Foreign keys use RESTRICT, preventing deletion of an administrative division when cities exist
* Cities cannot be deleted while referenced by addresses

### --Address--
Represents a physical address.

#### Responsibilities
* Store address lines
* Link addresses to cities and postal codes
* Provide location data for employees and customers

#### Attributes
* `address_id`: Primary key of the entity
* `city_id`: Foreign key referencing `city`.`city_id`
* `postal_zip_code_id`: Foreign key referencing `postal_zip_code`.`postal_zip_code_id` (optional)
* `address_line_1`: First part of address (required)
* `address_line_2`: First part of address (optional)

#### Relationships
* city: Many‑to‑one link to City
* postal_zip_code: Many‑to‑one link to PostalZipCode
* customers: One‑to‑many link to Customer
* employees: One‑to‑many link to Employee

#### Integrity & Performance
* Indexes on `city_id` and `postal_zip_code_id`
* Check constraints ensure clean address lines
* Foreign keys use RESTRICT, preventing deletion of cities or postal codes when addresses exist
* Addresses cannot be deleted while referenced by customers or employees

### --Customer--
Represents a client who purchases products and receives invoices.  
Each customer is linked to an address and is assigned a responsible employee representative.

#### Responsibilities
* Store customer identity and contact information
* Associate customers with their representative employee
* Maintain a history of invoices

#### Attributes
* `customer_id`: Primary key of the entity
* `address_id`: Foreign key referencing `address`.`address_id` (optional)
* `representative_id`: Foreign key referencing `employee`.`employee_id`
* `customer_last_name`: Last name of the customer
* `customer_first_name`: First name of the customer
* `customer_company`: Company of the customer (optional)
* `customer_phone`: Telephone number of the customer
* `customer_fax`: Fax number of the customer (optional)
* `customer_email`: Email of the customer

#### Relationships
* address: Many‑to‑one link to Address
* representative: Many‑to‑one link to Employee
* invoices: One‑to‑many collection of Invoice rows

#### Integrity & Performance
* Indexes on `address_id` and `representative_id`
* Unique email ensures customer identity consistency
* Check constraints prevents empty or whitespace‑only fields
* Foreign keys use RESTRICT, preventing deletion of addresses or employees when customers reference them
* Customers cannot be deleted while invoices exist
* No cascading deletes are allowed, in order to preserve invoice history

### --EmployeeLevel--
Lookup table defining employee seniority or classification levels.

#### Responsibilities
* Store standardized employee level codes
* Associate levels with employees

#### Attributes
* `employee_level_id`: Primary key of the entity
* `employee_level_code`: Representation of the level

#### Relationships
* employees: One‑to‑many collection of employees assigned to a specific level

#### Integrity & Performance
* Unique constraint on `employee_level_code`
* Check constraints enforce length and non‑whitespace
* Foreign keys in Employee use RESTRICT, preventing deletion of a level when employees reference it
* Association rows are protected from cascading deletes, so that levels cannot be deleted while linked to employees

### --EmployeeTitle--
Lookup table defining job titles for employees.

#### Responsibilities
* Store unique employee titles
* Associate titles with employees

#### Attributes
* `employee_title_id`: Primary key of the entity
* `employee_title_name`: Name of the title

#### Relationships
* employees: One‑to‑many collection of employees with a specific title

#### Integrity & Performance
* Index on `employee_title_name`
* Check constraint prevents whitespace‑only titles
* Foreign keys in `employee` use RESTRICT, preventing deletion of a title when employees reference it
* Association rows are protected from cascading deletes, so that titles cannot be deleted while linked to employees

### --Employee--
Represents a company employee.  
Employees have a title, level, address, and may manage other employees.  
They may also serve as customer representatives.

#### Responsibilities
* Store employee identity, contact details, and employment information
* Maintain hierarchical reporting structure
* Associate employees with customers they represent

#### Attributes
* `employee_id`: Primary key of the entity
* `employee_level_id`: Foreign key referencing `employee_level`.`employee_level_id`
* `employee_title_id`: Foreign key referencing `employee_title`.`employee_title_id`
* `address_id`: Foreign key referencing `address`.`address_id`
* `manager_id`: Self‑referential foreign key (optional)
* `employee_last_name`:  Last name of the employee
* `employee_first_name`: First name of the employee
* `employee_birthdate`: Birth date of the employee
* `employee_hiredate`:  Hire date of the employee
* `employee_phone`: Telephone number of the employee
* `employee_fax`: Fax number of the employee (optional)
* `employee_email`: Email of the employee

##### Relationships
* level: Many‑to‑one link to EmployeeLevel
* title: Many‑to‑one link to EmployeeTitle
* address: Many‑to‑one link to Address
* manager: Self‑referential many‑to‑one
* customers: One‑to‑many collection of customers represented by a specific employee

#### Integrity & Performance
* Indexes on all foreign keys and on `employee_last_name`
* Unique constraint on `employee_email` ensures identity consistency
* Check constraints enforce valid dates and non‑empty fields
* Birthdate of an employee must precede their hire date 
* Self‑referential hierarchy is deletion‑safe, so that managers cannot be deleted while subordinates exist
* Foreign keys use RESTRICT, preventing deletion of levels, titles, addresses, or managers when employees reference them
* Employees cannot be deleted while customers reference them, so that invoice history is preserved
* No cascading deletes are allowed in order to retain organizational structure and customer relationships

### --Invoice--
Represents a customer invoice.  
Billing information is stored denormalized to preserve historical accuracy.

#### Responsibilities
* Store invoice and billing details
* Associate invoices with customers
* Maintain line‑item details

#### Attributes
* `invoice_id`: Primary key of the entity
* `customer_id`: Foreign key referencing `customer`.`customer_id`
* `invoice_datetime`: Date and time the invoice was created
* `billing_address`: Customer’s address at the moment the invoice was issued
* `billing_city`: Customer’s city at the moment the invoice was issued
* `billing_administrative_division`: Customer’s administrative division at the moment the invoice was issued
* `billing_country`: Customer’s country at the moment the invoice was issued
* `billing_postal`: Customer’s postal or zip code at the moment the invoice was issued
* `invoice_total_cents`: Total amount of the invoice in cents

#### Relationships
* customer: Many‑to‑one link to Customer
* invoice_lines: One‑to‑many collection of InvoiceLine rows

#### Integrity & Performance
* Indexes on `customer_id` and `invoice_datetime`
* Check constraints enforce non‑empty billing fields
* Non‑negative total ensures financial correctness
* Foreign keys use RESTRICT, preventing deletion of customers when invoices exist
* Invoices cannot be deleted while invoice lines exist
* No cascading deletes are allowed so that, invoice and billing records remain intact for audit and reporting

### --InvoiceLine--
Represents an individual line item on an invoice.  
Each line links to a track and stores quantity and pricing information.

#### Responsibilities
* Represent invoice line‑item details
* Store pricing and quantity information
* Link invoices to purchased tracks

#### Attributes
* `invoice_line_id`: Primary key of the entity
* `invoice_id`: Foreign key referencing `invoice`.`invoice_id`
* `track_id`: Foreign key referencing `track_id`.`track_id`
* `unit_price_cents`: Price of the track in cents
* `quantity`: Quantity purchased

#### Relationships
* invoice: Many‑to‑one link to Invoice
* track: Many‑to‑one link to Track

#### Integrity & Performance
* Indexes on `invoice_id` and `track_id`
* Check constraints enforce valid pricing and quantity
* Foreign keys use RESTRICT, preventing deletion of invoices or tracks when invoice lines exist
* InvoiceLine is the final protection layer preventing Track deletion
* No cascading deletes are allowed in order to preserve financial accuracy
