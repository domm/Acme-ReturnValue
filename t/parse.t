#!perl -T
use Test::More tests => 6;
use Acme::ReturnValue;

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/Boring.pm');
    my $data = $arv->boring->[0];
    is($data->{package},'Boring','package');
    is($data->{value},'1','value');
}

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/Interesting.pm');
    my $data = $arv->interesting->[0];
    is($data->{package},'Interesting','package');
    is($data->{value},q|q{that's interesting!}|,'value');
}

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/UseUninstalled.pm');
    my $data = $arv->interesting->[0];
    is($data->{package},'UseUninstalled','package');
    is($data->{value},q|'ha!'|,'value');
}


