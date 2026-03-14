#!/usr/bin/perl -wT
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2002,2026 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# WWW:  https://github.com/eserte/earthclock
#

use strict;
use File::Temp ();
use CGI qw(:standard);

$ENV{PATH} = "/usr/local/bin:/usr/bin:/bin";

my $pos    = param("pos") || "fixed,53,13";
my $width  = param("width") || 200;
my $height = param("height") || 200;

for my $paramref (\$width, \$height) {
    if ($$paramref =~ /^(\d+)$/) {
	$$paramref = $1;
    } else {
	die "Wrong width/height parameter '$$paramref'";
    }
}
die "Dimensions too big (max. 2000 x 1500).\n" if $width > 2000 || $height > 1500;

my($lat,$lon);
if ($pos =~ /^fixed,(.*),(.*)$/) {
    ($lat,$lon) = ($1,$2);
} else {
    die "pos parameter must be 'fixed,\$latitude,\$longitude'.\n";
}

my $tmp = File::Temp->new('xearth.cgi-XXXXXXXX', TMPDIR => 1, SUFFIX => '.png', UNLINK => 1);
my @cmd = (qw(xplanet -num_times 1 -latitude), $lat, qw(-longitude), $lon, qw(-geometry), $width.'x'.$height, qw(-output), "$tmp");
#warn "Running '@cmd'...\n";
system @cmd;
die "Command '@cmd' failed" if $? != 0 || !-s "$tmp";

$| = 1;
binmode STDOUT;
print "Content-Type: image/png\r\n\r\n";
local $/ = \4096;
while(<$tmp>) {
    print $_;
}
