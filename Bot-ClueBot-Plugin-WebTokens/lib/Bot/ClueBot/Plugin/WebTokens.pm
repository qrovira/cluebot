package Bot::ClueBot::Plugin::WebTokens;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use utf8;
use 5.10.0;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


use JSON::WebToken;

my @TOKEN_CHARS = ('a'..'z', 'A'..'Z', '0'..'9', split '', ',./-_+=][{}";:^&*()%$#@!~`');

sub requires { qw/Commands/ }

sub init {
    my $self = shift;
    my $args = {
        token_expiration           => 60*60*24*7,
        secret_rotation            => 60*60*4,
        secret_expiration          => 60*60*24*7,
        %{ shift // {} },
    };

    $self->{token_expiration} = $args->{token_expiration};
    $self->{secret_rotation} = $args->{secret_rotation};
    $self->{secret_expiration} = $args->{secret_expiration}; # a bit redundant with token_expiration, but on 2 diff domains
    $self->data->{secrets} //= [];

    $self->bot->command(
        web_token => {
            help => "Generate auth token for use with other bot services",
            category => "Security",
        } => sub {
            my ($context) = @_;
            my ($user,$resource) = split '/', $context->{source_user};
            my $token = $context->{bot}->generate_token($user);

            # Explicit send_to_user, since this is sensitive
            $context->private_reply("Your new token is: $token");
        },
    );

    $self->bot->helper(
        decode_token => sub {
            my ($bot, $token) = @_;

            foreach my $secret ( @{ $self->_secrets } ) {
                my $data;
                eval { $data = JSON::WebToken->decode( $token, $secret->[0] ); };
                return $data->{aud} if $data && $data->{exp} > time;
            }
        },
        generate_token => sub {
            my ($bot, $user) = @_;
            return JSON::WebToken->encode( {
                exp => time + $self->{token_expiration},
                iss => $bot->{username},
                aud => $user,
            }, $self->_secrets()->[0][0] );
        }
    );
}



sub _secrets {
    my $self = shift;
    my $secrets = $self->data->{secrets};
    my $now = time;
    my $modified = 0;

    # Remove secrets older than $secret_expiration
    while( @$secrets && $secrets->[-1][1] < $now-$self->{secret_expiration} ) {
        pop @$secrets;
        $modified++;
    }

    # Generate new secret if the last available one is older than secret_rotation
    unless( @$secrets && $secrets->[0][1] > $now-$self->{secret_rotation} ) {
        my $new_secret = join '', map { $TOKEN_CHARS[0+int(rand($#TOKEN_CHARS))] } 1..64;
        unshift @$secrets, [ $new_secret, $now ];
        $modified++;
    }

    $self->save_data if $modified;

    return $secrets;
}


1;
