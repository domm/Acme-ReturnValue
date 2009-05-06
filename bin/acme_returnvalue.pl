#!perl
use 5.010;
use strict;
use warnings;
use Acme::ReturnValue;

Acme::ReturnValue->new_with_options->run;

__END__
if (my $dumpdir = $opts{generate_html}) {
    $arv->generate_report_from_dump($dumpdir);
    exit;
} 

