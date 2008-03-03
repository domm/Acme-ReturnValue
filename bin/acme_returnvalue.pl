#!perl
use strict;
use warnings;
use Acme::ReturnValue;
use Getopt::Long;
use Data::Dumper;

my %opts;
GetOptions(\%opts,qw(
    inc
    dir=s
    file=s
    cpan=s
    out=s
    report
    generate_html=s
));

my $arv=Acme::ReturnValue->new;

if (my $dumpdir = $opts{generate_html}) {
    $arv->generate_report_from_dump($dumpdir);
    exit;
} 
elsif ($opts{inc}) {
    $arv->in_INC();    
}
elsif (my $dir = $opts{dir}) {
    $arv->in_dir($dir);
}
elsif (my $file = $opts{file}) {
    $arv->in_file($dir);
}
elsif (my $cpan = $opts{cpan}) {
    $arv->in_CPAN($cpan, $opts{out} || '.')
}
else {
    $arv->in_dir('.');
}

if ($opts{report}) {
    print "\nResults\n";
    my $interesting=$arv->interesting;
    if (@$interesting > 0) {
        foreach my $cool (@$interesting) {
            print $cool->{package} .': '.$cool->{value} ."\n";
        }
    }
    else {
        print "boring!\n";
    }
}
else {
    print Dumper $arv;    
}
