candidate new entries
---------------------
[20150115] (air)

Workspace for possible additions to the dictionary.

Sources include:
- emails from users
- scarape of tool logs (cmudict, lextool, lmtool)

missing.*    -- scrape from lmtool
Schmirev.*   -- new words from new-cmudict
Yao*         -- extensions by a user
log-analysis -- scrape from cmudict

new entries will also be created ad hoc, if there;s an obvious missing
item noted while doing candidate insert or corrections. Often these
are inflected forms (e.g. 'race' -> 'racing').


cmudict log processing
----------------------
1. get log: dict-access_log [currently in .../apache2/www-htdocs/cmudict/]
2. use cmudict-log/parse_log.pl to get actual oovs (have '?' in response).
3. run comb_lmtool.sh to get the true oov's (use 'scrub' in find_aspell.pl)
4. use dict_diff.pl to make sure you have the 'real' oov's
5. Do manual updates

lmtool log processing
---------------------
0. work is currently in /home/air/cmudict/
1. run find_oov.pl over a raw pronounce log file
3. run comb_lmtool.sh to get the true oov's (use 'scrub' flag in find_aspell.pl)
4. use dict_diff.pl to make sure you have the 'real' oov's
5. Do manual updates


manual updating
---------------
1. open .oov and cmudict files
2. for each .oov word, figure out pronunciation and insert it
3. it helps to prepend a \t to each word you've done
4. while you're some corner or other of the dict, fix other problems
5. when done, run diff_dict.pl  again; fix errors, replace .oov file
6. Find additional errors when you run the main *_test.pl scripts



