use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Acme::ReturnValue',
    license           => 'perl',
    dist_author       => 'Thomas Klausner <domm@cpan.at>',
    dist_version_from => 'lib/Acme/ReturnValue.pm',
    requires          => {
        'PPI'                   => '1.118',
        'Archive::Any'          => '0.093',
        'Parse::CPAN::Packages' => '2.31',
        'Moose'                 => '0.77',
        'MooseX::Getopt'        => '0.18',
        'Path::Class'           => '0.16',
        'YAML::Any'             => '0.67',
    },
    build_requires => { 'Test::Most' => '0.21', },
    create_readme  => 1,
    create_license => 1,
    meta_merge     => {
        resources => {
            homepage => 'http://returnvalues.useperl.at',
            bugtracker =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-ReturnValue',
            repository => 'http://github.com/domm/Acme-ReturnValue',
        }
    },

);

$builder->create_build_script();
