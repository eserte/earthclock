# -*- perl -*-

#
# $Id: ICalEvent.pm,v 1.1 2002/01/31 23:26:45 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2002 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven.rezic@berlin.de
# WWW:  http://www.rezic.de/eserte/
#

package Tk::IcalEvent;
use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

use base qw(Tk::Frame);
Construct Tk::Widget 'IcalEvent';

use Net::ICal;

sub Populate {
    my($w, $args) = @_;
    $w->SUPER::Populate($args);

    $w->Component(Label => "Title")->pack;
    $w->Component(Text => "Text", -scrollbars => "oe",
		  -width => 40, -height => 5)->pack(-fill => "both",
						    -expand => 1);
    my $f = $w->Frame->pack(-fill => "x");
    # XXX use callbacks with these as default functions:
    $f->Button(-text => "OK",
	       -command => sub {
		   return unless $w->{Current};
		   $w->save_all;
		   $w->withdraw;
	       })->pack(-side => "left");
    $f->Button(-text => "Delete",
	       -comannd => sub {
		   return unless $w->{Current};
		   $w->delete_current;
		   $w->withdraw;
	       })->pack(-side => "left");
    $f->Button(-text => "Cancel",
	       -command => sub {
		   $w->unset;
		   $w->withdraw;
	       })->pack(-side => "left");

    $w->ConfigSpecs
      (-icalfile => ['METHOD', undef, undef, undef],
      );
}

sub icalfile {
    my $w = shift;
    if (@_) {
	$w->{ICalFile} = $_[0];

	open CALFILE, "< $w->{ICalFile}" or die "Can't load file: $!";
        undef $/; # slurp mode
        # FIXME: this is currently returning "not a valid ical stream"
        # from data saved out by the program itself. 
        $w->{ICal} = Net::ICal::Component->new_from_ical(<CALFILE>);
        close CALFILE;
    }
    $w->{ICalFile};
}

sub set_date {
    my($w,$y,$m,$d) = @_;

    $w->unset;

    my $date = sprintf "%04d%02d%02d", $y, $m, $d;

    my @events = @{ $w->{ICal}->events };
    for (@events) {
	if ($_->dtstart =~ /^$date/) {
	    $w->{Current} = $_;
	    last;
	}
    }
    if (!$w->{Current}) {
	$w->{Current} = new Net::ICal::Event
	    dtstart => Net::ICal::Item->new($date),
	    ;
	# XXX hackish...!
	push @events, $w->{Current};
	$w->{ICal} = new Net::ICal::Calendar events => \@events;
    }

    $w->Subwidget("Title")->configure(-text => $w->{Current}->dtstart);
    $w->Subwidget("Text")->insert(0, $w->{Current}->comment);

    $w->deiconify;
    $w->raise;
}

sub save_all {
    my($w) = @_;

    return if !defined $w->{ICalFile};

    open CALFILE, "> $w->{ICalFile}" or die "Can't save file: $!";
    print CALFILE $w->{ICal}->as_ical;
    close CALFILE;
}

sub unset {
    my $w = shift;
    delete $w->{Current};
    $w->Subwidget("Title")->configure(-text => "");
    $w->Subwidget("Text")->delete(0, "end");
}

1;

__END__
