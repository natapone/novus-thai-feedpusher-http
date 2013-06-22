package novus::thai::feedpusher::http::Controller::Root;
use Moose;
use namespace::autoclean;
use novus::thai::schema;
use novus::thai::utils;
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
    
    print Dumper($q);
    print Dumper($e);
    
    ## check for some parameters in the query to override path-parts
#    if ($c->req->param('page')) {
#        $e->{page} = $c->req->param('page');
#    }
#    
#    my $feed;
#    eval {$feed = $c->model('FeedPusher')->feed($q, $e)};
#    eval {$feed = $self->feed($q, $e)};
    
    
    
    
}

#sub feed {
#    my $self  = shift;
#    my $query = shift || {};
#    my $extra = shift || {};
#    my $p     = delete $extra->{page} || 1;
#    
#    # search db
#    my $schema = $self->schema;
#    
#    
#    # create feed
#    
#    
#    
#}

#sub schema {
#    my $self = shift;
#    my $config = $self->config();
#    
#    print "--- create schema: ", Dumper($config);
#    
#    return novus::thai::schema->connect(
#                                $config->{connect_info}[0], 
#                                $config->{connect_info}[1], 
#                                $config->{connect_info}[2], 
#                                $config->{connect_info}[3], 
#                            );
#}

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

##sub index :Path :Args(0) {
##    my ( $self, $c ) = @_;

##    # Hello World
##    $c->response->body( $c->welcome_message );
##}

##=head2 default

##Standard 404 error page

##=cut

##sub default :Path {
##    my ( $self, $c ) = @_;
##    $c->response->body( 'Page not found' );
##    $c->response->status(404);
##}

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
