package novus::thai::feedpusher::http::View::Atom;

=head1 NAME

Novus::FeedPusher::HTTP::View::Atom - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 METHODS

=cut

use strict;
use warnings;
use Data::Dumper;
use base 'Catalyst::View';

=head2 process

Renders a view, with XML::Atom as input an Atom as output.

=cut

sub process {
    my ($self, $c) = @_;
    
    my $feed = $c->stash->{ndf_object}->as_atom;
    my $id = '';
    my $class = ref($feed);
    if($class =~ 'Atom'){
        my $xml = $feed->as_xml;
        $c->res->body($xml);
        $c->res->content_type('application/atom+xml');
    }
    else{
        warn "Unrecognized feed format!";
    }
    
    

}

#=============================================================================
1;
__END__

=head1 AUTHOR

Andreas Marienborg

=head1 LICENSE

All rights reserved.

=cut
