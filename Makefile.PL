# -*- perl -*-
use ExtUtils::MakeMaker;

my $ver = MY->parse_version("earthclock");
#my $changes_file = parse_recent_changelog();

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	  => 'earthclock',
   'VERSION'      => $ver,
   'PM' => {
	    'lib/Earthclock/Astro/Phoon.pm'    => '$(INST_LIB)/Earthclock/Astro/Phoon.pm',
	    'lib/Earthclock/Astro/moon.png'    => '$(INST_LIB)/Earthclock/Astro/moon.png',
	    'lib/Earthclock/Astro/moon.xbm.gz' => '$(INST_LIB)/Earthclock/Astro/moon.xbm.gz',
	    'lib/Earthclock/Astro/moon.xpm.gz' => '$(INST_LIB)/Earthclock/Astro/moon.xpm.gz',
	    'lib/Earthclock/Date/Calendar.pm'  => '$(INST_LIB)/Earthclock/Date/Calendar.pm',
	   },
   'EXE_FILES' => ['earthclock'],
   'PREREQ_PM' => {'Tk'             => undef,
		   ($^O ne 'MSWin32' ? ('X11::Protocol' => undef) : ()),
		   'Tk::JPEG'       => undef,
		   'GD'             => undef,
		   # optional: GD::Convert
		   'LWP::UserAgent' => undef,
		  },
   'ABSTRACT_FROM' => 'earthclock',
   'AUTHOR' => 'Slaven Rezic (eserte@cs.tu-berlin.de)',
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
    <<EOF .

release:	dist
	../sf-upload/sf-upload -project ptktools -package earthclock -release \$(VERSION) -file \$(DISTVNAME).tar\$(SUFFIX) -notesfile README -changes ""

EOF
    # disabled:
    (0 && defined $ENV{USER} && $ENV{USER} eq 'eserte' ?
     <<EOF : "")
rsync-xearth.cgi:
	rsync -Pvzr xearth.cgi user.cs.tu-berlin.de:www/cgi/xearth.cgi

EOF
}
