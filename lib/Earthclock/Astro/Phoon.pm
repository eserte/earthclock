# -*- perl -*-

#
# $Id: Phoon.pm,v 1.5 2000/08/30 00:36:50 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Phoon;

use Time::localtime;
use Math::Trig qw(tan pi deg2rad rad2deg atan);
use POSIX qw(floor);
use FindBin;

use strict;
use vars qw($VERSION);
$VERSION = "0.01";

# phase.c - routines to calculate the phase of the moon
#
# Adapted from "moontool.c" by John Walker, Release 2.0.
#

# Astronomical constants.

use constant EPOCH => 2444238.5;	# 1980 January 0.0

# Constants defining the Sun's apparent orbit.

use constant ELONGE => 278.833540;	# ecliptic longitude of the Sun
				        # at epoch 1980.0 
use constant ELONGP => 282.596403;	# ecliptic longitude of the Sun at
				        # perigee
use constant ECCENT => 0.016718;        # eccentricity of Earth's orbit
use constant SUNSMAX => 1.495985e8;     # semi-major axis of Earth's orbit, km
use constant SUNANGSIZ => 0.533128;     # sun's angular size, degrees, at
				        # semi-major axis distance

# Elements of the Moon's orbit, epoch 1980.0.

use constant MMLONG =>      64.975464;  # moon's mean lonigitude at the epoch
use constant MMLONGP =>     349.383063; # mean longitude of the perigee at the
				        # epoch
use constant MLNODE =>	    151.950429; # mean longitude of the node at the
				        # epoch
use constant MINC =>        5.145396;   # inclination of the Moon's orbit
use constant MECC =>        0.054900;   # eccentricity of the Moon's orbit
use constant MANGSIZ =>     0.5181;     # moon's angular size at distance a
				        # from Earth
use constant MSMAX =>       384401.0;   # semi-major axis of Moon's orbit in km
use constant MPARALLAX =>   0.9507;     # parallax at distance a from Earth
use constant SYNMONTH =>    29.53058868; # synodic month (new Moon to new Moon)
use constant LUNATBASE =>   2423436.0;  # base date for E. W. Brown's numbered
				        # series of lunations (1923 January 16)

# Properties of the Earth.

use constant EARTHRAD =>    6378.16;	# radius of Earth in kilometres


# Handy mathematical functions.

sub fixangle { $_[0] - 360 * (floor($_[0] / 360)) }         # fix angle
sub dsin     { sin(deg2rad($_[0])) }			  # sin from deg
sub dcos     { cos(deg2rad($_[0])) }			  # cos from deg


# jdate - convert internal GMT date and time to Julian day and fraction

sub jdate {
    my $t = shift;
    my $y = $t->year + 1900;
    my $m = $t->mon + 1;
    if ($m > 2) {
	$m = $m - 3;
    } else {
	$m = $m + 9;
	--$y;
    }
    my $c = $y / 100;		# compute century
    $y -= 100 * $c;
    $t->mday + ($c * 146097) / 4 + ($y * 1461) / 4 +
	($m * 153 + 2) / 5 + 1721119;
}

# jtime - convert internal date and time to astronomical Julian
#         time (i.e. Julian date plus day fraction, expressed as
#	  a double)
#

sub jtime {
    my $t = shift;
#XXX wie kriege ich die Zone + Sommerzeit raus?
#    my $c = -$t->zone;
#	if ( t->tw_flags & TW_DST )
#		c += 60;
    my $c = 0;
    (jdate($t) - 0.5) + 
	($t->sec + 60 * ($t->min + $c + 60 * $t->hour)) / 86400;
}

# jyear - convert Julian date to year, month, day, which are
#         returned via integer pointers to integers
#

sub jyear {
    my $td = shift;
    $td += 0.5;		   # astronomical to civil
    my $j = floor($td);
    $j = $j - 1721119;
    my $y = floor(((4 * $j) - 1) / 146097);
    $j = ($j * 4) - (1 + (146097 * $y));
    my $d = floor($j / 4);
    $j = floor(((4 * $d) + 3) / 1461);
    $d = ((4 * $d) + 3) - (1461 * $j);
    $d = floor(($d + 4) / 4);
    my $m = floor(((5 * $d) - 3) / 153);
    $d = (5 * $d) - (3 + (153 * $m));
    $d = floor(($d + 5) / 5);
    $y = (100 * $y) + $j;
    if ($m < 10.0) {
	$m = $m + 3;
    } else {
	$m = $m - 9;
	$y = $y + 1;
    }
    ($y, $m, $d);
}

