package Net::HTTP::Methods::patch::log_request;

use 5.010001;
use strict;
no warnings;

use parent qw(Module::Patch);

# VERSION

our %config;

my $p_log_request = sub {
    require Log::Any;

    my $orig = shift;
    my $res = $orig->(@_);

    my $proto = ref($_[0]) =~ /^LWP::Protocol::(\w+)::/ ? $1 : "?";

    my $log = Log::Any->get_logger;
    $log->tracef("HTTP request (proto=%s, len=%d):\n%s",
                 $proto, length($res), $res);
    $res;
};

sub patch_data {
    return {
        config => {
        },
        versions => {
            # LWP is at 6.04, Net::HTTP 6.03, Net::HTTP::Methods still at 6.00
            '6.00' => {
                subs => {
                    format_request => $p_log_request,
                },
            },
        },
    };
}

1;
# ABSTRACT: Patch module for Net::HTTP::Methods

=head1 SYNOPSIS

 use Net::HTTP::Methods::patch::log_request;

 # now all your LWP HTTP requests are logged

Sample script and output:

 % LOG_SHOW_CATEGORY=1 TRACE=1 perl -MLog::Any::App \
   -MNet::HTTP::Methods::patch::log_request -MWWW::Mechanize \
   -e'$mech=WWW::Mechanize->new; $mech->get("http://www.google.com/")'
 [cat Net.HTTP.Methods.patch.log_request][23] HTTP request (142 bytes):
 GET / HTTP/1.1
 TE: deflate,gzip;q=0.3
 Connection: TE, close
 Accept-Encoding: gzip
 Host: www.google.com
 User-Agent: WWW-Mechanize/1.71

 [cat Net.HTTP.Methods.patch.log_request][70] HTTP request (144 bytes):
 GET / HTTP/1.1
 TE: deflate,gzip;q=0.3
 Connection: TE, close
 Accept-Encoding: gzip
 Host: www.google.co.id
 User-Agent: WWW-Mechanize/1.71


=head1 DESCRIPTION

This module patches Net::HTTP::Methods so that raw LWP HTTP request is logged
using L<Log::Any>. If you look into LWP::Protocol::http's source code, you'll
see that it is already doing that (albeit commented):

  my $req_buf = $socket->format_request($method, $fullpath, @h);
  #print "------\n$req_buf\n------\n";


=head1 FAQ

=head2 Why not subclass?

By patching, you do not need to replace all the client code which uses LWP (or
WWW::Mechanize, etc).

=cut
