# -*- perl -*-

#
# $Id: ICalEvent.pm,v 1.2 2002/01/31 23:48:17 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2002 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven.rezic@berlin.de
# WWW:  http://www.rezic.de/eserte/
#

package Tk::ICalEvent;
use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use base qw(Tk::Frame);
Construct Tk::Widget 'ICalEvent';

use Net::ICal;

sub Populate {
    my($w, $args) = @_;
    $w->SUPER::Populate($args);

    $w->Component(Label => "Title")->pack;
    my $txt = $w->Scrolled("Text", -scrollbars => "oe",
			   -width => 40, -height => 5)->pack(-fill => "both",
							     -expand => 1);
    $w->Advertise(Text => $txt);

    my $f = $w->Frame->pack(-fill => "x");
    # XXX use callbacks with these as default functions:
    $f->Button(-text => "OK",
	       -command => sub {
		   return unless $w->{Current};
		   $w->save_all;
		   $w->toplevel->withdraw;
	       })->pack(-side => "left");
    $f->Button(-text => "Delete",
	       -command => sub {
		   return unless $w->{Current};
		   $w->delete_current;
		   $w->toplevel->withdraw;
	       })->pack(-side => "left");
    $f->Button(-text => "Cancel",
	       -command => sub {
		   $w->unset;
		   $w->toplevel->withdraw;
	       })->pack(-side => "left");

    $w->ConfigSpecs
      (-icalfile => ['METHOD', undef, undef, undef],
      );
}

sub icalfile {
    my $w = shift;
    if (@_) {
	$w->{ICalFile} = $_[0];

	if (open CALFILE, "< $w->{ICalFile}") {
	    undef $/; # slurp mode
	    # FIXME: this is currently returning "not a valid ical stream"
	    # from data saved out by the program itself. 
	    $w->{ICal} = Net::ICal::Component->new_from_ical(<CALFILE>);
	    close CALFILE;
	} else {
	    $w->{ICal} = new Net::ICal::Calendar events => [];
	}
    }
    $w->{ICalFile};
}

sub set_date {
    my($w,$y,$m,$d) = @_;

    $w->unset;

    my $date = sprintf "%04d%02d%02d", $y, $m, $d;

    my @events = @{ $w->{ICal}->events };
    for (@events) {
	if ($_->dtstart->as_ical =~ /^:?$date/) {
	    $w->{Current} = $_;
	    last;
	}
    }

    if (!$w->{Current}) {
	$w->{Current} = new Net::ICal::Event
	    dtstart => Net::ICal::Time->new(ical => $date),
	    ;
	# XXX hackish...!
	push @events, $w->{Current};
	$w->{ICal} = new Net::ICal::Calendar events => \@events;
    }

    $w->Subwidget("Title")->configure(-text => $w->{Current}->dtstart->as_ical);
    $w->Subwidget("Text")->insert("1.0", $w->{Current}->comment->{'content'})
	if $w->{Current}->comment;

    $w->toplevel->deiconify;
    $w->toplevel->raise;
}

sub save_all {
    my($w) = @_;

    return if !defined $w->{ICalFile};

    if ($w->{Current}) {
	$w->{Current}->comment($w->Subwidget("Text")->get("1.0", "end"));
    }

    open CALFILE, "> $w->{ICalFile}" or die "Can't save file: $!";
    print CALFILE $w->{ICal}->as_ical;
    close CALFILE;
}

sub unset {
    my $w = shift;
    delete $w->{Current};
    $w->Subwidget("Title")->configure(-text => "");
    $w->Subwidget("Text")->delete("1.0", "end");
}

1;

__END__
