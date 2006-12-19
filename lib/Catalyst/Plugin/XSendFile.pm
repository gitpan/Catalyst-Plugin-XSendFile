package Catalyst::Plugin::XSendFile;
use strict;
use warnings;
use base qw/Class::Data::Inheritable/;

use Catalyst::Utils;
use File::Temp qw/tempdir tempfile/;
use File::stat;
use NEXT;
use Path::Class qw/file/;
use Scalar::Util qw/blessed/;
use bytes;

our $VERSION = '0.03_001';

=head1 NAME

Catalyst::Plugin::XSendFile - Catalyst plugin for lighttpd's X-Sendfile.

=head1 SYNOPSIS

    use Catalyst qw/XSendFile/;
    
    # manual send file
    sub show : Path('/files') {
        my ( $self, $c, $filename ) = @_;
    
        # unless login, it shows 403 forbidden screen
        $c->res->status(403);
        $c->stash->{template} = 'error-403.tt';
    
        # serving a static file only when user logged in.
        if ($c->user) {
            $c->res->sendfile( "/path/to/$filename" );
        }
    }
    
    
    # auto using x-send-tempfile on large content serving
    MyApp->config->{sendfile}{tempdir} = '/dev/shm';

=head1 NOTICE

B<This developer version of module requires lighttpd 1.5.0 (r1477) or above.>

=head1 DESCRIPTION

lighty's X-Sendfile feature is great.

If you use lighttpd + fastcgi, you can show files only set X-Sendfile header like below:

    $c->res->header( 'X-LIGHTTPD-send-file' => $filename );

This feature is especially great for serving static file on authentication area.

And with this plugin, you can use:

    $c->res->sendfile( $filename );

instead of above.

But off-course you know, this feature doesn't work on Catalyst Test Server (myapp_server.pl).
So this module also provide its emulation when your app on test server.

=head1 SERVE LARGE CONTENT BY X-LIGHTTPD-send-tempfile

Latest version of lighttpd (1.5.0) also support X-LIGHTTPD-send-tempfile, that is almost same to X-LIGHTTPD-send-file except deleting sending file when server sent file.

This module automatically use this feature when content length is above 16kbytes.

And for more performance, you need to set tempdir ($c->config->{sendfile}{tempdir}) on tmpfs (/dev/shm).

See below urls for detail.

=head1 SEE ALSO

lighty's life - X-Sendfile
http://blog.lighttpd.net/articles/2006/07/02/x-sendfile

Faster - FastCGI
http://blog.lighttpd.net/articles/2006/11/29/faster-fastcgi

=head1 NOTICE

To use it you have to set "allow-x-sendfile" option enabled in your fastcgi configuration.

    "allow-x-send-file" => "enable",

or on 1.5.0:

    proxy-core.allow-x-sendfile = "enable"

=head1 EXTENDED_METHODS

=head2 setup

Setup tempdir for x-send-tempfile

=cut

sub setup {
    my $c = shift;
    $c->NEXT::setup(@_);

    my $tempdir = $c->config->{sendfile}{tempdir}
      || Catalyst::Utils::class2tempdir($c, 1);

    __PACKAGE__->mk_classdata(
        _sendfile_tempdir => tempdir( DIR => $tempdir, CLEANUP => 1 ) );

    $c;
}

=head2 finalize_headers

Serving large (16kbytes) content via X-LIGHTTPD-send-tempfile.

=cut

sub finalize_headers {
    my $c = shift;

    my $engine = $ENV{CATALYST_ENGINE} || '';

    # X-Sendfile emulation for test server.
    if ( $engine =~ /^HTTP/ ) {
        if ( my $sendfile = file( $c->res->header('X-LIGHTTPD-send-file') ) ) {
            $c->res->headers->remove_header('X-LIGHTTPD-send-file');
            if ( $sendfile->stat && -f _ && -r _ ) {
                $c->res->body( $sendfile->openr );
            }
        }
    }
    elsif ( $engine eq 'FastCGI' ) {

        if ( my $body = $c->res->body ) {
            my ( $fh, $tempfile ) = tempfile( DIR => $c->_sendfile_tempdir );

            if ( blessed($body) && $body->can('read') or ref($body) eq 'GLOB' ) {
                my $stat = stat $body;
                if ( $stat and $stat->size >= 16*1024 ) {
                    while ( !eof $body ) {
                        read $body, my ($buffer), 4096;
                        last unless $fh->write($buffer);
                    }
                    close $body;
                    close $fh;

                    $c->res->send_tempfile($tempfile);
                }
            }
            elsif ( bytes::length($body) >= 16*1024 ) {
                $fh->write($body);
                $fh->close;

                $c->res->send_tempfile($tempfile);
            }
        }
    }

    $c->NEXT::finalize_headers;
}

=head1 EXTENDED_RESPONSE_METHODS

=head2 sendfile

Set X-LIGHTTPD-send-file header easily.

=cut

{
    package # avoid PAUSE Indexer
        Catalyst::Response;

    sub sendfile {
        my ($self, $file) = @_;
        $self->{body} = '';
        $self->header( 'X-LIGHTTPD-send-file' => $file );
    }

    sub send_tempfile {
        my ($self, $file) = @_;
        $self->{body} = '';
        $self->header( 'X-LIGHTTPD-send-tempfile' => $file );
    }
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
