#!perl
use strict;
use warnings;
use 5.010;
use Acme::ReturnValue;

my $arv=Acme::ReturnValue->new;
$arv->in_INC();

foreach my $cool (@{$arv->interesting}) {
    print $cool->{package}.":\n".$cool->{value}."\n\n";
}
