package novus::thai::feedpusher::http::View::RSS;
use strict;
use warnings;

use base 'Catalyst::View';

=head1 NAME

Novus::FeedPusher::HTTP::View::RSS - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 METHODS

=cut

use DateTime qw( now );
use Log::Log4perl qw( get_logger );
use XML::Feed;
use XML::RSS;

=head2 process

Renders a view, with XML::Atom as input an RSS as output.

=cut

sub process {
    my ( $self, $c ) = @_;
    my $feed = $c->stash->{ndf_object}->as_atom;

    # use Data::Dump qw/dump/;
    # dump $c->stash->{ndf_object};

    my $rss = $self->convert_atom_to_rss( $feed, $c );
    $c->res->body( $rss->as_string );
    $c->res->content_type('application/rss+xml');
}

=head2 convert_atom_to_rss $feed

Convert a given atom feed to RSS format

=cut

sub convert_atom_to_rss {
    my $self = shift;
    my $feed = shift;
    my $c    = shift;
    my $rss_feed;

    $rss_feed = XML::RSS->new( version => '2.0' );
    my $rss_channel = {};

    ## add novus namespace
    my $novus_nsURI = 'http://xml.startsiden.no/ns/novus/';
    $rss_feed->add_module( prefix => 'novus', uri => $novus_nsURI );

    ## set channel elements
    foreach my $field (qw( id title link language author copyright generator )){
        my $val = $feed->$field;
        next unless defined $val;
        $rss_channel->{$field} = $val;
    }

# XML::Atom publiserer ikke lenger dette feltet.
# TODO: Make sure we have a lastBuildDate field.
# https://bugs.startsiden.no/browse/NOV-447
#    my $modified = $feed->updated();


#    if (! $modified){
#        $modified = '';
#        $c->log->debug("The XML::Atom novus feed had no updated or modified date");
#        $c->log->debug("the feed with the empty modified field had the id:" . $feed->id);
#    }
    ## FIXME: THis is a hack to get lastBuildDate
    $rss_channel->{lastBuildDate} = DateTime->now(); # $modified if $modified;

    ## FIXME: generate description somewhere? (required channel element in rss2.0)
    ## FIXME: See OVB-74 :)
    $rss_channel->{description} = "*description*";

    $rss_feed->channel(
                        title         => $rss_channel->{title}        || '',
                        link          => $rss_channel->{link}         || '',
                        description   => $rss_channel->{description}  || '',
                        lastBuildDate => $rss_channel->{lastBuildDate},
                        novus         => {
                            id => $rss_channel->{id},
                            total_entries    => $feed->search_meta->total_entries,
                            current_page     => $feed->search_meta->current_page,
                            entries_per_page => $feed->search_meta->entries_per_page,

                        }
    );

    foreach my $entry ( $feed->entries ) {
        my $rss_entry = {};
        my $link      = $entry->link();
        my ( $source, $modified );

        if ($link) {
            $rss_entry->{link} = ( $link->href );
        }
        if ( $entry->category ) {
            $rss_entry->{category}->{name} = $entry->category->label;
        }

        foreach my $field (qw(title summary author id issued )) {
            if ($entry->$field) {
                $rss_entry->{$field} = $entry->$field;
            }
        }

        my $novus_hash = {};

        ## fetch cluster info
        my $nsURI      = "http://purl.org/dc/elements/1.1/";
        my $dc         = XML::Atom::Namespace->new( dc => $nsURI );
        my $cluster_id = $entry->get( $dc, 'cluster' );
        $novus_hash->{cluster} = $cluster_id if $cluster_id;

        # HACK: should have been possible to do something like
        # ``$entry->source->title'';
        $source = $entry->elem->getElementsByTagName("source")->get_node(0);
        $novus_hash->{source} = $source->getElementsByTagName('id')->string_value;
        $novus_hash->{publisher} = $source->getElementsByTagName('title')->string_value;

        ## item.datecreated is indexed as modified (for whatever reason)
        my $pubDate = $entry->updated();

        if (! $pubDate) {
            $pubDate = '';

            my $logger = get_logger();
            $c->log->debug("The XML::Atom novus entry had no updated or modified date");
            $c->log->debug("the entry with the empty modified field had the id:" . $entry->id);
        }

        $rss_entry->{pubDate} = $pubDate;


        $rss_feed->add_item(
                             title       => $rss_entry->{title},
                             link        => $rss_entry->{link},
                             description => $rss_entry->{summary} || '',
                             category    => $rss_entry->{category}->{name} || '',
                             pubDate     => $rss_entry->{pubDate},
                             novus       => $novus_hash,
                             guid        => $entry->id,
        );
    }

    return $rss_feed;
}

#=============================================================================
1;
__END__

=head1 AUTHOR

Lise Angell, lisea@linpro.no

=head1 LICENSE

All rights reserved.

=cut
