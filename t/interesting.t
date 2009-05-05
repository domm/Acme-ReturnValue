#!perl -T
use Test::Most tests => 16;
use Acme::ReturnValue;


{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/Interesting.pm');
    cmp_deeply($arv->failed,[],'no failed');
    cmp_deeply($arv->boring,[],'no boring');
    
    my $data = $arv->interesting->[0];
    is($data->{package},'Interesting','package');
    is($data->{value},q|q{that's interesting!}|,'value');
}

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/UseUninstalled.pm');
    cmp_deeply($arv->failed,[],'no failed');
    cmp_deeply($arv->boring,[],'no boring');
    
    my $data = $arv->interesting->[0];
    is($data->{package},'UseUninstalled','package');
    is($data->{value},q|'ha!'|,'value');
}

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/MockTime.pm');
    cmp_deeply($arv->failed,[],'no failed');
    cmp_deeply($arv->boring,[],'no boring');
    
    my $data = $arv->interesting->[0];
    is($data->{package},'Test::MockTime','package');
    is($data->{value},q|*restore_time = \\&restore|,'value');
}


# invalid returns:
# Test::MockTime
# SpamMonkey::Config

# wrong postives
# RayApp
