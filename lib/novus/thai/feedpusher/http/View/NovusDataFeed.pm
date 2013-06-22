package novus::thai::feedpusher::http::View::NovusDataFeed;

=head1 NAME

Novus::FeedPusher::HTTP::View::NovusDataFeed - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 METHODS

=cut

use strict;
use warnings;
use Encode;
use JSON;
use Log::Log4perl qw/get_logger/;
use base 'Catalyst::View::JSON';

=head2 process

Renders a view, with XML::Atom as input an JSON as output.

=cut

sub process {
    my ($self, $c) = @_;

    my $json_hash = $c->stash->{meta};
    my $json;
    if (my $obj = $c->stash->{ndf_object}) {
        $json = $obj->freeze;
    }

    $json ||= to_json($json_hash);
    $c->res->body($json);
    $c->res->content_type('application/json; charset=utf8');
}


#=============================================================================
1;
__END__

=head1 AUTHOR

Bjorn-Olav Strand, bolav@startsiden.no

=head1 LICENSE

All rights reserved.

=cut
