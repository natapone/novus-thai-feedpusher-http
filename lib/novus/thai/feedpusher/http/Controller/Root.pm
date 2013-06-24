package novus::thai::feedpusher::http::Controller::Root;

use Moose;
#use namespace::autoclean;
use novus::thai::schema;
use novus::thai::utils;

use Novus::Data::Feed;
use Novus::Data::Item;
use Novus::Data::Media;
use Novus::Data::SearchMeta;

use Encode;
use POSIX qw( strftime );
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

novus::thai::feedpusher::http::Controller::Root - Root Controller for novus::thai::feedpusher::http

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub default : Private {
    my ( $self, $c, @args ) = @_;
    
    # http://localhost:3003/type:json/rows:10/page:1/category:4
    
    my ($q, $e) = $self->parse_query(@args, $c->req->param('q') || undef);
    my $feed_type = $q->{'type'}[0] || 'RSS';
    delete $q->{'type'};
    $e->{type} = $feed_type;
    
#    print Dumper($q);
#    print Dumper($e);
    
    ## check for some parameters in the query to override path-parts
    if ($c->req->param('page')) {
        $e->{page} = $c->req->param('page');
    }
#    
    my $feed;
#    eval {$feed = $c->model('FeedPusher')->feed($q, $e)};
#    eval {$feed = $self->feed($q, $e)};
    
    $feed = $self->feed($q, $e);
    
    
    
    $c->stash->{ndf_object} = $feed;

    if($feed_type =~ m/atom/i){
        $c->stash->{current_view} = 'Atom';
    }
    elsif($feed_type =~ m/rss/i){
        #FIX add total_entries to RSS if needed
        $c->stash->{current_view} = 'RSS';
    }
    elsif($feed_type =~ m/json/i){
        $c->stash->{current_view} = 'JSON';
    }
    elsif($feed_type =~ m/novus/i){
        $c->stash->{current_view} = 'NovusDataFeed';
    }
    elsif (lc($feed_type) eq 'count') {
        $c->stash->{value} = $c->model('FeedPusher')->count($q, $e);
        $c->stash->{element_name} = 'count';
        $c->stash->{current_view} = 'XML';
    }
    else{
        warn "Unrecognized feed format!";
    }
}

sub resultset_to_ndf_feed {
#    my $self    = shift;
    my $results = shift;
    my $query   = shift;
    my $extra   = shift;
#    my ($self, $results, $query, $extra ) = @_;
    $extra ||= {};
    #warn "query: " . dump($query);
#    my $logger = get_logger();
    my $p = $query->{public};
#    print "==query==", Dumper($query), "\n";
#    print "==extra==", Dumper($extra), "\n";
    
    my $sm = Novus::Data::SearchMeta->new( 
#        total_entries    => $results->pager->total_entries,
#        current_page     => $results->pager->current_page,
#        entries_per_page => $results->pager->entries_per_page,
        
        total_entries    => 100,
        current_page     => 1,
        entries_per_page => 20,
    );
    
    my $feed = Novus::Data::Feed->new( 
        searchmeta => $sm,
#        title => $self->get_title($results),
        title => "Alle nyheter",
    );
    
    my $id = build_query($query);
    $id =~ s/public:1//;
    $id =~ s/^\s+//;
    $id =~ s/\s+$//;
    $feed->id(Encode::encode("utf-8", $id));
    
    while (my $res = $results->next) {
        my $meta = {};
#        my $meta  = $res->metadata;
        
        my $entry = Novus::Data::Item->new;
        $entry->title($res->title);
        $entry->id($res->id);
        $entry->summary($res->description);
        $entry->link($res->link);
        
#        print $res->id, ": add media === ",$res->feed->source->url, " : ", $res->media, "\n";
        
#        $d =    $res->timestamp
#        print "-----------------> ",strftime('%Y-%m-%dT%H:%M:%SZ',gmtime($res->timestamp)), "\n";
        my $updates = strftime('%Y-%m-%dT%H:%M:%SZ',gmtime($res->timestamp));
        $entry->modified( DateTime::Format::ISO8601->parse_datetime($updates) );
        
        $entry->siteid($res->feed->source->url || '');
        $entry->sitename($res->feed->source->name || '');
        $entry->siteurl($res->feed->source->url);
        
        # add media
        
        if ($res->media) {
            my $media_url = $res->media;
            if ($res->media !~ m/^http/ ) {
                $media_url = $res->feed->source->url . $media_url;
#                print "     -- fix: $media_url \n";
            }
            
            my $enclosure = {
                'url' => $media_url,
                'type' => 'image',
            };
            $entry->add_media( Novus::Data::Media->new( $enclosure) );
        }
        
        $feed->add_item($entry);
    }
    
#    print "--feed--", Dumper($feed);
    return $feed;
}

