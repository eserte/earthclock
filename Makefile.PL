# -*- perl -*-
use ExtUtils::MakeMaker;

my $ver = MY->parse_version("earthclock");
#my $changes_file = parse_recent_changelog();

my %pm = map { ("lib/Earthclock/$_" => '$(INST_LIB)/Earthclock/' . $_) }
    ("Astro/Phoon.pm",
     "Astro/moon.png",
     "Astro/moon.xbm.gz",
     "Astro/moon.xpm.gz",
     "Date/Calendar.pm",
     "BBBikeAlarm.pm",
     "Tk/ICalEvent.pm",
     ($^O eq 'MSWin32' ? "Win32Util.pm" : ()),
    );

WriteMakefile
  (
   'NAME'	  => 'earthclock',
   'VERSION'      => $ver,
   'PM' => \%pm,
   'EXE_FILES' => ['earthclock'],
   'PREREQ_PM' => {'Tk'             => 800,
		   ($^O ne 'MSWin32' ? ('X11::Protocol' => 0) : ()),
		   'Tk::JPEG'       => 0,
		   'GD'             => 0,
		   # instead of GD one can use Imager, which creates nicer
		   # results
		   'LWP::UserAgent' => 0,
		   # These are really optional, but recommended:
		   'savevars'       => 0,
		   'GD::Convert'    => 2,
		   'enum'           => 0, # for BBBikeAlarm.pm
		   # "make test" does not pass with 5.8.0:
		   #'Net::ICal'      => 0, # for Tk::ICalEvent
		  },
   'ABSTRACT_FROM' => 'earthclock',
   'AUTHOR' => 'Slaven Rezic (slaven@rezic.de)',
  );

sub MY::libscan {
    my($self,$path) = @_;
    return '' if $path =~ m:\b(RCS|CVS|SCCS)\b: ;
    return '' if $path =~ m:\b(install\.pl)$: ;
    $path;
}

#  sub parse_recent_changelog {
#      my $q_ver = quotemeta($ver);
#      open(C, "Changes") or die $!;
#      my $gather = 0;
#      my $changes = "";
#      while(<C>) {
#  	if (/^$q_ver$/) {
#  	    $gather = 1;
#  	} elsif ($gather) {
#  	    if (/^($|\s)/) {
#  		$changes .= $_;
#  	    } else {
#  		$gather = 0;
#  	    }
#  	}
#      }
#      close C;
#      if ($changes eq '') {
#  	warn "No change log for version $ver found.\n";
#      }
#      my $changes_file = "Changes.current";
#      open(CO, "> $changes_file") or die "Can't write to $changes_file: $!";
#      print CO $changes;
#      close CO;
#      $changes_file;
#  }

sub MY::postamble {
    my $postamble = "";

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../perl.release.mk") {
	$postamble .= <<'EOF';

rsync-xearth.cgi:
	rsync -Pvzr xearth.cgi user.cs.tu-berlin.de:www/cgi/xearth.cgi

SF_PROJECT=ptktools
SF_PACKAGE=earthclock

.include "../perl.release.mk"
.include "../perl.cvs.mk"

bundle-files:
	cp -v $(HOME)/src/bbbike/BBBikeAlarm.pm $(HOME)/src/bbbike/lib/Win32Util.pm lib/Earthclock
EOF
    }

    $postamble;
}