# meanphase - calculates mean phase of the Moon for a given base date
#             and desired phase:
#	           0.0   New Moon
#		   0.25  First quarter
#		   0.5   Full moon
#		   0.75  Last quarter
#	      Beware!!!  This routine returns meaningless
#             results for any other phase arguments.  Don't
#	      ttempt to generalise it without understanding
#	      at the motion of the moon is far more complicated
#	      tt this calculation reveals.
#

sub meanphase {
    my($sdate, $phase) = @_;

    my($yy,$mm,$dd) = jyear($sdate);

    my $k = ($yy + (($mm - 1) * (1 / 12)) - 1900) * 12.3685;

    # Time in Julian centuries from 1900 January 0.5.
    my $t = ($sdate - 2415020) / 36525;
    my $t2 = $t * $t;		   # square for frequent use
    my $t3 = $t2 * $t;		   # cube for frequent use

    my $usek = $k = floor($k) + $phase;
    my $nt1 = 2415020.75933 + SYNMONTH * $k
	      + 0.0001178 * $t2
	      - 0.000000155 * $t3
	      + 0.00033 * dsin(166.56 + 132.87 * $t - 0.009173 * $t2);

    ($nt1, $usek);
}

#  truephase - given a K value used to determine the mean phase of the
#              new moon, and a phase selector (0.0, 0.25, 0.5, 0.75),
#              obtain the true, corrected phase time
#

sub truephase {
    my($k, $phase) = @_;

    my $apcor = 0;

    $k += $phase;		   # add phase to new moon time
    my $t = $k / 1236.85;	   # time in Julian centuries from
				   # 1900 January 0.5
    my $t2 = $t * $t;		   # square for frequent use
    my $t3 = $t2 * $t;		   # cube for frequent use
    my $pt = 2415020.75933	   # mean time of phase
	     + SYNMONTH * $k
	     + 0.0001178 * $t2
	     - 0.000000155 * $t3
	     + 0.00033 * dsin(166.56 + 132.87 * $t - 0.009173 * $t2);

    my $m = 359.2242               # Sun's mean anomaly
	    + 29.10535608 * $k
	    - 0.0000333 * $t2
	    - 0.00000347 * $t3;
    my $mprime = 306.0253          # Moon's mean anomaly
	         + 385.81691806 * $k
		 + 0.0107306 * $t2
		 + 0.00001236 * $t3;
    my $f = 21.2964                # Moon's argument of latitude
	    + 390.67050646 * $k
	    - 0.0016528 * $t2
	    - 0.00000239 * $t3;
    if (($phase < 0.01) || (abs($phase - 0.5) < 0.01)) {

	# Corrections for New and Full Moon.

	$pt +=     (0.1734 - 0.000393 * $t) * dsin($m)
		    + 0.0021 * dsin(2 * $m)
		    - 0.4068 * dsin($mprime)
		    + 0.0161 * dsin(2 * $mprime)
		    - 0.0004 * dsin(3 * $mprime)
		    + 0.0104 * dsin(2 * $f)
		    - 0.0051 * dsin($m + $mprime)
		    - 0.0074 * dsin($m - $mprime)
		    + 0.0004 * dsin(2 * $f + $m)
		    - 0.0004 * dsin(2 * $f - $m)
		    - 0.0006 * dsin(2 * $f + $mprime)
		    + 0.0010 * dsin(2 * $f - $mprime)
		    + 0.0005 * dsin($m + 2 * $mprime);
	$apcor = 1;
    } elsif ((abs($phase - 0.25) < 0.01 || (abs($phase - 0.75) < 0.01))) {
	$pt +=     (0.1721 - 0.0004 * $t) * dsin($m)
		    + 0.0021 * dsin(2 * $m)
		    - 0.6280 * dsin($mprime)
		    + 0.0089 * dsin(2 * $mprime)
		    - 0.0004 * dsin(3 * $mprime)
		    + 0.0079 * dsin(2 * $f)
		    - 0.0119 * dsin($m + $mprime)
		    - 0.0047 * dsin($m - $mprime)
		    + 0.0003 * dsin(2 * $f + $m)
		    - 0.0004 * dsin(2 * $f - $m)
		    - 0.0006 * dsin(2 * $f + $mprime)
		    + 0.0021 * dsin(2 * $f - $mprime)
		    + 0.0003 * dsin($m + 2 * $mprime)
		    + 0.0004 * dsin($m - 2 * $mprime)
		    - 0.0003 * dsin(2 * $m + $mprime);
	if ($phase < 0.5) {
	    # First quarter correction.
	    $pt += 0.0028 - 0.0004 * dcos($m) + 0.0003 * dcos($mprime);
	} else {
	    # Last quarter correction.
	    $pt += -0.0028 + 0.0004 * dcos($m) - 0.0003 * dcos($mprime);
	}
	$apcor = 1;
    }
    if (!$apcor) {
	die "truephase() called with invalid phase selector.\n";
    }
    $pt;
}

