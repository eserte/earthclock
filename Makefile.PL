use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	  => 'earthclock',
   'VERSION_FROM' => 'earthclock', # finds $VERSION
   'PM' => {
	    'Astro/Phoon.pm'    => '$(INST_LIB)/Astro/Phoon.pm',
	    'Astro/moon.png'    => '$(INST_LIB)/Astro/moon.png',
	    'Astro/moon.xbm.gz' => '$(INST_LIB)/Astro/moon.xbm.gz',
	    'Astro/moon.xpm.gz' => '$(INST_LIB)/Astro/moon.xpm.gz',
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

