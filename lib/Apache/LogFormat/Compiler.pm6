use v6;

class Apache::LogFormat::Logger{

has Callable $.callback;
has Callable $.logger;

method new-with-logger($logger, $callback) {
    return self.bless(:$logger, :$callback);
}

method new($callback) {
    return self.new-with-logger(Nil, $callback);
}

method log-line(Apache::LogFormat::Logger:D: %env) {
    my $logger = $.logger;
    if !$logger {
        $logger = sub ($m) {
            %env<p6sgi.error>.print($m)
        };
    }

    if !%env<p6sgi.error> {
        %env<p6sgi.error> = $*ERR;
    }

    # TODO: provide proper parameters to callback
    $logger.($.callback.(%env, Nil, Nil, Nil, Nil));
}

}

class Apache::LogFormat::Compiler {

has %.char_handlers = (
    '%' => q!'%'!,
    h => q!(%env<REMOTE_ADDR> || '-')!,
    l => q!'-'!,
    u => q!(%env<REMOTE_USER> || '-')!,
    t => q!'[' ~ $t ~ ']'!,
    r => q!safe-value(%env<REQUEST_METHOD>) ~ " " ~ safe-value(%env<REQUEST_URI> ~ " " ~ %env<SERVER_PROTOCOL>!,
    s => q!!,
);

has %.block_handlers;

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

method run_block_handler($block, $type, $extra) {
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
        default {
            die "oops"
        }
    }
    return q|! ~ | ~ $cb ~ q| ~ q!|;
}

method run_char_handler($char, $extra) {
    my $cb = %.char_handlers<$char>;
    if !$cb {
        die "$char undefined";
    }
    return q|! ~ | ~ $cb ~ q|
      ~ q!|;
}

method compile (Apache::LogFormat::Compiler:D: $pat) {
    my $fmt = $pat; # copy so we can safely modify

    $fmt ~~ s:g/'!'/'\''!'/;
    $fmt ~~ s:g!
        [
             \%\{(.+?)\}(<[ a..z A..Z ]>)|
             \%<[\<\>]>?(<[ a..z A..Z \%]>)
        ]
    !{ $0 ?? self.run_block_handler($0, $1, Nil) !! self.run_char_handler($2, $3) }!;


    $fmt = q~sub (%env, $res, $length, $reqtime, $time) { q!~ ~ $fmt ~ q~! }~;
    my $code = EVAL($fmt);
    return Apache::LogFormat::Logger.new($code)
}

}


=begin pod

=head1 NAME

Apache::LogFormat::Compiler - blah blah blah

=head1 SYNOPSIS

  use Apache::LogFormat::Compiler;

=head1 DESCRIPTION

Apache::LogFormat::Compiler is ...

=head1 AUTHOR

Daisuke Maki <lestrrat@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Daisuke Maki

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
