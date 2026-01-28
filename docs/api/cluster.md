# Cluster API

`lib/my_news/cluster/`

## Simhash

`MyNews::Cluster::Simhash`

Computes 64-bit SimHash fingerprints from text content. Used for near-duplicate detection.

```ruby
fingerprint = MyNews::Cluster::Simhash.compute("article text here")
# => Integer (64-bit)
```

## Deduplicator

`MyNews::Cluster::Deduplicator`

Groups articles by SimHash hamming distance and assigns `cluster_id` values.

```ruby
MyNews::Cluster::Deduplicator.new.call
```

## Recurrence

`MyNews::Cluster::Recurrence`

Detects topics that recur across multiple days by comparing today's clusters against the last 3 days.

```ruby
MyNews::Cluster::Recurrence.new.call
```

Sets `is_recurring = true` on matching articles.
