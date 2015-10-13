use v6;
use Test;
use Apache::LogFormat::Compiler;
use IO::Blob;

my $f = Apache::LogFormat::Compiler.new();
my $fmt = $f.compile('"%{User-agent}i"');
if ! ok($fmt, "f is valid") {
    return
}

if ! isa-ok($fmt, "Apache::LogFormat::Logger") {
    return
}

my $io = IO::Blob.new;
my %env = (
    HTTP_USER_AGENT => "Firefox foo blah\n",
    'p6sgi.error' => $io,
);
$fmt.log-line(%env);
$io.seek(0, 0);
my $got = $io.slurp-rest(:enc<ascii>);
if ! ok($got ~~ m/'"Firefox foo blah\\x0a"'/, "line is as expected") {
    note $got;
}

done-testing;
