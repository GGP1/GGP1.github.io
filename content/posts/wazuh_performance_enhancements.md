---
title: "Delving into Wazuh's server performance enhancements"
description: ""
date: 2025-07-27
draft: false
showToc: true
tocOpen: false
image: "/images/performance_enhancements/auth_requests.png" # image path/url
tags:
  - Python
  - Batching
  - Connection pooling
  - Caching
  - Networking
  - Scaling
  - SQL
---

In this post, we will go through real-world performance optimizations introduced to the Wazuh server [4.13.0 version](https://github.com/wazuh/wazuh/releases/tag/v4.13.0), achieving significant reductions in time and resources consumption up to **95%**!

We will explore different techniques such as connection pooling, caching, SQL query improvements, reducing time complexity, better configuration values and more.

Let's dive into each one of the issues and how we fixed them.

### Identifying bottlenecks

Diagnosing performance issues begins with a thorough review of the system architecture. 

Depending on the application's requirements, you might find yourself working on different parts of the system, but the most common critical part of a system's performance is usually the database.

In the Wazuh server, the database uses the highest transaction isolation level available (serializable) to provide better data consistency, with the trade-off of being slower to process queries due to longer lock times and increased contention between transactions.

> *Serializable* means transactions are executed synchronously, one after the other. There can't be two transaction executing at the same time.
>
> See the [Isolation levels](./mastering_sql_with_go_p2.md#isolation-levels) section of one of the previous posts for more details on transaction levels.

<div class="mb-4" align="center">
  <img align="middle" src="/images/performance_enhancements/bottleneck.jpg" height="300" width="500" alt="Bottleneck">
</div>

On top of this, the communication with the database uses the UDP protocol, which is technically faster than TCP because it does not provide data recovery mechanisms, but that suffers from a significant limitation: packet sizes can't exceed 65kB, meaning that retrieving bigger data sets requires multiple round-trips.

We will see later that this plays a big role on many of the decisions we took on how to optimize the server performance.

### Improving queries

[<i class="fa-solid fa-code-pull-request"></i> Pull request](https://github.com/wazuh/wazuh/pull/29363)

The first major issue we were facing is that the database was locked executing too much queries to perform a single operation: get the number of agents with each connection and group configuration status.

The result would be something like this

```json
{
  "connection_status": {
    "active": 15,
    "disconnected": 4,
    "never_connected": 2,
    "pending": 2
  },
  "group_config_status": {
    "synced": 20,
    "not_synced": 3
  }
}
```

And to calculate that, we were retrieving all agents and their status fields to then iterate over them and count each occurence.

```sql
SELECT id AS 'id', connection_status AS 'status', group_config_status AS 'group_config_status' FROM agent ORDER BY id ASC LIMIT <limit> OFFSET <offset>
```

`LIMIT` and `OFFSET` clauses are used to paginate over the list of agents, which the server does in chunks of 500 agents at the time. The chunk size is quite low because of the UDP limitation we mentioned earlier in [Identifying shortcomings](#identifying-shortcomings).

There were no issues noticeable in most environments, since the number of agents is typically below 500 and there is only one transaction required. However, on bigger environments with thousands of agents, it was locking the database for extended periods of time.

To overcome this, we used the `GROUP BY` SQL clause to let the much faster and efficient database engine do the counting.

```sql
SELECT connection_status AS 'status' FROM agent GROUP BY connection_status ORDER BY id ASC LIMIT 4 OFFSET 0

SELECT group_config_status AS 'group_config_status' FROM agent GROUP BY group_config_status ORDER BY id ASC LIMIT 2 OFFSET 0
```

> Limits `4` and `2` are used to prevent the database client from trying to get more items after the first transaction. Since both statuses are enumerators, we already know the number of items in advance.

After this change, the number of transactions required to obtain the information in an environment with 50,000 agents went from **102** to just **6**, a **94.1176% decrease**.

> 4 of the 6 queries are added by the database client, only two are necessary to get the data.

<details><summary>Before</summary>

```console
2025/04/24 15:43:02 wazuh-db[28844] main.c:339 at run_dealer(): DEBUG: New client connected (40).
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select count(*) from (select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent)
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select count(*) from agent order by id asc
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 0
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 1000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 1500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 2000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 2500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 3000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 3500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 4000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 4500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 5000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 5500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 6000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 6500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 7000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 7500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 8000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 8500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 9000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 9500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 10000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 10500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 11000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 11500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 12000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 12500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 13000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 13500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 14000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 14500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 15000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 15500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 16000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 16500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 17000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 17500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 18000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 18500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 19000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 19500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 20000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 20500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 21000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 21500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 22000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 22500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 23000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 23500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 24000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 24500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 25000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 25500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 26000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 26500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 27000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 27500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 28000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 28500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 29000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 29500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 30000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 30500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 31000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 31500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 32000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 32500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 33000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 33500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 34000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 34500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 35000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 35500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 36000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 36500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 37000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 37500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 38000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 38500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 39000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 39500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 40000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 40500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 41000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 41500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 42000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 42500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 43000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 43500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 44000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 44500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 45000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 45500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 46000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 46500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 47000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 47500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 48000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 48500
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 49000
2025/04/24 15:43:02 wazuh-db[28844] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sql select id as 'id',connection_status as 'status',group_config_status as 'group_config_status' from agent order by id asc limit 500 offset 49500
2025/04/24 15:43:02 wazuh-db[28844] main.c:401 at run_worker(): DEBUG: Client 40 disconnected.
```

</details>

<details><summary>After</summary>

```console
2025/04/30 16:31:28 wazuh-db[5211] main.c:352 at run_dealer(): DEBUG: New client connected (43).
2025/04/30 16:31:28 wazuh-db[5211] wdb_parser.c:940 at wdb_parse(): DEBUG: Global query: sql select count(*) from (select connection_status as 'status' from agent)
2025/04/30 16:31:28 wazuh-db[5211] wdb_parser.c:940 at wdb_parse(): DEBUG: Global query: sql select count(*) from agent order by id asc  
2025/04/30 16:31:28 wazuh-db[5211] wdb_parser.c:940 at wdb_parse(): DEBUG: Global query: sql select connection_status as 'status' from agent group by connection_status order by id asc limit 4 offset 0
2025/04/30 16:31:28 wazuh-db[5211] main.c:414 at run_worker(): DEBUG: Client 43 disconnected.
2025/04/30 16:31:28 wazuh-db[5211] main.c:352 at run_dealer(): DEBUG: New client connected (21).
2025/04/30 16:31:28 wazuh-db[5211] wdb_parser.c:940 at wdb_parse(): DEBUG: Global query: sql select count(*) from (select group_config_status as 'group_config_status' from agent)
2025/04/30 16:31:28 wazuh-db[5211] wdb_parser.c:940 at wdb_parse(): DEBUG: Global query: sql select count(*) from agent order by id asc  
2025/04/30 16:31:28 wazuh-db[5211] wdb_parser.c:940 at wdb_parse(): DEBUG: Global query: sql select group_config_status as 'group_config_status' from agent group by group_config_status order by id asc limit 2 offset 0
2025/04/30 16:31:28 wazuh-db[5211] main.c:414 at run_worker(): DEBUG: Client 21 disconnected.
```

</details>

<br>

### Unifying requests

[<i class="fa-solid fa-code-pull-request"></i> Pull request](https://github.com/wazuh/wazuh/pull/29589)

One of Wazuh's main dashboards displays widgets containing the number of agents in each group, with each operating system and connection status.

![Agent widgets](/images/performance_enhancements/widgets.png "Agent widgets")

To get this information, the dashboard plugin was performing three different requests to the API. Each request requires to be authenticated, validated and uses a different connection to the database.

The fix we applied in this case was to create an endpoint that returned all the counters together, so that the client needed just one request to render the widgets. Just like that, we saved a considerable amount of computing power and memory allocations.

### Implementing smarter caching

[<i class="fa-solid fa-code-pull-request"></i> Pull request](https://github.com/wazuh/wazuh/pull/29406)

All requests to the Wazuh API require to be authenticated, and that authentication is done using a role-based access control mechanism ([RBAC](https://documentation.wazuh.com/current/user-manual/user-administration/rbac.html)). To enforce its policies, it is essential to get the resources that will be accessed and match them against the user's permissions.

Many of these resources were cached on the scope of the request, but the cache wouldn't work for different requests accessing the same information. This was causing the server to go and read the contents of a file for every ruleset request.

Given that ruleset files do not currently (as of 4.13.0) support hot-reloading, we could just have a global cache that "freezes" the ruleset for 10 seconds. It is enough time to use the memory when we receive multiple requests in a row, but not as much in case they are modified by the user and requested again.

Introducing a simple TTL in-memory cache saved us many unnecessary system calls.

### Reducing time complexity

![Time complexity](/images/performance_enhancements/time_complexity.jpeg "Time complexity")

[<i class="fa-solid fa-code-pull-request"></i> Pull request](https://github.com/wazuh/wazuh/pull/30931)

The endpoint `PUT /agents/restart` was causing timeouts and our performance tests to fail due to a critical logic mistake in its controller function.

The main issue lied in the [following line](https://github.com/wazuh/wazuh/pull/30931/files#diff-8a6dae46350a78b58703fdd662abc0544b50294a50755a8931c6a3ec8ac0cd69L266), which calculates a list of agents to restart. Only active agents are added to the list, since we can't restart disconnected or pending ones.

```py
# agents: array containing all agents
# non_active_agents: array containing agents whose status is not 'active'
eligible_agents = [agent for agent in agents if agent not in non_active_agents] if non_active_agents else agents
```

If all agents are disconnected this has a time complexity of **O(n²)** and, in an environment with 50,000 agents, it would take **27 seconds** to complete (even though no actual restart took place, because no agent was active).

In contrast, after the changes, the same scenario has a time complexity of **O(n)** and takes **600 milliseconds**, a **97.7778% decrease**!

This drastic difference is exacerbated by the fact that all of them are inactive, but in real environments, specially those who have sporadic agents (that is, they spawn agents to perform certain tasks and then kill them), this was causing response times to sky rocket due to a very simple operation.

The solution to this problem was to iterate over the list of agents once and building the inactive, eligible and not_found lists in the same for loop.

```py
for agent_id in agent_list:
  if agent_id not in system_agents:
      result.add_failed_item(id_=agent_id, error=WazuhResourceNotFound(1701))
      continue

  if agent_id not in active_agents:
      result.add_failed_item(id_=agent_id, error=WazuhError(1707))
      continue
      
  try:
      send_restart_command(agent_id, active_agents[agent_id], wq)
      result.affected_items.append(agent_id)
  except WazuhException as e:
      result.add_failed_item(id_=agent_id, error=e)
```

> The pull request also introduces changes to the database query to filter by status to get only the active agents instead of all of them, the eligible list is known by elimination.

<details><summary>Before</summary>

```console
2025/07/17 08:43:54 INFO: wazuh 172.18.0.1 "PUT /agents/restart" with parameters {} and body {} done in 27.334s: 200
```

</details>

<details><summary>After</summary>

```console
2025/07/17 09:32:30 INFO: wazuh 172.18.0.1 "PUT /agents/restart" with parameters {} and body {} done in 0.614s: 200
```

</details>

<br>

### Avoiding the bottleneck

[<i class="fa-solid fa-code-pull-request"></i> Pull request](https://github.com/wazuh/wazuh/pull/29363)

As we have previously mentioned in [Identifying shortcomings](#identifying-shortcomings), the communication with the database uses the UDP protocol which has a maximum packet size of 65kB. 

This forces the communication of bigger data sets to be splitted into several smaller ones. While this is great to keep memory consumption low, the amount of roundtrips required to access information in big environments is not efficient at all time-wise.

For instance, with 50,000 agents the database is making 20 queries with different offsets to retrieve all the data.

To overcome this limitation, what we did is to get them from a different source, the `client.keys` file, which contains a log-structured list of agents IDs, their names and keys.

This approach is much faster and requires a single system call, with the trade-off of loading all the information to memory at once. However, given that we are talking about IDs which are 1-2 bytes long, this isn't really an issue.

Finally, there is one more relevant change we did in this pull request, and that was that the query was getting all agents IDs and their groups, even though the groups weren't used. So we fixed that as well.

<details><summary>Before</summary>

```console
2025/04/23 20:24:56 wazuh-db[117264] main.c:339 at run_dealer(): DEBUG: New client connected (40).
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":0, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":2754, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":5462, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":8170, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":10843, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":13443, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":16043, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":18643, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":21243, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":23843, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":26443, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":29043, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":31643, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":34243, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":36843, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":39443, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":42043, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":44643, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":47243, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] wdb_parser.c:859 at wdb_parse(): DEBUG: Global query: sync-agent-groups-get {"last_id":49843, "condition":"all"}
2025/04/23 20:24:56 wazuh-db[117264] main.c:401 at run_worker(): DEBUG: Client 40 disconnected.
```

</details>

<details><summary>After</summary>

```console
Single system call to the file `/var/ossec/etc/client.keys`
```

</details>

<br>

### Database communication overhaul

[<i class="fa-solid fa-code-pull-request"></i> Pull request](https://github.com/wazuh/wazuh/pull/29515)

Many of the previous performance enhancements have been related to the communication protocol used. As we have seen, it's decent for most environments, but struggles a lot on bigger ones.

Because of this, we have partially replaced it with an HTTP over unix socket server that uses TCP under the hood and has no worrying size limitations.

The implementation is really simple and straightforward, and provides a less limited way of accessing the information. It has no pagination at the moment, but given that it works on prepared statements with limited information, this is not a concern.

### Scaling authentication requests

[<i class="fa-solid fa-code-pull-request"></i> Pull request](https://github.com/wazuh/wazuh/pull/28653)

Moving on to an issue affecting the whole cluster, we were receiving reports that authentication requests were taking too long and timing out, effectively rendering the API unusable.

The Wazuh cluster is reliant on the master node and has no alternative leader election in place. The master node holds the most updated state of the system and synchronizes it with the rest of the worker nodes.

Because of this, many requests that are handled by worker nodes are distributed to the master node, which is the only one capable of answering them, because we don't know for certain that the worker node has the latest state.

Authentication requests is one example, even if you have a cluster of 25 nodes, it will all come down to how fast the master node can handle the requests.

Prior to this change, the master node was using a pool with only one process to handle all authentication-related requests. This was causing delays all over the cluster because the node couldn't keep up with all the work it was assigned.

These were the response times of the authentication request in a cluster with 3 workers receiving 5 requests per second during one minute.

![1 worker, 1 connection per session](/images/performance_enhancements/one_session.png "1 worker, 1 connection per session")

To improve this, we have made configurable the number of processes dedicated to handling authentication requests and we have increased the default value to 2. That means, it can now handle requests 2x faster because it can parallelize the work.

![10 workers, 1 connection per session](/images/performance_enhancements/10_processes.png "10 processes, 1 connection per session")

> Note the y axis values. Bigger environments would probably benefit more if they increase it even more to 5 processes, but beyond that it's diminishing returns.

### Connection pooling

[<i class="fa-solid fa-code-pull-request"></i> Pull request](https://github.com/wazuh/wazuh/pull/28653)

Another issue related to authentication requests was that they were creating a new database session for every request, instead of creating a connection pool and re-utilizing those connections.

After identifying the issue, we proceeded to fix it by creating a pool of 10 connection to the RBAC database on startup and then use available connections on every session.

![1 process, 10 connections per session](/images/performance_enhancements/pool.png "1 process, 10 connections per session")

> We can observe that at the start connections are being created and response times are quite high. After that, we are just re-using existing ones and the performance is much better.

These two last changes alone

1. [Authentication processes increase](#scaling-authentication-requests)
2. [Database connection pooling](#connection-pooling)

have reduced the time taken to authenticate requests from an average of **~15 seconds** to just **700 milliseconds** (**95.3333% decrease**).

![Authentication requests performance](/images/performance_enhancements/auth_requests.png "Authentication requests performance")

## Conclusion

These changes mark a significant leap forward in Wazuh's performance, each addressing specific areas critical to system efficiency. 

From optimizing database queries and streamlining dashboard data retrieval to implementing efficient caching mechanisms and improving agent restart operations, these changes collectively contribute to a more responsive and reliable server.

The benefits of these improvements are tangible, leading to cooler servers and lower operational costs on tens of thousands of machines running the software across the world.

![API endpoints improvements](/images/performance_enhancements/api_endpoints.png "API endpoints improvements")

If your instance runs quieter or your bill has seen a reduction since this version, you're welcome 😉.
