# There is no performance difference between ' and " in PHP

There seems to be a widespread misconception in the PHP community about the performance characteristics of single quotes vs. double quotes in string literals.

I always thought this meme has long since been proven codswallop, but today I ran into a guy in ##php who was convinced there was a significant difference.

There is no *significant* difference between `'` and `"` in PHP — at least none you should worry about. If you're using APC (or any other bytecode cache) then there is **no difference at all**. None. Nil. Zilch.

If you aren't using a bytecode cache, the **only** penalty you pay is during parsing. Even then, the penalty is so negligible that there's no need to waste energy thinking about it.

If you *are* using a bytecode cache however, it might please you to know that there is no performance difference whatsoever. Consider this PHP script:

    \php
    <?php
    
    $z = "hello world";
    
    $z = 'hello world';

Analyzing it with the [Vulcan Logic Dumper](http://derickrethans.nl/projects.html#vld) — a handy PHP extension that lets you inspect the bytecode for a script — shows that the PHP parser emits the following instructions:

    \text
    compiled vars:  !0 = $z
    line     # *  op                  fetch       ext  return  operands
    ---------------------------------------------------------------------
       3     0  >   ASSIGN                                       !0, 'hello+world'
       5     1      ASSIGN                                       !0, 'hello+world'
       6     2    > RETURN                                       1

It's clear from this disassembly that PHP generates the **exact** same bytecode no matter whether you use single quotes or double quotes.

So please stop spouting this crap.