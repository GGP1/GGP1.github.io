---
title: "Mastering SQL with Go - Part 2"
description: ""
date: 2025-04-13
draft: false
showToc: true
tocOpen: false
image: "/images/sql_go_p2.png" # image path/url
---

This is the part 2 of a series covering **sql** and **Go**, this time, we will cover how to work with SQL transactions context and isolation levels, results dynamic scanning, full text search and recursive queries as well as using multiple result sets to do many queries in a single roundtrip.

> To go to part one, click [here](../mastering_sql_with_go_p1).

## Transactions

Let's start with transactions, why are they necessary?

A transaction is a way for an application to group several reads and writes together into a logical unit.

Conceptually, all the reads and writes in a transaction are executed as one operation: either the entire transaction succeeds (*commit*) or it fails (*abort*/*rollback*).

They are an abstraction layer that allows an application to pretend that certain concurrency problems and certain kinds of hardware and software faults don't exist.

Let's see how can we take advantage of them.

### Propagation using context

Specially in large projects, a single request can perform several calls to one or perhaps many services. 

If we were to execute and commit this operations separately, any error that occurs between them leaves the database in a corrupted state.

In order to avoid this, we need to "share" or execute the whole workflow in a single transaction, taking advantage of the [ACID](https://en.wikipedia.org/wiki/ACID)  (atomicity, consistency, isolation, durability) properties they bring us.

This way, we commit all the changes that were made in a single and atomic transaction, making sure that they either **succeed** or **fail completely**. In some cases, if the transaction fails, we can simply retry.

Now, passing down transactions as parameters will mess the code up and it isn't a scalable solution. We will store the transaction in the request's context so it can be accessed on lower layers:

```go
// --- sqltx.go ---
package sqltx

import (
	"context"
	"database/sql"
)

// txKey is the context key for the sql transaction.
var txKey key

type key struct{}

// NewContext returns a new context with a sql transaction in it.
func NewContext(ctx context.Context, tx *sql.Tx) context.Context {
	if ctx == nil {
		ctx = context.Background()
	}
	return context.WithValue(ctx, txKey, tx)
}

// FromContext returns the sql transaction stored in the context.
//
// It panics if there is no transaction.
func FromContext(ctx context.Context) *sql.Tx {
	tx, ok := ctx.Value(txKey).(*sql.Tx)
	if !ok {
		panic("sql tx not found")
	}
	return tx
}

// --- service.go ---
type service struct{}

func (s *service) MutationA(ctx context.Context) {
	sqlTx := sqltx.FromContext(ctx)
	q := "INSERT INTO posts (id, title, content) VALUES ('1', 'Title', 'Post content')"
	sqlTx.ExecContext(ctx, q)
}

func (s *service) MutationB(ctx context.Context) {
	sqlTx := sqltx.FromContext(ctx)
	sqlTx.ExecContext(ctx, "UPDATE users SET posts_count = posts_count + 1")
}

// --- handler.go ---
// db and service objects creation omitted to simplify the scenario
func HandleRequest(w http.ResponseWriter, r *http.Request) {
	tx, _ := db.BeginTx()
	defer tx.Rollback()

	ctx := sqltx.NewContext(r.Context(), tx)
	if err := service.MutationA(ctx); err != nil {
		// Rollback changes
	}
	if err := service.MutationB(ctx); err != nil {
		// Rollback changes
	}
	// Commit both mutations atomically, in case of a failure none will take effect
	_ = tx.Commit()
}
```

This way, we can easily use the same transaction in different operations and even services. Given that it's stored at the request-level, the action the user took will either succeed or fail, but it will always prevent leaving the system in a corrupted state.

But this is not the only thing to take into account when working with SQL, there is also different kind of transactions that have different consistency and performance trade-offs, let's review them.

### Isolation levels

Many databases support setting different isolation levels to transactions, an isolation level determines the degree to which that data is isolated from other concurrent processes.

A lower isolation level allows many users to access the same information at the same time, but increases the probabilities of encountering inconsistencies among the different results. A higher isolation level ensures less concurrency effects but requires most system resources and the chances that one transaction may block another.

Some of the ones supported by the Go standard library package are:

- **Read uncommitted**: In this level a transaction may see uncommited changes made by other transactions, it's the lowest isolation level.

	> PostgreSQL's Read Uncommitted mode behaves like Read Committed.

- **Read committed**: It's the default level. A query sees only data committed before the query began; it never sees either uncommitted data or changes committed during query execution by concurrent transactions. 

	However, the query does see the effects of previous updates executed within its own transaction, even though they are not yet committed.

	Note that two successive `SELECT` commands can see different data.

- **Repeatable read**: In this level, the transaction only sees data committed before it began. 

	This level is different from Read Committed in that a query in a repeatable read transaction sees a snapshot as of the start of the first non-transaction-control statement in the transaction, not as of the start of the current statement within the transaction. Thus, successive SELECT commands within a single transaction see the same data.

- **Serializable**: It is the strictest isolation level. In it, transactions are executed sequentially, that is, one after another and without any concurrency.

In Go, one could create a transaction with a specific isolation level by doing:

```go
tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
```

Having discussed how to manage transactions and the different kind of them, let's move over to the concept of dynamic scanning, parsing SQL transactions results without having to code one method per query. 

## Dynamic scanning

The Go standard library provides a basic interface that does an acceptable job, but in some cases it falls behind requirements like:

- Use always the same method for scanning any type of object
- Scan fields dynamically (let the user choose which fields to receive)
- Simple and compact interface

Let's take a look at how we would scan fields into an object with Go's native methods

```go
type Post struct {
	Title string
	Content string
}

func getPosts(id string) ([]Post, error) {
	rows, _ := db.Query("SELECT title, content FROM posts WHERE id=$1", id)

	var posts []Post
	for rows.Next() {
		var post Post
		// Here we would have to add all the fields we want to scan, 
		// the bigger the struct and the query the messier it becomes
		if err := rows.Scan(&post.Title, &post.Content); err != nil {
			return nil, err
		}
		posts = append(posts, post)
	}

	if err := rows.Close(); err != nil {
		return err
	}

	return posts, nil
}
```

This implementation is verbose, it would require us to create a method for every query (or at least those that are not equal) and the fields returned are hardcoded. 

Hopefully, we have many solutions for these problems, there are many production-ready packages that help manage sql queries in a simple and clean way. 

In this case, I'm going to introduce one that is simple, compatible with the standard library and that supports recursive mapping of object fields. It's called [sqan](https://github.com/GGP1/sqan), and I will explain how it works in the next two sections: *mapping* and *scanning*.

### Mapping

Sqan maps objects fields using a nested map where the top level key is the field type, the inner map then uses the field names or their `db` tag (if specified) as the key and the indices they represent inside the struct as the value.

> Unexported fields and struct slices are skipped

For example, the following struct

```go
type Post struct {
	Title string `db:"title"` // Optional, could be any string
	Content string
	Comment Comment
}

type Comment struct {
	Content string
	Likes int
}
```

is mapped like

```
Post:
	title: 0
	content: 1
	content: 2 0
	likes: 2 1
```

The field's type and indices are obtained using reflection, in case the field is an embedded struct, the mapping is done in the same way as the top one (using recursion).

The mapping is executed the first time the struct is used to store sql results and the information remains in memory and ready to be used by the scanner.

### Scanning

When scanning results, Sqan looks for the columns names in the SQL query and creates a slice with the fields required and an empty value for each of them, which will then be populated by the SQL scanner with the values retrieved from the database.

It uses the field's indices stored in the map to know where to allocate the empty value and reflection to create it.

And that's how we use every value from the map to generate dynamic slices to scan SQL results.

```go
func getPosts(id string) ([]Post, error) {
	rows, _ := db.Query("SELECT title, content FROM posts WHERE id=$1", id)

	var posts []Post
	if err := sqan.Rows(&posts, rows); err != nil {
		return nil, err
	}

	return posts, nil
}
```

Now our Go code is not only simpler, but we could also let the clients (validating and sanitizing their inputs) ask for fields on demand.

> Sqan also works when scanning a single value (`sqan.Row()`)

## Full Text Search

There are cases in which a simple `SELECT <fields>` falls short to deliver what we are looking for. Full text search is one of those cases, if we want to get rows that contain but are not equals to a speficic value, we will have to use them. Let's see how they work. 

To implement full text searching there must be a function to create a `tsvector` from a document and a `tsquery` from a user query. 

The function we are going to use is`to_tsvector`, which parses a textual document into tokens and reduces the tokens to lexemes. Here is an example:

```sql
SELECT to_tsvector('english', 'a fat  cat sat on a mat - it ate a fat rats');
                  to_tsvector
-----------------------------------------------------
 'ate':9 'cat':3 'fat':2,11 'mat':7 'rat':12 'sat':4

-- The resulting tsvector does not contain the words a, on, or it, the word rats became rat, and the punctuation sign - was ignored
```

We can use the function `to_tsvector()` to create a vector on a table field. For example, here we will look for the text "Rice" in the field "title"

```go
// If you want to match any string starting with the value below, add ":*" to it to match prefixes as well
text := "Rice"
q := "SELECT title, description FROM posts WHERE to_tsvector(title) @@ plainto_tsquery($1)"
db.Query(q, text)
```

> `plainto_tsquery` transforms the unformatted text querytext to a `tsquery` value. The text is parsed and normalized much as for to_tsvector, then the & (AND) tsquery operator is inserted between surviving words.

It will return all the products that contain the word "Rice" on its title.

To look for text on several fields, concatenate using `|| ' ' ||`:

```go
"... to_tsvector(title || ' ' || description) ..."
```

> There's no limit to the number of fields that can be included as vectors to look for text in them, the only constraint is performance.

However, by querying information this way, we are creating the vectors on the fly and if we perform many queries of these type the SQL engine would have to generate the indices on each one of the operations, which is really inefficient.

To solve this, we can instruct the database to create the index when the table is created and to update it each time a new row is inserted, effectively moving the calculations to the *write side*.

```sql
CREATE TABLE IF NOT EXISTS products
(
	title text NOT NULL,
	description text NOT NULL,
	search tsvector -- The search field will represent an index of both title and description field contents
)

-- Create index of type GIN (more about GIN at https://www.postgresql.org/docs/15/gin-intro.html)
CREATE INDEX ON products USING GIN (search);

-- Create the function that creates the index
CREATE OR REPLACE FUNCTION products_tsvector_trigger() RETURNS trigger AS $$
BEGIN
	-- setweight takes a vector and a letter, and it's typically used to mark different parts of a document
	-- Later, they can be used for ranking search results
	new.search :=
	setweight(to_tsvector('english', new.title), 'A')
	|| setweight(to_tsvector('english', new.description), 'B');
	return new;
END
$$ LANGUAGE plpgsql;

-- Delete the trigger if it existed previously so the operation below does not fail
DROP TRIGGER IF EXISTS products_tsvector_update ON products;

-- Instruct the database to execute the trigger before each product addition
CREATE TRIGGER products_tsvector_update BEFORE INSERT OR UPDATE
    ON products FOR EACH ROW EXECUTE PROCEDURE products_tsvector_trigger();
```

> If the fields you are using can be null, you should use the `coalesce()` function when creating the index to convert the content to an empty string, i.e `to_tsvector(coalesce(title,''))`. Otherwise `to_tsvector(NULL)` will return `NULL`.

We can now look for products containing the word "Apple"  in their `title` and `description` fields by using the already generated index on the `search` field:

```go
db.Query("SELECT title, description FROM posts WHERE search @@ plainto_tsquery('Apple')")
```

Moreover, we can set the order of the query to prioritize the fields with more weight:

```go
text := "Apple"
db.Query(`SELECT title, description 
FROM posts 
WHERE search @@ plainto_tsquery($1)
ORDER BY ts_rank(search, plainto_tsquery($1)) DESC`, text)
```

As we set a higher priority to the `title` field, the ones containing the `Apple` text in it will be at the top of the list and above the products that have it in the `description` field.

## Recursive queries

Now imagine we want to retrieve all the replies from a post and the replies to those comments as well, this scenario is proposed for **educational purposes**, ideally you will need to load one comment at a time when a user requests it. The query would be as follows:

```sql
WITH RECURSIVE replies AS (
	SELECT 
		id, user_id, content
		FROM comments WHERE parent_comment_id=$1
		-- Below we get the replies of the replies and we "append" them
		-- to our current matches (the top level ones)
		UNION
			SELECT
			c.id, c.parent_comment_id c.user_id, c.content, 
			FROM comments c
			INNER JOIN replies r ON r.id = c.parent_comment_id
) SELECT id, parent_comment_id, user_id, content FROM replies
```
> If a comment is a reply to the post and not to a comment then `parent_comment_id` will be null.

## Multiple result sets

Lastly, we will cover how to execute multiple `SELECT` queries in a single roundtrip with *results sets*. 

This is really useful in cases where the database is the system's bottleneck because it is receiving a lot of concurrent connections. Doing all the operations in a single call can hurt a program's readability, but it can also reduce the network latency and optimize the overall workflow.

As you can see below, the implementation is pretty straightforward and self-explanatory.

```go
func getPostsAndComments() error {
	rows, err := db.Query("SELECT * from posts; SELECT * from comments;")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	// Loop through the posts (first query)
	for rows.Next() {
		// Scan posts
	}

	// Advance to next result set
	// It returns a boolean indicating if there are further sets
	nextSet := rows.NextResultSet()
	if !nextSet {
		return rows.Err()
	}

	// Loop through the comments (second query)
	for rows.Next() {
		// Scan comments
	}

	// Check for any error in either result set
	return rows.Err()
}
```

## References

- [Designing Data-Intensive Applications by Martin Kleppmann](https://dataintensive.net/)
- [Controlling Text Search](https://www.postgresql.org/docs/current/textsearch-controls.html)
