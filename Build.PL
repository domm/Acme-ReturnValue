use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::ReturnValue',
    license             => 'perl',
    dist_author         => 'Thomas Klausner <domm@cpan.at>',
    dist_version_from   => 'lib/Acme/ReturnValue.pm',
    requires    => {
        'PPI'           => '1.118',
        'Archive::Any'  => '0.093',
        'Parse::CPAN::Packages' => '2.26',
        'Class::Accessor'   => '0.31',
    },
    build_requires  => {
        'Test::Pod'             => '1.14',
        'Test::Pod::Coverage'   => '1.04',
    },
);

$builder->create_build_script();
