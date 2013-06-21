use strict;
use warnings;

use novus::thai::feedpusher::http;

my $app = novus::thai::feedpusher::http->apply_default_middlewares(novus::thai::feedpusher::http->psgi_app);
$app;

