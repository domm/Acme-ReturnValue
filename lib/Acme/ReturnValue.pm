#!/usr/bin/perl
package Acme::ReturnValue;

use 5.010;
use strict;
use warnings;
use version; our $VERSION = qv '0.70.0';

use PPI;
use File::Find;
use Parse::CPAN::Packages;
use Path::Class qw();
use File::Spec::Functions;
use File::Temp qw(tempdir);
use File::Path;
use File::Copy;
use Archive::Any;
use Data::Dumper;
use YAML::Any qw(DumpFile); 

use Moose;
with qw(MooseX::Getopt);

has 'interesting' => (is=>'rw',isa=>'ArrayRef',default=>sub {[]});
has 'bad' => (is=>'rw',isa=>'ArrayRef',default=>sub {[]});
has 'failed' => (is=>'rw',isa=>'ArrayRef',default=>sub {[]});

has 'quiet' => (is=>'ro',isa=>'Bool',default=>0);
has 'inc' => (is=>'ro',isa=>'Bool',default=>0);
has 'dir' => (is=>'ro',isa=>'Str');
has 'file' => (is=>'ro',isa=>'Str');
has 'cpan' => (is=>'ro',isa=>'Str');
has 'dump_to' => (is=>'ro',isa=>'Str',default=>'returnvalues');

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

=cut

=head3 run

run from the commandline (via F<acme_returnvalue.pl>

=cut

sub run {
    my $self = shift;
   
    if ($self->inc) {
        $self->in_INC;
    }
    elsif ($self->dir) {
        $self->in_dir($self->dir);
    }
    elsif ($self->file) {
        $self->in_file($self->file);
    }
    elsif ($self->cpan) {
        $self->in_CPAN($self->cpan,$self->dump_to);
        exit;
    }
    else {
        $self->in_dir('.');
    }

    my $interesting=$self->interesting;
    if (@$interesting > 0) {
        foreach my $cool (@$interesting) {
            print $cool->{package} .': '.$cool->{value} ."\n";
        }
    }
    else {
        print "boring!\n";
    }
}

=head3 waste_some_cycles

    my $data = $arv->waste_some_cycles( '/some/module.pm' );

C<waste_some_cycles> parses the passed in file using PPI. It tries to 
get the last statement and extract it's value.

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

    my @significant = grep { _is_code($_) } $doc->schildren();
    my $match = $significant[-1];
    my $rv=$match->content;
    $rv=~s/\s*;$//;
    $rv=~s/^return //gi;

    return if $rv eq 1;
    
    my $data = {
        'file'    => $file,
        'package' => $this_package,
        'PPI'     => ref $match,
    };

    my @bad = map { 'PPI::Statement::'.$_} qw(Sub Variable Compound Package Scheduled Include Sub);

    if (ref($match) ~~ @bad) {
        $data->{'bad'}=$rv;
        push(@{$self->bad},$data);
    }
    elsif ($rv =~ /^('|"|\d|qw|qq|q|!|~)/) {
        $data->{'value'}=$rv;
        push(@{$self->interesting},$data);
    }
    else {
        $data->{'bad'}=$rv;
        $data->{'PPI'}.=" (but very likely crap)";
        push(@{$self->bad},$data);
    }
}

=head4 _is_code

Stolen directly from Perl::Critic::Policy::Modules::RequireEndWithOne
as suggested by Chris Dolan.

Thanks!

=cut

sub _is_code {
    my $elem = shift;
    return ! (    $elem->isa('PPI::Statement::End')
               || $elem->isa('PPI::Statement::Data'));
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
        $data->{file}=$distfile;
        my $dir;
        eval {
            $dir = tempdir('/var/tmp/arv_XXXXXX');
        
            my $archive=Archive::Any->new($distfile);
            $archive->extract($dir);
            
            $self->in_dir($dir,$dist->distvname);
             
        };
        if ($@) {
            print $@;
        }
        rmtree($dir);
    }
}

=head3 in_INC

    $arv->in_INC;

Collect return values from all F<*.pm> files in C<< @INC >>.

=cut

sub in_INC {
    my $self=shift;
    foreach my $dir (@INC) {
        $self->in_dir($dir,"INC_$dir");
    }
}

=head3 in_dir

    $arv->in_dir( $some_dir );

Collect return values from all F<*.pm> files in C<< $dir >>.

=cut

sub in_dir {
    my ($self,$dir,$dumpname)=@_;
    $dumpname ||= $dir;
    $dumpname=~s/\//_/g;

    say $dumpname unless $self->quiet;

    $self->interesting([]);
    $self->bad([]);
    my @pms;
    find(sub {
        return unless /\.pm\z/;
        return if $File::Find::name=~/\/x?t\//;
        return if $File::Find::name=~/\/inc\//;
        push(@pms,$File::Find::name);
    },$dir);

    foreach my $pm (@pms) {
        $self->in_file($pm);
    }

    if ($self->interesting && @{$self->interesting}) {
        my $dump=Path::Class::Dir->new($self->dump_to)->file($dumpname.".dump");
        DumpFile($dump->stringify,$self->interesting);
    }
    if ($self->bad && @{$self->bad}) {
        my $dump=Path::Class::Dir->new($self->dump_to)->file($dumpname.".bad");
        DumpFile($dump->stringify,$self->bad);
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
