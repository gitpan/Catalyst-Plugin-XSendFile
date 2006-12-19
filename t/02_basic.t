#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use Test::Base;
use Catalyst::Test 'TestApp';
use File::Temp qw/tempdir/;

plan tests => 8;

TestApp->config->{sendfile}{tempdir} = tempdir( CLEANUP => 1 );
TestApp->setup;

my $image_fn = 'cpan.jpg';
my $image    = File::Spec->catfile( $FindBin::Bin, qw/lib TestApp root/, 'cpan.jpg' );

# sendfile: normal requests
ok( my $res = request("http://localhost/sendfile/$image_fn"), 'request ok' );
is( $res->header('X-LIGHTTPD-send-file'), $image_fn, 'correct sendfile header');

# sendfile: lighty emuration
{
    local $ENV{CATALYST_ENGINE} = 'HTTP';
    ok( $res = request("http://localhost/sendfile_emuration/$image_fn"), 'request ok');
    is( $res->content_length, -s $image, 'content_length ok');
}

# send_tempfile
{
    local $ENV{CATALYST_ENGINE} = 'FastCGI';
    ok( $res = request("http://localhost/send_tempfile"), 'request ok' );
    ok( $res->header('X-LIGHTTPD-send-tempfile'), 'X-LIGHTTPD-send-tempfile header ok' );

    ok( $res = request("http://localhost/send_tempfile_handle"), 'request ok' );
    ok( $res->header('X-LIGHTTPD-send-tempfile'), 'X-LIGHTTPD-send-tempfile header ok' );
}
