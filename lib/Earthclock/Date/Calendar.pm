# -*- perl -*-

#
# $Id: Calendar.pm,v 1.2 2000/09/04 23:35:14 eserte Exp $
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

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use Date::Calc qw(Days_in_Month Day_of_Week Day_of_Week_Abbreviation);
use POSIX;

sub cal {
    my $month = shift;
    my $year = shift || (localtime[5])+1900;
    my $len = 7*2+6;
    my $r = "";

    my $monline = strftime("%B %Y", 0,0,0,1,$month-1,$year-1900);
    $r .= center_text($monline, $len) . "\n";

    my @weekdays;
    foreach my $day_i (6 .. 12) { # 2000-08-06 till 2000-08-12
	my $wday = POSIX::strftime("%A", 0,0,0,$day_i,8-1,2000-1900);
	if ($wday eq '' || $wday =~ /^\?/) {
	    $wday = Day_of_Week_Abbreviation( $day_i==6 ? 7 : $day_i-6 );
	}
	push @weekdays, substr($wday, 0, 2);
    }
    $r .= join(" ", @weekdays) . "\n";

    my $days_in_month = Days_in_Month($year, $month);
    my $line = " " x $len;
    for my $day (1 .. $days_in_month) {
	my $dow = Day_of_Week($year, $month, $day);
	$dow = 0 if $dow == 7;
	substr($line, $dow*3, 2) = sprintf "%2d", $day;
	if ($dow == 6 || $day == $days_in_month) {
	    $r .= $line . "\n";
	    $line = " " x $len;
	}
    }

    $r;
}

# REPO BEGIN
# REPO NAME center_text /home/e/eserte/src/repository 
# REPO MD5 e6f3ceeea93f1a9be85d64a712bbf009
=head2 center_text($text[, $linelength])

Center the text. $linelength is optional and defaults to 80 characters.

=cut

sub center_text {
    my $text = shift;
    my $linelength = shift || 80; # XXX get from "tput co"?
    my $spaces = ($linelength-length($text))/2;
    my $r = "";
    if ($spaces > 0) {
	$r = " " x $spaces;
    }
    $r . $text;
}
# REPO END

1;

__END__