# phasehunt5 - find time of phases of the moon which surround the current
#                date.  Five phases are found, starting and ending with the
#                new moons which bound the current lunation
#

sub phasehunt5 {
    my $sdate = shift;

    my $adate = $sdate - 45;
    my($nt1, $k1) = meanphase($adate, 0);
    my($nt2, $k2);
    for ( ; ; ) {
	$adate += SYNMONTH;
	($nt2, $k2) = meanphase($adate, 0);
	last if ($nt1 <= $sdate && $nt2 > $sdate);
	$nt1 = $nt2;
	$k1 = $k2;
    }

    my @phases;
    $phases[0] = truephase($k1, 0.0);
    $phases[1] = truephase($k1, 0.25);
    $phases[2] = truephase($k1, 0.5);
    $phases[3] = truephase($k1, 0.75);
    $phases[4] = truephase($k2, 0.0);

    @phases;
}


# phasehunt2 - find time of phases of the moon which surround the current
#              date.  Two phases are found.
#

sub phasehunt2 {
    my $sdate = shift;

    my $adate = $sdate - 45;
    my($nt1, $k1) = meanphase($adate, 0.0);
    my($nt2, $k2);
    for ( ; ; ) {
	$adate += SYNMONTH;
	($nt2, $k2) = meanphase($adate, 0);
	last if ($nt1 <= $sdate && $nt2 > $sdate);
	$nt1 = $nt2;
	$k1 = $k2;
    }
    my(@phases, @which);

    $phases[0] = truephase($k1, 0.0);
    $which[0] = 0.0;
    $phases[1] = truephase($k1, 0.25);
    $which[1] = 0.25;
    if ( $phases[1] <= $sdate ) {
	$phases[0] = $phases[1];
	$which[0] = $which[1];
	$phases[1] = truephase($k1, 0.5);
	$which[1] = 0.5;
	if ( $phases[1] <= $sdate ) {
	    $phases[0] = $phases[1];
	    $which[0] = $which[1];
	    $phases[1] = truephase($k1, 0.75);
	    $which[1] = 0.75;
	    if ( $phases[1] <= $sdate ) {
		$phases[0] = $phases[1];
		$which[0] = $which[1];
		$phases[1] = truephase($k2, 0.0);
		$which[1] = 0.0;
	    }
	}
    }
    ('Phases' => \@phases,
     'Which'  => \@which);
}


# kepler - solve the equation of Kepler

sub kepler {
    my($m, $ecc) = @_;

    my $EPSILON = 1E-6;

    my $e = $m = deg2rad($m);
    my $delta;
    do {
	$delta = $e - $ecc * sin($e) - $m;
	$e -= $delta / (1 - $ecc * cos($e));
    } while (abs($delta) > $EPSILON);
    $e;
}

#  phase - calculate phase of moon as a fraction:
#
# 	The argument is the time for which the phase is requested,
# 	expressed as a Julian date and fraction.  Returns the terminator
# 	phase angle as a percentage of a full circle (i.e., 0 to 1),
# 	and stores into pointer arguments the illuminated fraction of
#       the Moon's disc, the Moon's age in days and fraction, the
# 	distance of the Moon from the centre of the Earth, and the
# 	angular diameter subtended by the Moon as seen by an observer
# 	at the centre of the Earth.
#