sub build_query {
#    my $self = shift;
    my $q = shift;
    my @q_parts;

    if ($q->{'terms'}) {
        push(@q_parts, '' . $q->{'terms'} . '');
    }

    foreach my $k (keys %$q) {
        next if ($k eq 'terms');
        next unless defined $k;
        my $v = $q->{$k};
        my @v = (ref $v ? @$v : ($v));
        my $q_part = "";
        my $negate = 0;
        if ($k =~ s/^!//) {
            $negate = 1;
            $q_part = "NOT ";
            $q_part .= "(" if (scalar(@v) > 1);
        }
        $q_part .= join(' ', map { $k . ":" . $_ } grep { defined($_) } @v) . "";
        if ($negate && scalar(@v) > 1) {
            $q_part .=  ")";
        }
        push(@q_parts, $q_part);
    }

    return join(" ", @q_parts);
}


sub feed {
    my $self  = shift;
    my $query = shift || {};
    my $extra = shift || {};
    my $p     = delete $extra->{page} || 1;
    
    # search db, only category
    my $schema = $self->schema();
#    my $source = $schema->resultset('Source')->find(1);
    
    if ($query->{'category'} ) {
        # get feeds list
        my $category = $schema->resultset('Category')->find($query->{'category'});
        my $feeds = $category->feeds;
        
        # if specific source
        if($query->{'source'}) {
            $feeds = $feeds->search({ sourceid => {'in' => $query->{'source'}} });
        }
        
        my @feed_read;
        while (my $feed = $feeds->next) {
            push(@feed_read, $feed->id);
        }
        
        
        my $results  = $schema->resultset('Item')->search (
    #        $query
            {
                feedid  => {'in' => \@feed_read},
                'length(media)'   => {'>' => 0},
            }, {
                rows        => $extra->{'rows'},
                order_by    => { -desc => [qw/timestamp/] }
            }
        );
        
#        while (my $item = $results->next) {
#            print "-----* ",$item->id,": ", $item->title, " -- ", $item->media, "\n";
#        };
    
        # create feed
#        print "-----create feed-----  \n";
        my $result_feeds = resultset_to_ndf_feed($results, $query, $extra);
        return $result_feeds;
    }
}

sub schema {
    my $self = shift;
    my $config = novus::thai::utils->get_config();
#    print "--- create schema: ", Dumper($config);
    
    return novus::thai::schema->connect(
                                $config->{connect_info}[0], 
                                $config->{connect_info}[1], 
                                $config->{connect_info}[2], 
                                $config->{connect_info}[3], 
                            );
}

#sub config {
#    return novus::thai::utils->get_config();
#}

sub parse_query {
    my $self = shift;
    my $q = pop;
    my @args = @_;

    # warn "q: $q" if defined($q);
    my $query = {};
    my %extra = (page => 1, dupedate => 'last');
    for(@args) {
        next unless($_);
        my ($t, $v) = split /:/, $_;
        if ($t eq 'page') {
            $extra{page} = $v;
            next;
        }
        if ($t eq 'order') {
            $extra{order} = $v;
            next;
        }
        if ($t eq 'rows') {
            $extra{rows} = $v;
            next;
        }
        if ($t eq 'internal') {
            $extra{'internal'} = $v;
            next;
        }
        if ($t eq 'unique') {
            $extra{'unique'} = $v;
            next;
        }
        if ($t eq 'collapse') {
            # deprecated for now
            next;
        }
        if ($t eq 'archive') {
            $extra{'archive'} = $v;
            next;
        }
        if ($t eq 'dupedate') {
            $extra{'dupedate'} = $v;
            next;
        }

        $query->{$t} = [] unless $query->{$t};
        push(@{ $query->{$t} }, $v);
    }
    if (defined($q)) {
        $query->{'terms'} = $q;
    }
    if (scalar(keys(%$query)) == 0 || (scalar(keys(%$query)) == 1 and exists $query->{type})) {
        # empty query, lets default to 1..<now>
        $query->{'terms'} = '1..' . time;
        # not allowing empty searches against the archive index (takes too long)
        delete $extra{'archive'};
    }
    return ($query, \%extra);

}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Dong,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
