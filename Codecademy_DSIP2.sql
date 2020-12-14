-- Top 10 tracks that appeared in the most playlists
SELECT tracks.TrackId,
	tracks.name,
	COUNT(playlist_track.TrackId) AS 'Appearance'
FROM tracks
JOIN playlist_track
	ON playlist_track.TrackId = tracks.TrackId
GROUP BY 1
ORDER BY 3 DESC
LIMIT 10;

-- Top 10 tracks that generated the most revenue 
SELECT tracks.TrackId,
	tracks.name,
	SUM(invoice_items.UnitPrice) AS ' Track Revenue'
FROM tracks
LEFT JOIN invoice_items
	ON tracks.TrackId = invoice_items.TrackId
GROUP BY tracks.TrackId
ORDER BY 3 DESC
LIMIT 10;

-- Top 10 genres that generated the most revenue
SELECT genres.GenreId,
	genres.name,
	ROUND(SUM(invoice_items.UnitPrice), 2) AS ' Genre Revenue'
FROM genres
INNER JOIN tracks 
	ON tracks.GenreId = genres.GenreId
INNER JOIN invoice_items
	ON tracks.TrackId = invoice_items.TrackId
GROUP BY genres.GenreId
ORDER BY 3 DESC
LIMIT 10;

--Top 10 albumns that generated the most revenue
SELECT albums.AlbumId,
	albums.Title,
	ROUND(SUM(invoice_items.UnitPrice), 2) AS 'Album Revenue'
FROM albums
INNER JOIN tracks
	ON tracks.AlbumId = albums.AlbumId
INNER JOIN invoice_items
	ON tracks.TrackId = invoice_items.TrackId
GROUP BY albums.AlbumId
ORDER BY 3 DESC
LIMIT 10;

--Top 10 countries with the highest revenue
SELECT invoices.BillingCountry,
	ROUND(SUM(invoice_items.UnitPrice), 2) AS 'Country Revenue',
	100 * ROUND(SUM(invoice_items.UnitPrice) / (SELECT SUM(invoice_items.UnitPrice) FROM invoice_items), 2)  AS '% of Total Country Revenue'
FROM invoices
INNER JOIN invoice_items
	ON invoices.InvoiceId = invoice_items.InvoiceId
INNER JOIN tracks
	ON tracks.TrackId = invoice_items.TrackId
GROUP BY invoices.BillingCountry
ORDER BY 2 DESC
LIMIT 10;

-- Number of customers each employee supported
SELECT employees.EmployeeId,
	employees.FirstName,
	employees.LastName,
	COUNT(customers.SupportRepId) AS 'Customers supported'
FROM employees
INNER JOIN customers
	ON customers.SupportRepId = employees.EmployeeId
GROUP BY employees.EmployeeId
ORDER BY 4 DESC;

-- Average revenue of each sale
SELECT ROUND(AVG(invoices.total), 2) AS 'Average Revenue/ Sale'
FROM invoices;

-- Average revenue of each sales employee
SELECT employees.EmployeeId,
	employees.FirstName,
	employees.LastName,
	(SELECT SUM(invoices.total) FROM invoices )/ (SELECT COUNT(*) FROM employees WHERE employees.Title LIKE '%sales%') AS 'Average Employee Sales Revenue'
FROM employees
WHERE employees.Title LIKE '%sales%'
GROUP BY employees.EmployeeId;

-- Total sale
SELECT SUM(invoices.total) AS 'Total Sales'
FROM invoices;

-- Do longer or shorter length albums tend to generate more revenue?
WITH 'albums_length' AS (
	SELECT albums.AlbumId,
		SUM(tracks.Milliseconds) AS 'Mslength'
	FROM albums
	INNER JOIN tracks
		ON tracks.AlbumId = albums.AlbumId
	GROUP BY albums.AlbumId
)
SELECT albums.AlbumId,
	albums.Title,
	albums_length.Mslength,
	SUM(invoice_items.UnitPrice) AS 'Revenue'
FROM albums
INNER JOIN albums_length
	ON albums_length.AlbumId = albums.AlbumId
INNER JOIN tracks
	ON tracks.AlbumId = albums.AlbumId
INNER JOIN invoice_items
	ON invoice_items.TrackId = tracks.TrackId
GROUP BY albums.AlbumId
ORDER BY 3 DESC;

-- Is the number of times a track appear in any playlist a good indicator of sales?
WITH 'track_appearance' AS (
	SELECT playlist_track.TrackId,
		COUNT(playlist_track.TrackId) AS 'Appearance'
	FROM playlist_track
	GROUP BY playlist_track.TrackId
)
SELECT track_appearance.TrackId,
	tracks.Name,
	track_appearance.Appearance,
	SUM(invoice_items.UnitPrice) AS 'Revenue'
FROM track_appearance
INNER JOIN invoice_items
	ON track_appearance.TrackId = invoice_items.TrackId
INNER JOIN tracks
	ON tracks.TrackId = invoice_items.TrackId
GROUP BY 1
ORDER BY 4 DESC;

-- How much revenue is generated each year, and what is its percent change from the previous year
WITH 'Revenue_year' AS (
	SELECT CAST(strftime('%Y', invoices.InvoiceDate) AS INTEGER) AS 'Year',
		ROUND(SUM(invoice_items.UnitPrice), 2) AS 'Revenue_by_Year'
	FROM invoices
	INNER JOIN invoice_items
			ON invoices.InvoiceId = invoice_items.InvoiceId
	GROUP BY 1
)
SELECT 2009,
	Revenue_year.Revenue_by_Year AS 'Revenue This Year',
	0.00 AS 'Percentage Growth from Previous Year (%)'
FROM Revenue_year
WHERE Revenue_year.Year = 2009
UNION
SELECT Revenue_year.Year,
	Revenue_year.Revenue_by_Year,
	ROUND(((Revenue_year.Revenue_by_Year - Revenue_year_prev.Revenue_by_year)/Revenue_year.Revenue_by_Year) * 100, 2)
FROM Revenue_year
INNER JOIN Revenue_year AS Revenue_year_prev
	ON Revenue_year_prev.Year = Revenue_year.Year - 1;
