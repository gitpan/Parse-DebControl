use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Parse::DebControl',
	'VERSION_FROM'	=> 'lib/Parse/DebControl.pm', # finds $VERSION
	'PREREQ_PM'	=>
		{ 
			'Test::More' => '0.45',
			'IO::Scalar' => '2.104',
		},

	'dist'		=> 
		{
			COMPRESS => 'gzip -9',
			SUFFIX   => '.gz',
			DIST_DEFAULT => 'all tardist',
		},

	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(
			ABSTRACT_FROM	=> 'lib/Parse/DebControl.pm', # retrieve abstract from module
			AUTHOR     	=> 'Jay Bonci <jaybonci@cpan.org>') 
		: ()),
);

