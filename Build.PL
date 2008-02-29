use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::ReturnValue',
    license             => 'perl',
    dist_author         => 'Thomas Klausner <domm@zsi.at>',
    dist_version_from   => 'lib/Acme/ReturnValue.pm',
);

$builder->create_build_script();
