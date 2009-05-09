#!/usr/bin/perl
package Acme::ReturnValue::MakeSite;

use 5.010;
use strict;
use warnings;

use File::Find;
use Path::Class qw();
use File::Spec::Functions;
use File::Temp qw(tempdir);
use File::Path;
use URI::Escape;
use Encode;
use Data::Dumper;
use Acme::ReturnValue;

use Moose;
with qw(MooseX::Getopt);

has 'now' => (is=>'ro',isa=>'Str',default => sub { scalar localtime});
has 'quiet' => (is=>'ro',isa=>'Bool',default=>0);
has 'data' => (is=>'ro',isa=>'Str',default=>'returnvalues');
has 'out' => (is=>'ro',isa=>'Str',default=>'htdocs');


$|=1;

=head1 NAME

Acme::ReturnValue::MakeSite - generate some HTML pages

=head1 SYNOPSIS

    use Acme::ReturnValue::MakeSite;

=head1 DESCRIPTION

Generate a small site based on the findings of L<Acme::ReturnValue>

=head2 METHODS

=cut

=head3 run

run from the commandline (via F<acme_returnvalue_makesite.pl>

=cut

sub run {
    my $self = shift;

    my @interesting;
    my $datadir = $self->data;
    my $dir = Path::Class::Dir->new($datadir); 
    
    my %cool_dists;
    my %bad_dists;
    my %cool_rvs;
    #my %authors;

    while (my $file=$dir->next) {
        next unless $file=~/^(?<dist>.*)\.(?<type>dump|bad)$/;
        my $dist=$+{dist};
        my $type=$+{type};
        $dist=~s/$datadir//;

        my $VAR1;
        eval $file->slurp;
        my $data=$VAR1;
        foreach my $report (@$data) {
            if ($report->{value}) {
                push(@{$cool_dists{$dist}},$report);
                push(@{$cool_rvs{$report->{value}}},$report);
            }
            else {
                push(@{$bad_dists{$report->{PPI}}{$dist}},$report);
            }
        }
    }
     
    $self->gen_cool_dists(\%cool_dists); 
    
    $self->gen_bad_dists(\%bad_dists); 
    
}


sub gen_cool_dists {
    my ($self, $cool) = @_;

    my $out = Path::Class::Dir->new($self->out)->file('cool.html');
    my $fh = $out->openw;

    say $fh $self->_html_header;
    say $fh "<table>";
    foreach my $dist (sort keys %$cool) {
        say $fh $self->_html_cool_dist($dist,$cool->{$dist});
    }
    
    say $fh "</table>";
    say $fh $self->_html_footer;
    close $fh;

}

sub gen_bad_dists {
    my ($self, $dists) = @_;

    my $out = Path::Class::Dir->new($self->out)->file('bad.html');
    my $fh = $out->openw;

    say $fh $self->_html_header;
    
    my @bad = sort keys %$dists;
    say $fh "<ul>";
    foreach my $type (@bad) {
        say $fh "<li><a href='#$type'>$type</li>";
    }
    say $fh "</ul>";
    
    foreach my $type (sort keys %$dists) {
        say $fh "<h3><a name='$type'>$type</a></h3>\n<table>";
        foreach my $dist (sort keys %{$dists->{$type}}) {
           # say $fh 
           # $self->_html_dist($dist,$dists->{$type}{$dist},'bad');

        }
        say $fh "</table>";
       # say $type;
        #say $fh $self->_html_dist($dist,$dists->{$dist});
    }
    
    say $fh "<table>";
    say $fh "</table>";
    say $fh $self->_html_footer;
    close $fh;

}


sub _html_cool_dist {
    my ($self, $dist,$report) = @_;
    my $html;
    my $count = @$report;

    if ($count>1) {
        $html.="<tr><td colspan=2>".$self->_link_dist($dist)."</td></tr>";
    }

    foreach my $ele (@$report) {
        my $val=$ele->{'value'};
        $val=~s/>/&gt;/g;
        $val=~s/</&lt;/g;
       
        if ($count>1) {
            $html.="<tr><td class='package'>".$ele->{package}."</td>";
        }
        else {
            $html.="<tr><td colspan>".$self->_link_dist($dist)."</td>";
        }
        $html.="<td>".$val."</td>";
        $html.="</tr>\n";
    }
    return $html;

}

sub _link_dist {
    my ($self, $dist) = @_;
    return "<a href='http://search.cpan.org/dist/$dist'>$dist</a>";
}

sub _html_header {
    my $self = shift;

    return <<"EOHTMLHEAD";
<html>
<head><title>Acme::ReturnValue findings</title>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">
</head>

<body>
<h1>Acme::ReturnValue</h1>

<ul class="menu">
<li><a href="index.html">About</a></li>
<li><a href="cool.html">Cool return values</a></li>
<li><a href="by_returnvalue.html">By return value</a></li>
<li><a href="bad.html">Bad return values</a></li>
</ul>

EOHTMLHEAD
}

sub _html_footer {
    my $self = shift;
    my $now = $self->now;
    my $version = Acme::ReturnValue->VERSION;
    return <<"EOHTMLFOOT";
<div class="footer">
<p>Acme::ReturnValue: <a href="http://search.cpan.org/dist/Acme-ReturnValue">on CPAN</a> | <a href="http://domm.plix.at/talks/acme_returnvalue.html">talks about it</a><br>
Contact: domm  AT cpan.org<br>
Generated: $now<br>
Version: $version<br>
</p>
</div>
</body></html>
EOHTMLFOOT
}


"let's generate another stupid website";

__END__


=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-returnvalue@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Thomas Klausner

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
