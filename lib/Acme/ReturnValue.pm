#!/usr/bin/perl
package Acme::ReturnValue;
use strict;
use warnings;
use version; our $VERSION = version->new( '0.04' );

use PPI;
use File::Find;
use Parse::CPAN::Packages;
use File::Spec::Functions;
use File::Temp qw(tempdir);
use File::Path;
use File::Copy;
use Archive::Any;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(interesting boring failed));

$|=1;

=head1 NAME

Acme::ReturnValue - report interesting module return values

=head1 SYNOPSIS

    use Acme::ReturnValue;
    my $rvs = Acme::ReturnValue->new;
    $rvs->in_INC;
    foreach (@{$rvs->interesting}) {
        say $_->{package} . ' returns ' . $_->{value}; 
    }

=head1 DESCRIPTION

C<Acme::ReturnValue> will list 'interesting' return values of modules. 
'Interesting' means something other than '1'.

=head2 METHODS

=head3 waste_some_cycles

    my $data = $arv->waste_some_cycles( '/some/module.pm' );

C<waste_some_cycles> parses the passed in file using PPI. It tries to 
get the last statement ('PPI::Token::Quote' or 'PPI::Token::Number') 
and extract it's value.

C<waste_some_cycles> returns a hash with following keys

=over

=item * file

The file

=item * package 

The package defintion (the first one encountered in the file

=item * value

The return value of that file

=back

C<waste_some_cycles> will also put this data structure into 
L<interesting> or L<boring>.

You might want to pack calls to C<waste_some_cycles> into an C<eval> 
because PPI dies on parse errors.

=cut

sub waste_some_cycles {
    my ($self, $file) = @_;
    my $doc = PPI::Document->new($file);

    eval {  # I don't care if that fails...
        $doc->prune('PPI::Token::Comment');
        $doc->prune('PPI::Token::Pod');
    }; 

    my @packages=$doc->find('PPI::Statement::Package');
    my $this_package;

    foreach my $node ($packages[0][0]->children) {
        if ($node->isa('PPI::Token::Word')) {
            $this_package = $node->content;
        }
    }

    my @statements = $doc->find(
        sub { $_[1]->isa('PPI::Token::Quote') || $_[1]->isa('PPI::Token::Number') }
    );

    my $last = pop (@{$statements[0]});
    my $return_value = $last->content;
    
    my $data = {
        'file'    => $file,
        'package' => $this_package,
        'value'   => $return_value,
    };
    if ($return_value eq '1') {
        push(@{$self->boring},$data);
    }
    else {
        push(@{$self->interesting},$data);
    }
    return $data;
}

=head3 new

    my $arc = Acme::ReturnValue->new;

Yet another boring constructor;

=cut

sub new {
    my ($class,$opts) = @_;
    $opts ||= {};
    my $self=bless $opts,$class;
    $self->interesting([]);
    $self->boring([]);
    $self->failed([]);
    return $self;
}

=head3 in_CPAN

=cut

sub in_CPAN {
    my ($self,$cpan,$out)=@_;

    my $p=Parse::CPAN::Packages->new(catfile($cpan,qw(modules 02packages.details.txt.gz)));

    if (!-d $out) {
        mkpath($out) || die "cannot make dir $out";
    }

    foreach my $dist (sort {$a->dist cmp $b->dist} $p->latest_distributions) {
        my $data;
        my $distfile = catfile($cpan,'authors','id',$dist->prefix);
        print "$distfile\n";
        $data->{file}=$distfile;
        my $dir;
        eval {
            $dir = tempdir('/var/tmp/arv_XXXXXX');
        
            my $archive=Archive::Any->new($distfile);
            $archive->extract($dir);
            my $outname=catfile($out,$dist->distvname.".dump");
            system("$^X $0 --dir $dir > $outname");
        };
        if ($@) {
            print $@;
            $data->{error}=$@;
            push (@{$self->failed},$data);
        }
        rmtree($dir);
        exit;
    }
}

=head3 in_INC

    $arv->in_INC;

Collect return values from all F<*.pm> files in C<< @INC >>.

=cut

sub in_INC {
    my $self=shift;
    foreach my $dir (@INC) {
        $self->in_dir($dir);
    }
}

=head3 in_dir

    $arv->in_dir( $some_dir );

Collect return values from all F<*.pm> files in C<< $dir >>.

=cut

sub in_dir {
    my ($self,$dir)=@_;
    
    my @pms;
    find(sub {
        return unless /\.pm\z/;
        push(@pms,$File::Find::name);
    },$dir);

    foreach my $pm (@pms) {
        $self->in_file($pm);
    }
}

=head3 in_file

    $arv->in_file( $some_file );

Collect return value from the passed in file.

If L<waste_some_cycles> failed, puts information on the failing file into L<failed>.

=cut

sub in_file {
    my ($self,$file)=@_;
    eval { $self->waste_some_cycles($file) };
    if ($@) {
        push (@{$self->failed},{file=>$file,error=>$@});
    }
}

"let's return a strange value";

__END__

=head3 interesting

Returns an ARRAYREF containing 'interesting' modules.

=head3 boring

Returns an ARRAYREF containing 'boring' modules.

=head3 failed

Returns an ARRAYREF containing unparsable modules.

=pod

=head1 BUGS

Probably many, because I'm not sure I master PPI yet.

=head1 AUTHOR

Thomas Klausner, C<< <domm@cpan.org> >>

Thanks to Armin Obersteiner and Josef Schmid for input during very 
early development

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-returnvalue@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Thomas Klausner

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
