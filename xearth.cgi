#!/usr/bin/perl -wT
# -*- perl -*-

#
# $Id: xearth.cgi,v 1.3 2002/08/06 10:20:12 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2002 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven.rezic@berlin.de
# WWW:  http://www.rezic.de/eserte/
#

use strict;
use CGI qw(:standard);

$ENV{PATH} = "/usr/X11R6/bin:/usr/local/bin:/usr/bin:/bin";

my $pos    = param("pos") || "fixed,53,13";
my $width  = param("width") || 200;
my $height = param("height") || 200;

die "Dimensions too big" if $width > 2000 || $height > 1500;

my $pid = open(P, "-|");
if ($pid == 0) {
    exec('xearth', '-nolabel', '-nomarkers',
	 '-pos', $pos, '-size', "$width,$height", '-gif') or die $!;
}
$/ = undef;
$| = 1;
binmode STDOUT;
print header("image/gif");
print <P>;

