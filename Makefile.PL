use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Parse::DebControl',
	'VERSION_FROM'	=> 'lib/Parse/DebControl.pm', # finds $VERSION
	'PREREQ_PM'	=>
		{ 
			'Test::More' => '0.45',
			'IO::Scalar' => '2.104',
			'Compress::Zlib' => '',
			'LWP::UserAgent' => '',
			'LWP::Simple' => '',
		},

	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(
			ABSTRACT_FROM	=> 'lib/Parse/DebControl.pm', # retrieve abstract from module
			AUTHOR     	=> 'Jay Bonci <jaybonci@cpan.org>') 
		: ()),
);



