#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: test.pl,v 1.2 2002/02/22 19:35:25 eserte Exp $
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

system("$^X -Mblib blib/script/earthclock &");
ok(1);

__END__
