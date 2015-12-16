package Bot::ClueBot::Plugin::ACL;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use 5.10.0;

sub init {
    my ($self, $args) = @_;

    $self->data->{acls} //= $args->{acls} // {};

    $self->bot->helper(
        auth => sub {
            my ($bot, $acl, $user) = @_;

            if($args->{admin} && $user eq $args->{admin}) {
                $self->bot->debug("Auth check for global admin user $user on acl $acl");
                return 1;
            }

            $self->bot->debug("Auth check for user $user on acl $acl");

            return $self->data->{acls}{$acl} && exists $self->data->{acls}{$acl}{$user};
        },
        register_acl => sub {
            my ($bot, $acl) = @_;

            $self->data->{acls}{$acl} //= {};
        }
    );

}



# Override parent's peristent data store implementation to load arrays into hashes for quick lookup and save it back to arrays.
#

sub load_data {
    my $self = shift;
    my $data = $self->SUPER::load_data(@_);

    return { acls => { map { $_ => { map { $_ => 1 } @{ $data->{$_} } } } keys %$data } };
}

sub save_data {
    my $self = shift;

    $self->SUPER::save_data( $self->freeze_data );
}

sub freeze_data {
    my $self = shift;
    my $data = { map { $_ => [ sort { $a cmp $b } keys %{$self->data->{acls}{$_}} ] } keys %{ $self->data->{acls} } };
    return $data;
}


1;
