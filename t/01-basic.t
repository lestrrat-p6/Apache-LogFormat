use v6;
use Test;
use Apache::LogFormat::Compiler;
use IO::Blob;

my $f = Apache::LogFormat::Compiler.new();
my $fmt = $f.compile('%r %t "%{User-agent}i"');
if ! ok($fmt, "f is valid") {
    return
}

if ! isa-ok($fmt, "Apache::LogFormat::Logger") {
    return
}

my $io = IO::Blob.new;
my %env = (
    HTTP_USER_AGENT => "Firefox foo blah\n",
    REQUEST_METHOD => "GET",
    REQUEST_URI => "/foo/bar/baz",
    SERVER_PROTOCOL => "HTTP/1.0",
    'p6sgi.error' => $io,
);
$fmt.log-line(%env);
$io.seek(0, 0);
my $got = $io.slurp-rest(:enc<ascii>);

if ! ok($got ~~ m!'GET /foo/bar/baz HTTP/1.0'!, "Checking %r") {
    note $got;
    return;
}

if ! ok($got ~~ m!\[\d**2\/<[A..Z]><[a..z]>**2\/\d**4\:\d**2\:\d**2\:\d**2 " " <[\+\-]>\d**4\]!, "checking %t") {
    note $got;
    return;
}

if ! ok($got ~~ /'"Firefox foo blah\\x0a"'/, "line is as expected") {
    note $got;
    return;
}

done-testing;
