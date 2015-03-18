deriving a master word list from Google Books
---------------------------------------------
[201503] (air)

develop a list of plausible words, as defined by Google Books corpus.

./processGBooks.pl <corpus-file-stub> <letter>
tabulates words for a given letter:

.skipped  - filter out entries that fail [[:graph:]] (like cyrillic, etc)
.word_*   - collapses across years (all)
.base_*   - collapses across POS tags (.base)
.annotations - all POS-like tags
.log      - major category counts

- for convenience generate lists with 10,000 and 1,000 count cutoffs.

to do
-----

1. generate according to date range (say, since 1945)
2. generate POS distributions for common words; relate to cmudict entries



---
