use v6;
use Test;
use Apache::LogFormat::Compiler;
use IO::Blob;

my $fmt = Apache::LogFormat.combined();
if ! isa-ok($fmt, "Apache::LogFormat::Logger") {
    return
}

my $io = IO::Blob.new;
my %env = (
    HTTP_REFERER => "http://doc.perl6.org",
    HTTP_USER_AGENT => "Firefox foo blah\n",
    REMOTE_ADDR => "192.168.1.1",
    REMOTE_USER => "foo",
    REQUEST_METHOD => "GET",
    REQUEST_URI => "/foo/bar/baz",
    SERVER_PROTOCOL => "HTTP/1.0",
    'p6sgi.error' => $io,
);
my @res = (200, ["Content-Type" => "text/plain"], ["Hello, World".encode('ascii')]);
$fmt.log-line(%env, @res);
$io.seek(0, 0);
my $got = $io.slurp-rest(:enc<ascii>);

if !ok $got ~~ /^ "192.168.1.1 - foo [" \d**2\/<[A..Z]><[a..z]>**2\/\d**4\:\d**2\:\d**2\:\d**2 " " <[\+\-]>\d**4 '] "GET /foo/bar/baz HTTP/1.0" 200 - "http://doc.perl6.org" "Firefox foo blah\x0a"' /, "line matches" {
    note $got;
}
done-testing;