sub phase {
    my $pdate = shift;

    # Calculation of the Sun's position.

    my $Day = $pdate - EPOCH;			# date within epoch
    my $N = fixangle((360 / 365.2422) * $Day);	# mean anomaly of the Sun
    my $M = fixangle($N + ELONGE - ELONGP);     # convert from perigee
					        # co-ordinates to epoch 1980.0
    my $Ec = kepler($M, ECCENT);		# solve equation of Kepler
    $Ec = sqrt((1 + ECCENT) / (1 - ECCENT)) * tan($Ec / 2);
    $Ec = 2 * rad2deg(atan($Ec));		# true anomaly
    my $Lambdasun = fixangle($Ec + ELONGP);	# Sun's geocentric ecliptic
					        #  longitude
    # Orbital distance factor.
    my $F = ((1 + ECCENT * cos(deg2rad($Ec))) / (1 - ECCENT * ECCENT));
    my $SunDist = SUNSMAX / $F;			# distance to Sun in km
    my $SunAng = $F * SUNANGSIZ;		# Sun's angular size in degrees


    # Calculation of the Moon's position.

    # Moon's mean longitude.
    my $ml = fixangle(13.1763966 * $Day + MMLONG);

    # Moon's mean anomaly.
    my $MM = fixangle($ml - 0.1114041 * $Day - MMLONGP);

    # Evection.
    my $Ev = 1.2739 * sin(deg2rad(2 * ($ml - $Lambdasun) - $MM));

    # Annual equation.
    my $Ae = 0.1858 * sin(deg2rad($M));

    # Correction term.
    my $A3 = 0.37 * sin(deg2rad($M));

    # Corrected anomaly.
    my $MmP = $MM + $Ev - $Ae - $A3;

    # Correction for the equation of the centre.
    my $mEc = 6.2886 * sin(deg2rad($MmP));

    # Another correction term.
    my $A4 = 0.214 * sin(deg2rad(2 * $MmP));

    # Corrected longitude.
    my $lP = $ml + $Ev + $mEc - $Ae + $A4;

    # Variation.
    my $V = 0.6583 * sin(deg2rad(2 * ($lP - $Lambdasun)));

    # True longitude.
    my $lPP = $lP + $V;

    # Calculation of the phase of the Moon.

    # Age of the Moon in degrees.
    my $MoonAge = $lPP - $Lambdasun;

    # Phase of the Moon.
    my $MoonPhase = (1 - cos(deg2rad($MoonAge))) / 2;

    # Calculate distance of moon from the centre of the Earth.

    my $MoonDist = (MSMAX * (1 - MECC * MECC)) /
	(1 + MECC * cos(deg2rad($MmP + $mEc)));

    # Calculate Moon's angular diameter.

    my $MoonDFrac = $MoonDist / MSMAX;
    my $MoonAng = MANGSIZ / $MoonDFrac;

   ("MoonPhase" => $MoonPhase,        # illuminated fraction
    "MoonAge"   => SYNMONTH * (fixangle($MoonAge) / 360), # age of moon in days
    "Dist"    => $MoonDist,	   # distance in kilometres
    "MoonAng" => $MoonAng, 	   # angular diameter in degrees
    "SunDist" => $SunDist,	   # distance to Sun
    "SunAng"  => $SunAng,          # sun's angular diameter

    "AngRad" => deg2rad(fixangle($MoonAge)),
   );
}

sub tk_photo {
    my($top, %args) = @_;
    #my $angrad = phase($pdate);
    $args{-width}  = 100 unless defined $args{-width};
    $args{-height} = 100 unless defined $args{-height};

    my $imagefile;
    if ($args{-imagefile}) {
	$imagefile = $args{-imagefile};
    } else {
	$imagefile = "$FindBin::RealBin/moon.xbm.gz";
	if (!-r $imagefile) {
	    die "No imagefile found or given";
	}
    }

    my $cmd;
    if ($imagefile =~ /\.gz$/) {
	$cmd = "zcat $imagefile | xbmtopbm ";
    } else {
	$cmd = "xbmtopbm $imagefile ";
    }
    $cmd .= "| pnmscale -xsize $args{-width} -ysize $args{-height} " .
	    "| ppmtoxpm |";

    open(PBM, $cmd);
    local($/) = undef;
    my $buf = <PBM>;
    close PBM;
    my $p = $top->Photo(-data => $buf, -format => "xpm");
#warn $p->width;
    $p;
}

