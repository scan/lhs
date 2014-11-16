Collection
===

A collection is a special type of data that contains multiple items.

In general you can use any method that you also could call on an array (like count, [0], first etc.).

## Total

`total` provides total amount of items (even if paginated).

## Limit

`limit` provides amount of items per page.

## Offset

`offset` provides how many items where skipped to start the current page.

## Offset / Limit / Pagination

You can paginate by passing offset, and limit params. They will be forwarded to the backend.

```
data = Feedback.where(limit: 50) #<LHS::Data @_proxy_=#<LHS::Collection>>
data.count // 50
Feedback.where(limit: 50, offset: 51) #<LHS::Data @_proxy_=#<LHS::Collection>>
```