package Bot::ClueBot::Plugin::HTTPD;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use utf8;
use 5.10.0;

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


use AnyEvent::HTTPD;
use JSON;
use YAML;
use HTML::Entities;
use Sys::Hostname;
use URI::Escape;

sub requires { qw/Commands WebTokens/ }

sub init {
    my $self = shift;
    my $args = {
        port => 9090,
        %{ shift // {} },
    };

    my $base_url = ($args->{cert} ? "https://" : "http://") . hostname . ':' . $args->{port} . '/';

    $self->{httpd} = AnyEvent::HTTPD->new(
        port => $args->{port},
        ( $args->{cert} ? ( ssl => { cert_file => $args->{cert} } ) : () ),
    );

    $self->{httpd}->reg_cb(
        '' => sub { $_[1]->respond([ 404, "Wut?" ]); }
    );

    $self->bot->helper(
        webservice => sub {
            my $bot = shift;

            while( @_ ) {
                my ($path, $cb) = ( shift, shift );
                $bot->debug("Registered HTTPD webservice on $path");
                $self->{httpd}->reg_cb( $path => $cb );
            }
        }
    );

    $self->bot->webservice(
        '/command' => sub { $self->_handle_command( @_ ); },
        '/authorize' => sub { $self->_handle_authorize( @_ ); }
    );

}


sub _handle_command {
    my ($self, $httpd, $req) = @_;
    my %cookies = map { split '=', $_, 2 } split /[;,]\s?/, $req->headers->{'cookie'} // '';
    my $user = $self->bot->decode_token( $cookies{token} );

    unless( $user ) {
        $req->respond({ redirect => '/authorize' });
        return;
    }

    my ($command) = $req->url =~ m#^/command/([^/\?]+)(\?.*)?$#;
    unless( $command ) {
        _respond_json_or_html( $req, "Unknown command", 404 );
        return;
    }

    my %params = map { $_ => $req->parm($_) } $req->params;
    my $argline = delete $params{argline};

    my $context = Bot::ClueBot::Plugin::Commands::Context::HTTPD->new(
        bot => $self->bot,
        (
            defined($argline) ? (argline => $argline) :
            keys(%params) ? (params => \%params) :
            ()
        ),
        user => $user,
        req  => $req,
    );

    $self->bot->handle_comand( $command, $context );
}

sub _handle_authorize {
    my ($self, $http, $req) = @_;
    my ($token, $user) = map { $req->parm($_) } qw/token user/;
    my $error = "";

    if( $user && $token ) {
        if( ($self->bot->decode_token( $token ) // '') ne $user ) {
            $error = "Invalid token";
        } else {
            $req->respond([ 200, "Welcome", { Location => "/", 'Set-Cookie' => "token=".$token }, <<"EOD" ]);
<!DOCTYPE HTML>
<html><head><title>Welcome!</title></head>
<body><h1>Welcome!</h1><p>You may now use the web interface.<br/>See <a href="/command/help">Help</a> for details.</p></body>
</html>
EOD
            return;
        }
    }

    $req->respond({
        content => ['text/html', <<"EOH"]
<!DOCTYPE HTML>
<html><head><title>Authorization with @{[ $self->bot->{username} ]}</title></head>
<body>
<h1>Authorization with @{[ $self->bot->{username} ]}</h1>
@{[ $error ? "<p style=\"color:red;\">$error</p>" : "" ]}
<p>Request a token from the bot via the <em>web_token</em> command, and paste it below to save the authorization</p>
<form method="post">
  <label for="user">User:</label>
  <input type="text" name="user" value="@{[ $req->parm('user') // '' ]}" />
  <br/>
  <label for="token">Token:</label>
  <input type="text" name="token" value="@{[ $req->parm('token') // '' ]}" />
  <br/>
  <input type="submit"/>
</form>
</body>
</html>
EOH
    });
}

my %status2message = (
    200 => "Ok",
    403 => "Forbidden",
    404 => "Not Found",
);
sub _respond_json_or_html {
    my ($req, $data, $status_code, $status_message ) = @_;

    $status_code //= 200;

    if( ($req->headers->{Accepts} // '') =~ m#json# ) {
        $req->respond([
            $status_code,
            $status_message // $status2message{$status_code} // "",
            { 'Content-Type' => 'application/json' },
            encode_json( ref($data) ? $data : { message => $data } )
        ]);
    } else {
        $req->respond([
            $status_code,
            $status_message // $status2message{$status_code} // "",
            { 'Content-Type' => 'text/html' },
            '<html><body><pre>'.
            encode_entities( ref($data) ? Dump($data) : $data ).
            '</pre></body></html>'
        ]);
    }
}

package Bot::ClueBot::Plugin::Commands::Context::HTTPD;

use YAML;

our @ISA = ('Bot::ClueBot::Plugin::Commands::Context');

sub new {
    my ($proto, %args) = @_;
    my $user = delete $args{user};
    my $req = delete $args{req};

    my $self = $proto->SUPER::new(
        %args,
        source_type => 'httpd',
        source_jid  => $user.'/httpd',
    );

    return $self;
}

sub reply {
    my ($self, $data) = @_;
    Bot::ClueBot::Plugin::HTTPD::_respond_json_or_html( $self->{req}, $data );
}

sub private_reply { shift->reply(@_); }

1;
