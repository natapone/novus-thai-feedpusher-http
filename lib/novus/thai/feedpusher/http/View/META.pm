package novus::thai::feedpusher::http::View::META;

use strict;
use warnings;
use Encode;
use JSON;
use XML::Feed;
use Log::Log4perl qw/get_logger/;
use base 'Catalyst::View::JSON';


sub process {
    my ($self, $c) = @_;
    
    if ($c->stash->{meta_object}) {
        my $json_hash = $c->stash->{meta_object};
        my $json = to_json($json_hash);
        
            if ( Encode::is_utf8($json) ) {
        $json = Encode::encode("utf-8", $json);
    }
        
        $c->res->body($json);
    }
    $c->res->content_type('application/json; charset=utf8');
}


1;
__END__
