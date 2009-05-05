#!perl -T
use Test::Most;
use Acme::ReturnValue;

my @boring = qw(Boring RayApp);
plan tests => @boring * 4;

foreach my $boring (@boring) {
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/'.$boring.'.pm');
    cmp_deeply($arv->failed,[],"$boring: no failed");
    cmp_deeply($arv->interesting,[],"$boring: no interesting");
    
    my $data = $arv->boring->[0];
    is($data->{package},$boring,"$boring: package name");
    is($data->{value},'1',"$boring: return value is 1");
}


