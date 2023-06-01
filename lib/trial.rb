#Most read books:
SELECT
  book_id,
  book.title,
  COUNT(*) AS times_read
FROM `wp_bdb_reading_log` log INNER JOIN `wp_bdb_books` book ON book.id = log.book_id
GROUP BY book_id
HAVING times_read > 1
ORDER BY times_read DESC
LIMIT 25

#Books you own two or more copies of:
SELECT
  book_id,
  book.title,
  COUNT(*) AS number_copies
FROM `wp_bdb_owned_editions` e INNER JOIN `wp_bdb_books` book ON book.id = e.book_id
GROUP BY book_id
HAVING number_copies > 1
ORDER BY number_copies DESC

#Get all the books and their ratings from a specific term name ("Fantasy") that were read in 2017.
SELECT
  book.title,
  log.rating,
  log.date_finished
FROM `wp_bdb_books` book RIGHT JOIN `wp_bdb_reading_log` log ON log.book_id = book.id
  INNER JOIN `wp_bdb_book_term_relationships` r ON r.book_id = book.id
  INNER JOIN `wp_bdb_book_terms` term ON (term.id = r.term_id AND term.name = 'Fantasy')
WHERE 2017 = YEAR (date_finished)
ORDER BY log.date_finished ASC

#Same as above, but checks reviews only, where the review was written in a specific year (2017).
SELECT
  book.title,
  log.rating
FROM `wp_bdb_reviews` review RIGHT JOIN `wp_bdb_reading_log` log ON log.review_id = review.id
  INNER JOIN `wp_bdb_books` book ON book.id = review.book_id
  INNER JOIN `wp_bdb_book_term_relationships` r ON r.book_id = review.book_id
  INNER JOIN `wp_bdb_book_terms` term ON (term.id = r.term_id AND term.name = 'Fantasy')
WHERE 2017 = YEAR (date_written)
ORDER BY book.title ASC

#Get books with 4 stars or higher in the genres "Contemporary" and "Romance":
SELECT
  book.title,
  author.name,
  log.rating
FROM wp_bdb_books AS book
  INNER JOIN wp_bdb_book_author_relationships AS r ON book.id = r.book_id
  INNER JOIN wp_bdb_authors AS author ON r.author_id = author.id
  INNER JOIN wp_bdb_reading_log AS log ON book.id = log.book_id
WHERE log.rating > 4
      AND book.id IN (
  SELECT book_id
  FROM wp_bdb_book_term_relationships AS r
    INNER JOIN wp_bdb_book_terms AS t ON r.term_id = t.id
  WHERE t.name = 'Contemporary'
        AND book_id IN (
    SELECT book_id
    FROM wp_bdb_book_term_relationships AS r2
      INNER JOIN wp_bdb_book_terms AS t2 ON r2.term_id = t2.id
    WHERE t2.name = 'Romance'
  )
)
GROUP BY book.id
ORDER BY log.rating DESC

#Get a count of how many books were read in each format in a given year (2017).
SELECT
  format,
  COUNT(*) AS number_books_read
FROM `wp_bdb_owned_editions` AS b
  INNER JOIN wp_bdb_reading_log AS l ON l.book_id = b.book_id
WHERE 2017 = YEAR (date_finished)
GROUP BY format
ORDER BY format ASC;

#Get a count of how many books read in 2017 were published in each year.
SELECT
  YEAR(pub_date) AS pub_year,
  COUNT(*) AS number_books_published
FROM wp_bdb_books AS b
  INNER JOIN wp_bdb_reading_log AS l ON l.book_id = b.id
WHERE 2017 = YEAR (date_finished)
GROUP BY YEAR(pub_date)
ORDER BY pub_year DESC;

#Get your top 5 most read genres (order by ASC to get least read).
SELECT COUNT(log.id) AS count,t.name
FROM wp_bdb_reading_log AS log
INNER JOIN wp_bdb_book_term_relationships AS tr ON( log.book_id = tr.book_id )
INNER JOIN wp_bdb_book_terms AS t ON( tr.term_id = t.id )
WHERE t.taxonomy = 'genre'
GROUP BY t.name
ORDER BY count DESC
LIMIT 5;

#Average number of days it takes you to finish a book. To exclude DNF books, add another condition for AND percentage_complete >= 1.
SELECT ROUND( AVG( DATEDIFF( date_finished, date_started ) * percentage_complete ) ) + 1 AS number_days
FROM wp_bdb_reading_log
WHERE date_started IS NOT NULL
AND date_finished IS NOT NULL

#Average number of days between the date you acquire a book and the date you first start reading it.
SELECT ROUND( AVG( DATEDIFF( date_started, date_acquired ) ) ) + 1 AS number_days_to_start
FROM wp_bdb_owned_editions AS edition
INNER JOIN wp_bdb_reading_log AS log ON log.id = (
	SELECT id
	FROM wp_bdb_reading_log AS log2
	WHERE edition_id = edition.id
	AND date_started IS NOT NULL
	ORDER BY date_started
	LIMIT 1
)
WHERE date_acquired IS NOT NUL