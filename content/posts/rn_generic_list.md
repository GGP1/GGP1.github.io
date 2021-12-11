---
title: "React Native generic list"
date: 2021-12-11
draft: false
cover:
    image: "/images/rn_list.png"
    alt: "React Native List example" # alt text
    caption: "" # display caption under cover
    relative: false # when using page bundles set this to true
    hidden: false # only hide on current single pag
---

React Native's *FlatList* is a component that supports many cool features while being simple and easy to use, it's a good example of a well-designed piece of software and that's why I decided to take it a step further.

For that, I've developed a generic list built on top of it that handles **pagination** and **refreshing** internally, reducing a *lot* of repetitive code from my previous implementation.

I looked for something like this online but couldn't find anything similar, even though it might be useful for many people, so I decided to share it. 

Here's the snippet with the entire code, let's take a brief look and review it in detail later:

```tsx
import React, { useCallback, useEffect, useState } from "react";
import { FlatList, FlatListProps } from "react-native";

interface ID {
	id: string
}

type FLProps<T> = Omit<
	FlatListProps<T>, 
	"data" | "keyExtractor" | "onEndReached" | "onRefresh" | "refreshing"
>

interface Props<T> extends FLProps<T> {
	fetchItems: (cursor?: string) => Promise<[string, T[]]>
}

export const List = <T extends ID>(props: Props<T>) => {
	const [items, setItems] = useState<readonly T[]>();
	const [cursor, setCursor] = useState<string>();
	const [refreshing, setRefreshing] = useState<boolean>(false);

	const getItems = useCallback(async () => {
		try {
			const [nextCursor, elems] = await props.fetchItems(cursor);
			setCursor(nextCursor);
			items ? setItems(items.concat(elems)) : setItems(elems);
		} catch (err) {
			console.log(err);
		} finally {
			setRefreshing(false);
		}
	}, []);

	useEffect(() => {
		getItems();
	}, []);

	return (
		<FlatList
			data={items}
			keyExtractor={item => item.id}
			onEndReached={({ distanceFromEnd }) => {
				distanceFromEnd < 0 ? undefined : getItems();
			}}
			onEndReachedThreshold={
				props.onEndReachedThreshold ? props.onEndReachedThreshold : 0.1
			}
			refreshing={refreshing}
			onRefresh={() => {
				setRefreshing(true);
				setCursor(undefined);
				setItems(undefined);
				getItems();
			}}
			{...props}
		/>
	);
};
```

### `List` in action

```tsx
import { List } from "./List"

type User = {
  id: string,
  username: string
}

export const UserList = () => {
	const getUsers = async (cursor?: string): Promise<[string, User[]]> => {
		const response = await fetch(`localhost:4000/users?cursor=${cursor}`);
		// In this example, the response body contains a JSON object with 
		// the next cursor and an array of users
		const json = await response.json() as {next_cursor: string, users: User[]};
		return [json.next_cursor, json.users];
	}

	return (
		<List<User>
			fetchItems={(cursor) => getUsers(cursor)}
			renderItem={({ item }) => <View><Text>{item.username}</Text></View>}
			numColumns={2}
			// More properties from FlatList may be included here
		/>
	);
}
```

As you can see, it's extremely easy to use and requires few lines of code to have it working. 

> Note two things, `<User>` makes explicit the type of items the list will contain and 
> `next_cursor` must always return a non-null value, if not, the request will return duplicated items.
 
## Component breakdown

### Properties

```tsx
interface ID {
	id: string
}

type FLProps<T> = Omit<
	FlatListProps<T>, 
	"data" | "keyExtractor" | "onEndReached" | "onRefresh" | "refreshing"
>

interface Props<T> extends FLProps<T> {
	fetchItems: (cursor?: string) => Promise<[string, T[]]>
}

export const List = <T extends ID>(props: Props<T>) => {}
```

The `ID` interface is used for the generic to accept only items that has and id field in it, which is used to extract a unique key from each of them.

`FLProps` contains all the properties of a `FlatList` except the ones that are specified with literal strings, preventing the caller from overwriting the properties that are automatically handled by the component.

> In my case I was always using the types' id field to uniquely identify items inside the list but if it's not your case, `keyExtractor` can be delegated.

Lastly, the component's properties are all of `FLProps` plus `fetchItems`, the callback from which the list will be populated. 

### State

```tsx
const [items, setItems] = useState<readonly T[]>();
const [cursor, setCursor] = useState<string>();
const [refreshing, setRefreshing] = useState<boolean>(false);
```

- `items` holds the elements list, it's set to read-only as the items themselves won't be modified. Always try to type as much as possible.
- `cursor` contains the id of the element used to tell the server the starting point for a new list of elements.
- `refreshing` stores a boolean that tells whether the list is waiting for more values or not.

### Get items callback

```tsx
const getItems = useCallback(async () => {
	try {
		const [nextCursor, elems] = await props.fetchItems(cursor);
		setCursor(nextCursor);
		items ? setItems(items.concat(elems)) : setItems(elems);
	} catch (err) {
		console.log(err);
	} finally {
		setRefreshing(false);
	}
}, []);
```

Here's where most of the list's work is done, we fetch items from a source - tipically an HTTP request to a server - using a cursor (initially undefined), so we will never get a duplicated item. 

> `useCallback` returns a memoized version of the callback that changes only when one of its dependencies has changed. 
>
> In this case it has none to execute the callback only when we explicity specify it and to prevent unnecessary renders from `useEffect`.

The received cursor is stored for use in following calls and, if there are already stored items, the ones from the next request are appended to them. 

Any potential error is catched and logged into the console.

Finally, `refreshing` is set to false to tell the list that we are done getting new values.

### Use effect hook

```tsx
useEffect(() => {
	getItems();
}, []);
```

`useEffect` runs once and gets the items that the list will contain when the component is mounted, the cursor will always be undefined.

### Pagination

```tsx
<_
	onEndReached={({ distanceFromEnd }) => {
		distanceFromEnd < 0 ? undefined : getItems();
	}}
	onEndReachedThreshold={
		props.onEndReachedThreshold ? props.onEndReachedThreshold : 0.1
	}
/>
```

`onEndReached` is the callback that will be called whenever the user reaches the end of the list, in this case it will request more items to the server, using the cursor to specify the last item of the latest response.

There are some scenarios when the list is first rendered but it has so few items that it triggers the `onEndReached` callback, forcing another render. 

In order to avoid this, `distanceFromEnd` (always negative on the first render) is set to undefined in those cases.

### Refreshing

```tsx
<_ 
	refreshing={refreshing}
	onRefresh={() => {
		setRefreshing(true);
		setCursor(undefined);
		setItems(undefined);
		getItems();
	}}
/>
```

Each time the list is pulled the `onRefresh` callback is triggered. 

In it, the list is set to its refreshing state, the component's state is reset and new items are requested. It's like simulating the component's first render.

### Potential enhancements

This is a simplified version of the List component I use so there are things that may be missing for your implementation. 

One kind of obvious is the possibility that `fetchItems` returns undefined data. 

Some others may be:

- Passing more parameters to the fetch items callback.
- Set a limit to the amount of items that can be stored.
- Use a reference to a boolean value to avoid requesting items on an unmounted list.

Extending its utility it's up to your imagination and I hope this post has inspired you to create useful generic components.