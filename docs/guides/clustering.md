# Clustering

MyNews uses SimHash fingerprinting to deduplicate articles and detect recurring topics.

## SimHash Deduplication

SimHash generates a 64-bit fingerprint from article text. Articles with fingerprints within a configurable hamming distance are grouped into clusters.

<div class="cluster-flow">
  <div class="node bg-fetch">Article text</div>
  <span class="arrow">&#x25B6;</span>
  <div class="node bg-normalize">Compute SimHash</div>
  <span class="arrow">&#x25B6;</span>
  <div class="node bg-summarize">Compare hamming distance</div>
  <span class="arrow">&#x25B6;</span>
  <div class="diamond bg-cluster">Distance &lt; threshold?</div>
  <div class="branch">
    <div class="branch-row">
      <span class="branch-label" style="color:#2E7D32;">Yes &#x25B6;</span>
      <span class="outcome bg-normalize">Same cluster</span>
    </div>
    <div class="branch-row">
      <span class="branch-label" style="color:#C62828;">No &#x25B6;</span>
      <span class="outcome bg-publish">New cluster</span>
    </div>
  </div>
</div>

### How SimHash Works

1. Tokenize the article text into words
2. Hash each word to a 64-bit value
3. For each bit position, sum +1 (if bit is 1) or -1 (if bit is 0) across all word hashes
4. The final fingerprint has bit N set to 1 if the sum at position N is positive

Two articles are considered duplicates if their SimHash fingerprints differ in fewer than ~3 bit positions (hamming distance).

## Recurring Topic Detection

After clustering, the recurrence detector compares today's clusters against articles from the last 3 days. Topics that appear across multiple days are flagged as `is_recurring = true`.

Recurring topics are placed at the end of published bulletins.

## Running

```bash
my_news cluster
```

This runs both deduplication and recurrence detection.
