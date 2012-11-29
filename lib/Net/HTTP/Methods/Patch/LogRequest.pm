package Net::HTTP::Methods::Patch::LogRequest;

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

# VERSION

our %config;

my $p_log_request = sub {
    require Log::Any;

    my $ctx = shift;
    my $orig = $ctx->{orig};
    my $res = $orig->(@_);

    my $proto = ref($_[0]) =~ /^LWP::Protocol::(\w+)::/ ? $1 : "?";

    my $log = Log::Any->get_logger;
    if ($log->is_trace) {

        # there is no equivalent of caller_depth in Log::Any, so we do this only
        # for Log4perl
        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1
            if $Log::{"Log4perl::"};

        $log->tracef("HTTP request (proto=%s, len=%d):\n%s",
                     $proto, length($res), $res);

    }
    $res;
};

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'wrap',
                mod_version => qr/^6\.0.*/,
                sub_name    => 'format_request',
                code        => $p_log_request,
            },
        ],
    };
}

1;
# ABSTRACT: Log raw HTTP requests

=for Pod::Coverage ^(patch_data)$

=head1 SYNOPSIS

 use Net::HTTP::Methods::Patch::LogRequest;

 # now all your LWP HTTP requests are logged

Sample script and output:

 % LOG_SHOW_CATEGORY=1 TRACE=1 perl -MLog::Any::App \
   -MNet::HTTP::Methods::Patch::LogRequest -MWWW::Mechanize \
   -e'$mech=WWW::Mechanize->new; $mech->get("http://www.google.com/")'
 [cat Net.HTTP.Methods.Patch.LogRequest][23] HTTP request (142 bytes):
 GET / HTTP/1.1
 TE: deflate,gzip;q=0.3
 Connection: TE, close
 Accept-Encoding: gzip
 Host: www.google.com
 User-Agent: WWW-Mechanize/1.71

 [cat Net.HTTP.Methods.Patch.LogRequest][70] HTTP request (144 bytes):
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
