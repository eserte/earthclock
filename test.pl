#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: test.pl,v 1.3 2004/04/27 21:07:16 eserte Exp $
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

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

system("$^X -Mblib blib/script/earthclock" . ($ENV{BATCH} ? " &" : ""));
ok(1);

__END__
