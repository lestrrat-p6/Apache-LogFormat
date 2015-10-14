[![Build Status](https://travis-ci.org/lestrrat/p6-Apache-LogFormat-Compiler.svg?branch=master)](https://travis-ci.org/lestrrat/p6-Apache-LogFormat-Compiler)

NAME
====

Apache::LogFormat::Compiler - blah blah blah

SYNOPSIS
========

    # Use a predefined log format to generate string for logging
    use Apache::LogFormat;
    my $fmt = Apache::LogFormat.combined;
    my $line = $fmt.format(%env, @res, $length, $reqtime, $time);
    $*ERR.print($line);

    # Compile your own log formatter
    use Apache::LogFormat::Compiler;
    my $c = Apache::LogFormat::Compiler.new;
    my $fmt = $c.compile(' ... pattern ... ');
    my $line = $fmt.format(%env, @res, $length, $reqtime, $time);
    $*ERR.print($line);

DESCRIPTION
===========

Apache::LogFormat::Compiler is ...

AUTHOR
======

Daisuke Maki <lestrrat@gmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2015 Daisuke Maki

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