sub tk_shadow {
    my($c, $angle, $w, %args) = @_;

    $c->delete("shadow");

    my($a1, $a2) = ($w/2, 0);
    my $b2 = $w/2;
    my($c1, $c2) = ($w/2, $w);
    my $m2 = ($c2-$a2)/2+$a2;

    if ($angle < pi/2) {
	my $b1 = $w - ($w/2 * $angle/(pi/2));
	my $m1 = (sqr($a1)+sqr($a2-$b2)-sqr($b1))/(2*($a1-$b1));
	$c->createOval($b1-($b1-$m1)*2,$m2-($b1-$m1),$b1,$m2+($b1-$m1),
		       -fill => "black",
		       -outline => "black",
		       -tags => "shadow",
		       %args,
		      );
    } elsif ($angle < pi) {
	my $begin = ($w/2 * $angle/(pi/2));
	for(my $x = $begin; $x<=$w; $x++) {
	    my $b1 = $w-$x;
	    my $m1 = (sqr($a1)+sqr($a2-$b2)-sqr($x))/(2*($a1-$x));
	    $c->createArc($b1,$m2-($x-$m1),$b1+($x-$m1)*2,$m2+($x-$m1),
			  -fill=>"black",-outline=>"black",
			  -style => "arc",
			  -start => 90, -extent => 180,
			  -tags => "shadow",
			  %args,
			 );
	}
    } elsif ($angle < 3*pi/2) {
	my $begin = $w - ($w/2)*($angle - pi) * 2/pi;
	for(my $b1 = $begin; $b1<=$w; $b1++) {
	    my $x = $w-$b1;
	    my $m1 = (sqr($a1)+sqr($a2-$b2)-sqr($b1))/(2*($a1-$b1));
	    my @c=($b1-($b1-$m1)*2,$m2-($b1-$m1),$b1,$m2+($b1-$m1));
	    $c->createArc(@c,
			  -fill=>"black",-outline=>"black",
			  -style => "arc",
			  -start => -90, -extent => 180,
			  -tags => "shadow",
			  %args,
			 );
	}
    } else {
	my $x = ($angle-3/2*pi)/(1/2*pi) * $w/2 + $w/2;
	my $b1 = $w-$x;
	my $m1 = (sqr($a1)+sqr($a2-$b2)-sqr($x))/(2*($a1-$x));
	$c->createOval($b1,$m2-($x-$m1),$b1+($x-$m1)*2,$m2+($x-$m1),
		       -fill => "black",
		       -outline => "black",
		       -tags => "shadow",
		       %args,
		      );
    }
}

# REPO BEGIN
# REPO NAME sqr /home/e/eserte/src/repository 
# REPO MD5 16b84a0c96e6a73e14dccb674f78be75
=head2 sqr($n)

Return the square of $n.

=cut

sub sqr { $_[0] * $_[0] }
# REPO END


return 1 if caller();

__END__

use Tk;
my $top=tkinit;
my $cal = `cal`;
my $fixf = $top->fontCreate("fixed");
my $maxlen = 0;
my $lines = 0;
foreach(split(/\n/,$cal)) {
    $maxlen = length($_) if $maxlen < length($_);
    $lines++;
}

my $w = $top->fontMeasure($fixf, "x")*$maxlen;
my $h = $top->fontMetrics($fixf, -linespace)*$lines;
($w, $h) = (max($w,$h))x2;

warn "$w x $h";

my $p = Phoon::tk_photo($top,
			-width => $w, -height => $h);

my $c = $top->Canvas(-width => $w-1, -height => $h-1,
		     -highlightthickness => 0)->pack;
$c->createImage(0, 0, -image => $p, -anchor => "nw");
$c->createText($w/2, $w/2, -text => $cal, -anchor => "c",
	       -font => "fixed",-fill => "yellow",
	      -tags => "cal");

while(1) {
    for (my $t = time; $t <= time+86400*30; $t+=86400) {
	my $l = localtime($t);
	my %res = phase(jtime($l));
#	print ctime($t) . "=>" . $res{AngRad}, "\n";
	tk_shadow($c, $res{AngRad}, $w);
	$c->raise("cal");
	$c->tk_sleep(0.1);
    }
}

#  my $f;
#  for my $i (0 .. 27) {
#      if (!$f || $i % 5 == 0) {
#  	$f=$top->Frame->pack;
#      }
#      $f->Label(-image => $p)->pack(-side => "left");
#  }
#  #  my $f = $top->Canvas(-height => $h, -width => $w, -offset => ["sw"], -tile => $p,  -bg => "red")->pack(-expand => 1, -fill => "both");
MainLoop;

# REPO BEGIN
# REPO NAME max /home/e/eserte/src/repository 
# REPO MD5 6232837b4a9cf07258e364a03b0a89dc
=head2 max(...)

Return maximum value.

=cut

sub max {
    my $max = $_[0];
    foreach (@_[1..$#_]) {
	$max = $_ if $_ > $max;
    }
    $max;
}
# REPO END


# REPO BEGIN
# REPO NAME tk_sleep /home/e/eserte/src/repository 
# REPO MD5 a27d34cadcb4c0f321eae5ca04614005
=head2 tk_sleep

    $top->tk_sleep($s);

Sleep $s seconds (fractions are allowed). Use this method in Tk
programs rather than the blocking sleep function.

=cut

sub Tk::Widget::tk_sleep {
    my($top, $s) = @_;
    my $sleep_dummy = 0;
    $top->after($s*1000,
                sub { $sleep_dummy++ });
    $top->waitVariable(\$sleep_dummy)
	unless $sleep_dummy;
}
# REPO END

__END__
