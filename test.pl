#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: test.pl,v 1.1 2002/02/22 19:33:57 eserte Exp $
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "# tests only work with installed Test module\n";
	print "1..1\n";
	print "ok 1\n";
	exit;
    }
}

BEGIN { plan tests => 1 }

system("$^X -Mblib blib/scripts/earthclock &");
ok(1);

__END__
