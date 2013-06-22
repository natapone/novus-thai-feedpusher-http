package novus::thai::feedpusher::http::View::JSON;

=head1 NAME

Novus::FeedPusher::HTTP::View::JSON - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 METHODS

=cut

use strict;
use warnings;
use Encode;
use JSON;
use XML::Feed;
use Log::Log4perl qw/get_logger/;
use base 'Catalyst::View::JSON';

=head2 process

Renders a view, with XML::Atom as input an JSON as output.

=cut

sub process {
    my ($self, $c) = @_;

    my $json_hash = $c->stash->{meta};
    if ($c->stash->{ndf_object}) {
        $json_hash = atom_to_json($c->stash->{ndf_object}->as_atom);
    }

    my $json = to_json($json_hash);
#    if ( Encode::is_utf8($json) ) {
#        $json = Encode::encode("utf-8", $json);
#    }
    $c->res->body($json);
    $c->res->content_type('application/json; charset=utf8');
}

=head2 atom_to_json $atom_feed_object

Convert an XML::Atom feed to JSON

=cut

sub atom_to_json{
    my $feed      = shift;
    my $logger    = get_logger();
    my $json_hash = {};
    my $i;

    ### NB: Får url til første entry her, og ikke feed_id

    MAIN_ATTR:
    for my $k (qw/id author language title version/) {
        my $v = $feed->$k or next MAIN_ATTR;
        $json_hash->{'feed'}{$k} = $v;
    }

    META:
    for my $k (qw/total_entries current_page entries_per_page/) {
        $json_hash->{'search_meta'}{$k} = $feed->search_meta->$k;
    }
    #$logger->debug(" # of hits: " . $json_hash->{'search_meta'}{total_entries}) if ;

    # process links
    $i = 0;
    LINK:
    for my $link (@_ = $feed->link){
        my $tmp_link = {};

        ATTR:
        for my $k (qw/href hreflang rel title type/) {
            my $v = $link->$k or next ATTR;
            $json_hash->{'feed'}{'link'}[$i]{$k} = $v;
        }

        $i++ if($json_hash->{'feed'}->{'link'}[$i]);
    }

    ## process entries
    my $feed_entries = [];
    foreach my $entry ($feed->entries) {
        my $entry_hash = {};

        MAIN_ATTR:
        for my $k (qw/author title id summary updated/) {
            my $v = $entry->$k or next MAIN_ATTR;
            $entry_hash->{$k} = $v;
        }

        ### content
        if($entry->content){
            $entry->content->type('text') unless $entry->content->type;
        }
        $entry_hash->{'content'} = $entry->content ? $entry->content->body : undef;

        $i = 0;
        LINK:
        for my $link (@_ = $entry->link){

            ATTR:
            for my $k (qw/href hreflang rel title type/) {
                my $v = $link->$k or next ATTR;
                $entry_hash->{'link'}[$i]{$k} = $v;
            }

            $i++ if($entry_hash->{'link'}[$i]);
        }

        ### source
        ##  HACK: should have been possible to do something like
        ##  $entry->source->title;
        ##
        if(my $node = $entry->elem->getElementsByTagName('source')) {
            for my $k (qw/id title/) {
                my $e = $node->get_node(0)->getElementsByTagName($k) or next;
                my $v = $e->string_value                             or next;
                $entry_hash->{'source'}{$k} = $v;
            }
        }

        $i = 0;
        CATEGORY:
        for my $cat (@_ = $entry->categories) {

            ATTR:
            for my $k (qw/term label/) {
                my $v = $cat->$k or next ATTR;
                $entry_hash->{'category'}[$i]{$k} = $v;
            }

            $i++ if($entry_hash->{'category'}[$i]);
        }

        CLUSTER:
        my $nsURI = 'http://purl.org/dc/elements/1.1/';
        my @nodes = $entry->elem->getElementsByTagNameNS($nsURI,'cluster');
        foreach my $node (@nodes){
            $entry_hash->{'cluster'} = $node->textContent if $node->textContent;
        }
        push @$feed_entries, $entry_hash;
    }
    $json_hash->{'feed'}->{'entry'} = $feed_entries;
    return $json_hash;
}

#=============================================================================
1;
__END__

=head1 AUTHOR

Lise Angell, lisea@linpro.no

=head1 LICENSE

All rights reserved.

=cut
