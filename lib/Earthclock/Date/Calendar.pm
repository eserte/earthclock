# -*- perl -*-

#
# $Id: Calendar.pm,v 1.3 2002/04/12 21:00:37 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Date::Calendar;

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub cal {
    my($m,$y,%args) = @_;
    if (defined $args{-mondayfirst} && $args{-mondayfirst} eq 'auto') {
	my $locale = $ENV{LC_TIME} || $ENV{LC_ALL} || $ENV{LANG} || "C";
	if ($locale =~ /^de/) {
	    $args{-mondayfirst} = 1;
	} else {
	    $args{-mondayfirst} = 0;
	}
    }
    my @l = (0,0,0,1,$m-1,$y-1900);
    require Time::Local;
    my $wd = (localtime(Time::Local::timelocal(@l)))[6];
    my $days = month_days($m-1,$y-1900);

    my $col;

    if ($args{-mondayfirst}) {
	$wd = 7 if $wd == 0;
	$col = $wd-1;
    } else {
	$col = $wd;
    }

    my $s = "";

    require POSIX;
    my $mon = POSIX::strftime("%B", @l) . " " . $y;
    $s .= " "x(int((20-length($mon))/2)) . $mon. "\n";

    my @wkday;
    for (1 .. 7) {
	$l[3]=$_;
	my $wkday = (localtime(Time::Local::timelocal(@l)))[6];
	$wkday[$wkday] = POSIX::strftime("%a", @l);
    }

    $s .= join(" ", map { sprintf "%-2s", substr($wkday[$_],0,2) } $args{-mondayfirst} ? (1 .. 6, 0) : (0 .. 6)) . "\n";

    $s .= "  " if ($col > 0);
    $s .= "   "x($col-1) if ($col > 1);

    my $lines = 0;
    for my $day (1 .. $days) {
	$s .= " " if ($col > 0);
	$s .= sprintf "%2d", $day;
	if (++$col > 6) {
	    $s .= "\n";
	    $lines++;
	    $col=0;
	}
    }
    if ($col != 0) {
	$s .= "\n";
	$lines++;
    }

    # add lines to line up with other months
    for ($lines .. 5) {
	$s .= "\n";
    }

    $s;
}

sub month_days {
    my($m,$y) = @_;
    my $d = [31,28,31,30,31,30,31,31,30,31,30,31]->[$m];
    $d++ if $m == 1 && leapyear($y+1900);
    $d;
}

# REPO BEGIN
# REPO NAME leapyear /home/e/eserte/src/repository 
# REPO MD5 65650e87112f3e2453743c0400608702
sub leapyear {
    my $year = $_[0];
    ($year % 4 == 0 &&
     (($year % 100 != 0) || ($year % 400 == 0)));
}
# REPO END


1;

__END__
