use v6;

unit class Apache::LogFormat::Compiler;
use Apache::LogFormat::Formatter;

use DateTime::Format;

has %.char-handlers = (
    '%' => q!'%'!,
    b => q|(defined($length)??$length!!'-')|,
    D => q|($reqtime.defined ?? $reqtime.Int !! '-'|,
    h => q!(%env<REMOTE_ADDR> || '-')!,
    H => q!%env<SERVER_PROTOCOL>!,
    l => q!'-'!,
    m => q!safe-value(%env<REQUEST_METHOD>)!,
    p => q!%env<SERVER_PORT>!,
    P => q!$$!,
    q => q|(%env<QUERY_STRING> ?? '?' ~ safe-value(%env<QUERY_STRING>) !! '')|,
    r => q!safe-value(%env<REQUEST_METHOD>) ~ " " ~ safe-value(%env<REQUEST_URI>) ~ " " ~ %env<SERVER_PROTOCOL>!,
    s => q!@res[0]!,
    t => q!'[' ~ format-datetime($time) ~ ']'!,
    T => q|($reqtime.defined ?? $reqtime.Int.truncate * 1_000_000 !! '-'|,
    u => q!(%env<REMOTE_USER> || '-')!,
    U => q!safe-value(%env<PATH_INFO>)!,
    v => q!(%env<SERVER_NAME> || '-')!,
    V => q!(%env<HTTP_HOST> || %env<SERVER_NAME> || '-')!,
);

has %.block-handlers;

# [10/Oct/2000:13:55:36 -0700]
my sub format-datetime(DateTime $dt) {
    state @abbr = <Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec>;

    return sprintf("%02d/%s/%04d:%02d:%02d:%02d %s%02d%02d",
        $dt.day-of-month, @abbr[$dt.month-1], $dt.year,
        $dt.hour, $dt.minute, $dt.second, ($dt.offset>0??'+'!!'-'), $dt.offset/3600, $dt.offset%3600);
}

our sub safe-value($s) {
    if !defined($s) {
        return '';
    }

    my $x = $s.Str;
    $x ~~ s:g/(<:C>)/{ "\\x" ~ Blob.new(ord($0)).unpack("H*") }/;
    return $x;
}

our sub string-value($s) {
    if !$s {
        return '-'
    }

    my $x = $s.Str;
    $x ~~ s:g/(<:C>)/{ "\\x" ~ Blob.new(ord($0)).unpack("H*") }/;
    return $x;
}

our sub get-header(@hdrs, $key) {
    my $lkey = $key.lc;
    my @copy = @hdrs;
    for @hdrs -> $pair {
        if $pair.key.lc eq $lkey {
            return $pair.value;
        }
    }
    return;
}

method run-block-handler($block, $type, %extra-blocks) {
    state %psgi-reserved = (
        CONTENT_LENGTH => 1,
        CONTENT_TYPE => 1,
    );
    my $cb;
    given $type {
        when 'i' {
            $cb = $block;
            $cb ~~ s:g/\-/_/;
            my $hdr-name = $cb.uc;
            if !%psgi-reserved{$hdr-name} {
                $hdr-name = "HTTP_" ~ $hdr-name;
            }
            $cb = q!string-value(%env<! ~ $hdr-name ~ q!>)!;
        }
        when 'o' {
            $cb = q!string-value(get-header(@res[1], '! ~ $block ~ q!'))!;
        }
        when 't' {
            $cb = q!"[" ~ strftime('! ~ $block ~ q!', $time) ~ "]"!;
        }
        when %extra-blocks{$type}:exists {
            $cb = q!string-value(%extra-blocks{'! ~ $type ~ q!'}('! ~ $block ~ q!', %env, @res, $length, $reqtime))!;
        }
        default {
            die "{$block}$type not supported";
        }
    }
    return q|! ~ | ~ $cb ~ q| ~ q!|;
}

method run-char-handler(Str $char, %extra) {
    my $cb;

    if %.char-handlers{$char}:exists {
        $cb = %.char-handlers{$char};
    } elsif %extra{$char}:exists {
        $cb = q!(%extra-chars{'! ~ $char ~ q!'}(%env, @res))!;
    }

    if !$cb {
        die "char handler for '$char' undefined";
    }
    return q|! ~ | ~ $cb ~ q|
      ~ q!|;
}

method compile(Apache::LogFormat::Compiler:D: $pat, %extra-blocks?, %extra-chars?) {
    my $fmt = $pat; # copy so we can safely modify

    $fmt ~~ s:g/'!'/'\''!'/;
    $fmt ~~ s:g!
        [
             \%\{ $<name>=.+? \} $<type>=<[ a..z A..Z ]>|
             \%<[\<\>]>? $<char>=<[ a..z A..Z \%]>
        ]
    !{ $<name> ??
        self.run-block-handler($<name>, $<type>, %extra-blocks) !!
        self.run-char-handler($<char>.Str, %extra-chars)
    }!;


    $fmt = q~sub (%env, @res, $length, $reqtime, DateTime $time = DateTime.now) {
        q!~ ~ $fmt ~ q~!;
    }~;

    my $code = EVAL($fmt);
    return Apache::LogFormat::Formatter.new($code);
}

=begin pod

=head1 NAME

Apache::LogFormat::Compiler - Compiles Log Format Into Apache::LogFormat::Formatter

=head1 SYNOPSIS

  use Apache::LogFormat::Compiler;
  my $c = Apache::LogFormat::Compiler.new;
  my $fmt = $c.compile(' ... pattern ... ');
  my $line = $fmt.format(%env, @res, $length, $reqtime, $time);
  $*ERR.print($line);

=head1 DESCRIPTION

Apache::LogFormat::Compiler compiles an Apache-style log format string into
efficient perl6 code. It was originally written for perl5 by kazeburo.

=head1 METHODS

=head2 new(): $compiler:Apache::LogFormat::Compiler

Creates a new parser. The parser is stateless, so you can reuse it as many
times to compile log patterns.

=head2 compile($pat:String, %extra-block-handlers:Hash(Str,Callable), %extra-char-handlers:Hash(Str,Callable)) $fmt:Apache::LogFormat::Formatter

Compiles the pattern into an executable formatter object.

=head1 AUTHOR

Daisuke Maki <lestrrat@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Daisuke Maki

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
