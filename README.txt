cmudict refub project
---------------------
[20130331] (air)

Starts with a version that was modified during the setup of the Google
AI AMT verification project.

Some changes will be made before the AMT data is vetted and folded
in. Specifically, the dict was run through Sequitur and deletion errors
were examined; for the most part these are mistakes in the dict and
would not need AMT verification; on the other hand it performs a
redundant check. Still...


[201412] (air)

Major refurb, part the 2.
I.
1. Start incorporating Nickolay words
2. Harvest lmtool LtoS invocations
3. Add color to reduced vowels (which are mostly AH0)
4. weed out variants, especially AH0/IH0. (really a part of 3.)

II.
Bring the sequitur g2p testing stage back. Generalize testing setup for better throughput.
- doing this on an i7 octo is too slow
    - revise on aspen/birch to be able to run ||lel experiments

