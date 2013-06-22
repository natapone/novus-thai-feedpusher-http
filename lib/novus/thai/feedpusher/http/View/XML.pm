package novus::thai::feedpusher::http::View::XML;

=head1 NAME

Novus::FeedPusher::HTTP::View::JSON - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 METHODS

=cut

use strict;
use warnings;
use XML::LibXML;
use base 'Catalyst::View';

=head2 process

Renders a view, with xml_object as input an Atom as output.

=cut

sub process {
    my ($self, $c) = @_;

    my $name = $c->stash->{element_name};
    return unless $name;
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElement($name);
    $doc->setDocumentElement($root);
    my $value = $c->stash->{value};
    if (ref($value) eq 'HASH') {
        foreach my $k (keys %$value) {
            my $elem = $doc->createElement($k);
            
            $elem->appendChild($doc->createTextNode($value->{$k}));
            $root->appendChild($elem);
        }
    } else {
        $root->appendChild( $doc->createTextNode($value) );
    }
    $c->res->body($doc->toString());
    $c->res->content_type('application/xml');
}

#=============================================================================
1;
__END__

=head1 AUTHOR

Lise Angell, lisea@linpro.no

=head1 LICENSE

All rights reserved.

=cut
