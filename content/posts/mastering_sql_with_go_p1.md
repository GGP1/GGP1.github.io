---
title: "Mastering SQL with Go - Part 1"
description: ""
date: 2024-11-24
draft: false
showToc: true
tocOpen: false
image: "/images/sql_go_p1.png" # image path/url
tags:
  - Go
  - SQL
---

I found myself using SQL a lot in one of my projects and I have learnt many things while trying to solve the problems I encountered.

This post is the part one of a series where I will try to show how to manage data in a relational database using SQL (Postgre syntax), Go and its standard library package [`database/sql`](https://github.com/golang/go/tree/master/src/database/sql).

Explaining absolutely everything would require an entire book so I will skip the subjects that most articles already cover (connection establishment, foreign keys, parameterized arguments, etc).

## Connection tuning

When we connect to an SQL database through a driver and using the `database/sql` package we get the [`sql.DB`](https://pkg.go.dev/database/sql#DB) database handle, which manages a pool of active connections that are safe for concurrent use, creating new ones when required. 

> To perform actions on a dedicated connection, we can use [`sql.Conn`](https://pkg.go.dev/database/sql#Conn).

The management of these connections can be personalized by using the following methods:

```go
// Set the maximum number of concurrent open connections.
// There is no limit defined by default.
// After the limit is passed, new datatabase operations will block 
// until there's an available connection.
db.SetMaxOpenConns(n int)

// Set a connection's maximum life time.
// Default is 2.
// Increasing this value will improve the database performance at the
// cost of consuming more memory to keep the connections alive.
db.SetMaxIdleConns(n int)

// Set a connection's maximum life time, once the time is reached it 
// cannot be used again.
// By default connections are reused forever.
// Every one second the `database/sql` package removes expired connections 
// from the pool.
db.SetConnMaxLifetime(d time.Duration)

// Set a connection's maximum idle time.
// No value is set by default, connections may be idle their entire lifetime.
db.SetConnMaxIdleTime(d time.Duration) 
```

The recommended values for these configurations depend on the type of application the database is used for, it may be convenient to specify and tweak them on the fly based on metrics gathered. 

I personally prefer to begin limiting the maximum number and time of **idle** connections to avoid holding them for a long period of time (i.e. a burst of requests may open many connections that later won't be used anymore).

> A simple and useful way of getting more information about the database connection is the [`db.Stats()`](https://pkg.go.dev/database/sql#DB.Stats) method.

## Scanning null values

If we attempt to scan a null value into a non-pointer variable we will receive an error saying that a null value can't be scanned into a Go type. There are (at least) three ways to address this problem:

### COALESCE

The *COALESCE* function takes *n* arguments and returns the first one that is not null, hence, we can use the targeted field as the first argument and then a default value to be returned when the first one is null.

The query would be as follows: 
```go
"SELECT COALESCE(description, '') as description FROM posts WHERE id='sample"
```

### Standard library types

The `database/sql` package has various types for scanning potentially null values (`sql.NullString`, `sql.NullInt`, `sql.NullBool`, etc.)

```go
// SELECT description FROM posts WHERE id='sample';
func scanString(row *sql.Row) (string, error) {
	var nullable sql.NullString
	if err := row.Scan(&nullable); err != nil {
		return "", err
	}
	// We can check if the value is null by using the nullable.Valid field.
	if !nullable.Valid {
		// nullable is null
	}

	return nullable.String, nil
}
```

### Pointers

The last option, and probably the most used one, is to declare a pointer that will be equal to `nil` in case there is no value stored.

```go
// SELECT description FROM posts WHERE id='sample';
func scanString(row *sql.Row) (*string, error) {
	var nullable *string
	if err := row.Scan(&nullable); err != nil {
		return "", err
	}

	return nullable, nil
}
```

## Storing slices

Storing a list of items that correspond to an object is generally done by using a new table and a foreign key to link both records.

However, in the case of simple data types like text and integer we can use `text[]` and `integer[]` respectively.

This isn't only simpler but it doesn't require to create a new table and one new row per slice element. 

> For further information, see the [official docs](https://www.postgresql.org/docs/14/arrays.html).

Let's take a look at how to store a string slice in PostgreSQL with Go:

```go
// Package "github.com/lib/pq" required
//
// `keys` field is of type text[]
func insertKeys(db *sql.DB, id string, keys pq.StringArray) error {
	_, err := db.Exec("INSERT INTO users (keys) VALUES ($2) WHERE id=$1", id, keys)
	if err != nil {
		return err
	}
	return nil
}

// pq.StringArray underlying type is []string
func getKeys(db *sql.DB, id string) ([]string, error) {
	row := db.QueryRow("SELECT keys FROM users WHERE id=$1", id)
	var keys pq.StringArray
	if err := row.Scan(&keys); err != nil {
		return nil, err
	}
	return keys, nil
}
```

## Update only what changes

The [COALESCE](#coalesce) function we've seen above is also handy for updating only the fields that the user specified a value for.

Consider a scenario where we want the users to update a post's content, the image or both.

We will use string pointers for our struct fields to distinguish null values, otherwise we wouldn't know whether the user wants to store and empty string or to not change anything.

```go
type UpdatePost struct {
	Content *string
	Image *string
}

func updatePost(db *sql.DB, id string, post UpdatePost) error {
	q := `UPDATE posts SET 
	content = COALESCE($2, content)
	image = COALESCE($3, image)
	WHERE id = $1`
	_, err := db.Exec(q, id, post.Content, post.Image)
	return err
}
```

This way, if the user updated the content only, COALESCE will detect that the image argument is null and thus use the already stored value, leaving the field as it was prior to the update.

## Batch inserts

Inserting multiple records at once is typically an expensive operation and that's why we need an optimal solution for it.

### Bulk imports

The `COPY` command is optimized for loading large numbers of rows; it is less flexible than `INSERT`, but incurs significantly less overhead for large data loads. 

Since it's a single command, there is no need to disable autocommit if you use this method to populate a table. Also, it stops operation at the first error.

`COPY FROM` will invoke any triggers and check constraints on the destination table. However, it will not invoke rules.

```go
func bulkImports(db *sql.DB, posts []Post) error {
	stmt, err := db.Prepare("COPY posts (id, title, content) FROM STDIN")
	if err != nil {
		return err
	}
	defer stmt.Close()
	
	for _, post := range posts {
		_, err := stmt.ExecContext(ctx, post.ID, post.Title, post.Content)
		if err != nil {
			return err
		}
	}
	
	// Flush buffered data
	if _, err := stmt.ExecContext(ctx); err != nil {
		return err
	}

	return nil
}
```

### Query building

Another way to insert multiple records in one call is to build a query containing a set of arguments for each of them. 

For example: 

```go	
"INSERT INTO posts (id, title, content, image) VALUES ($1, $2, $3), ($4, $5, $6)"
```

> Take a look at the implementation [here](https://stackoverflow.com/questions/12486436/how-do-i-batch-sql-statements-with-package-database-sql).
>
> Note that the maximum number of arguments supported by `VALUES` is 1000.

## Pagination

Pagination is the process of dividing a document into discrete pages.

In programming, we provide our clients the possibility to paginate the list of results by using a cursor.

A cursor could be thought as a flag that divides already seen records and not yet seen ones. 

On each request, we return a new cursor (which may be an id or an encoded string) so the user can ask for more records without getting repeated ones.

Here are two common ways of implementing pagination in SQL that are safe from injection:

### Using UUIDs

We select the posts that were created before the date passed, in case the date matches with the creation timestamp, the ID is compared.

> In this case, the cursor is generally an encoded string that contains both the ID and the creation timestamp.

```go
// Requires the table to have a field with a timestamp of the value creation
id := "3c0217ac-503f-45dc-b150-0b1618155d3d"
createdAt := time.Now()
q := `SELECT * FROM posts WHERE 
created_at < $1 OR (created_at = $1 AND id < $2) 
ORDER BY created_at DESC, id DESC LIMIT 5`
db.Query(q, createdAt, id)
```

### Using lexicographically sortable IDs

Since the IDs are already sorted there is no need to compare the creation date, the ID is the cursor itself.

```go
id := "01FMA344NAGPSKF4TNAXMC06KS"
db.Query("SELECT * FROM posts WHERE id < $1 ORDER BY id DESC LIMIT 5", id)
```

## Prepared statements

When we make a query using [`db.Query()`](https://pkg.go.dev/database/sql#DB.Query), a prepared statement is built underneath to run it, but it's used only once.

If we were to execute the same query multiple times, we would be wasting resources as the prepared statement would be compiled on each iteration.

In order to fix this, we can use *prepared statements*, they allow us to compile the query with parameterized arguments separetely and then use that statement *n* times.

Another advantage is that multiple queries or executions may be run concurrently from the returned statement.

```go
stmt, err := db.Prepare("SELECT * FROM posts WHERE id=$1")
if err != nil {
	return err
}
// Remember to always close the statement when 
// it's no longer needed to free up resources
defer stmt.Close()

for _, id := range postIDs {
	if _, err := stmt.QueryRowContext(ctx, id); err != nil {
		return err
	}
	// Scan post
}
```

## Stored procedures

Stored procedures are user-defined functions that can be stored in the database for later reuse, they can contain parameters but can't return anything.

As simple as that, let's implement a stored procedure for updating a post's likes:

```go
// Check if the user already liked the post, if yes, remove the like, if not, add it.
q := `CREATE OR REPLACE PROCEDURE likePost(postID text, userID text) AS $$
	BEGIN
		IF EXISTS (SELECT 1 FROM post_likes WHERE post_id=postID AND user_id=userID) THEN
	   		DELETE FROM post_likes WHERE post_id=postID AND user_id=userID;
	   	ELSE
	   		INSERT INTO post_likes (post_id, user_id) VALUES (postID, userID);
	   	END IF;
	END 
$$ LANGUAGE plpgsql`
db.ExecContext(ctx, q)
```

We can execute it doing:

```go
db.ExecContext(ctx, "CALL likePost($1, $2)", postID, userID)
```

## Parting words

I hope you found this post useful, in the next one we will be taking a look at transactions (propagation using context and isolation levels), dynamic scanning, full text search, recursive queries and much more.
