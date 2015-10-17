use v6;
use Test;
use Apache::LogFormat::Compiler;

my $f = Apache::LogFormat::Compiler.new();
my $fmt = $f.compile('%r %t "%{User-agent}i"');
if ! ok($fmt, "f is valid") {
    return
}

if ! isa-ok($fmt, "Apache::LogFormat::Formatter") {
    return
}

my %env = (
    HTTP_USER_AGENT => "Firefox foo blah\n",
    REQUEST_METHOD => "GET",
    REQUEST_URI => "/foo/bar/baz",
    SERVER_PROTOCOL => "HTTP/1.0",
);
my @res = (200, ["Content-Type" => "text/plain"], ["Hello, World".encode('ascii')]);
my $now = DateTime.now;

sub mk_format($tz?) {
    $fmt.format(%env, @res, 10, Duration.new(1), $tz.defined ?? $now.in-timezone($tz) !! $now);
}

my $got = mk_format;

if ! ok($got ~~ m!'GET /foo/bar/baz HTTP/1.0'!, "Checking %r") {
    note $got;
    return;
}

sub check_fmt_t($got, :$tz) {
    my $tag = $tz.defined ?? " - $tz" !! '';
    ok $got ~~ m!\[\d**2\/<[A..Z]><[a..z]>**2\/\d**4\:\d**2\:\d**2\:\d**2 " " <[\+\-]>\d**4\]!, "checking %t$tag";
}

# Check with system timezone
if ! check_fmt_t($got) {
    note $got;
    return;
}

# Check with various timezones
for -21600, 32400, 0 -> $tz {
    my $got2 = mk_format $tz;
    if ! check_fmt_t($got2, :$tz) {
        note $got2;
        return;
    }
}

if ! ok($got ~~ /'"Firefox foo blah\\x0a"'/, "line is as expected") {
    note $got;
    return;
}

done-testing;
