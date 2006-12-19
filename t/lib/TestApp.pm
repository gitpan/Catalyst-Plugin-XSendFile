package TestApp;
use strict;
use warnings;

use Catalyst qw/XSendFile/;

use File::Temp qw/tempfile/;

__PACKAGE__->config(
    name => 'TestApp',
);

sub sendfile : Global {
    my ( $self, $c, $filename ) = @_;

    $c->res->sendfile($filename);
}

sub sendfile_emuration : Global {
    my ( $self, $c, $filename ) = @_;
    $c->res->sendfile( $c->path_to( 'root', $filename )->stringify );
}

sub send_tempfile : Global {
    my ( $self, $c ) = @_;
    $c->res->body( ' ' x (16*1024) ); # sending 16kb data
}

sub send_tempfile_handle : Global {
    my ( $self, $c ) = @_;
    my ($fh, $tempfile) = tempfile( UNLINK => 1 );
    $fh->write(' ' x (16*1024));

    $c->res->body($fh);
}

1;
