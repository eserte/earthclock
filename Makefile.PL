use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	  => 'earthclock',
   'VERSION_FROM' => 'earthclock', # finds $VERSION
   'PM' => {
	    'lib/Earthclock/Astro/Phoon.pm'    => '$(INST_LIB)/Earthclock/Astro/Phoon.pm',
	    'lib/Earthclock/Astro/moon.png'    => '$(INST_LIB)/Earthclock/Astro/moon.png',
	    'lib/Earthclock/Astro/moon.xbm.gz' => '$(INST_LIB)/Earthclock/Astro/moon.xbm.gz',
	    'lib/Earthclock/Astro/moon.xpm.gz' => '$(INST_LIB)/Earthclock/Astro/moon.xpm.gz',
	    'lib/Earthclock/Date/Calendar.pm'  => '$(INST_LIB)/Earthclock/Date/Calendar.pm',
	   },
   'EXE_FILES' => ['earthclock'],
   'PREREQ_PM' => {'Tk'             => undef,
		   'X11::Protocol'  => undef,
		   'Tk::JPEG'       => undef,
		   'GD'             => undef,
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
