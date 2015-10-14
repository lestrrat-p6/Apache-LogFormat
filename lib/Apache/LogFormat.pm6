use v6;

unit class Apache::LogFormat;
use Apache::LogFormat::Compiler;

method common(Apache::LogFormat:U: :$logger) {
    my $p = Apache::LogFormat::Compiler.new();
    return $p.compile('%h %l %u %t "%r" %>s %b');
}

method combined(Apache::LogFormat:U: :$logger) {
    my $p = Apache::LogFormat::Compiler.new();
    return $p.compile('%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"');
}

=begin pod

=head1 NAME

Apache::LogFormat - Provide Apache-Style Log Generators

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Apache::LogFormat provides Apache-style log generators.

=head1 PRE DEFINED FORMATTERS

=head2 common(): $fmt:Apache::LogFormat::Formatter

Creates a new Apache::LogFormat::Formatter that generates log lines in
the following format:

    %h %l %u %t "%r" %>s %b

=head2 combined(): $fmt:Apache::LogFormat::Formatter

Creates a new Apache::LogFormat::Formatter that generates log lines in
the following format:

    %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"

=head1 AUTHOR

Daisuke Maki <lestrrat@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Daisuke Maki

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

