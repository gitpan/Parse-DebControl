#!/usr/bin/perl -w

use Test::More tests => 10;
use Compress::Zlib;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';
}


my $mod = "Parse::DebControl";

#Object initialization - 2 tests

	use_ok($mod);
	ok($pdc = new Parse::DebControl(), "Parser object creation works fine");

SKIP: {
	skip "/tmp not available. Either not-unix or not standard unix", 8 unless(-d "/tmp");
	skip "/tmp not writable. Skipping write tests", 8 unless(-d "/tmp" and -w "/tmp");
	skip "Windows /tmp wierdness. No thanks", 8 if($^O =~ /Win32/);

	my $fh;
	my $file = "/tmp/pdc_testfile".int(rand(10000));

	ok($pdc->write_file($file, {"key1" => "value1", "key2" => "value2"}, {"clobberFile" => 1}), "File write is okay");
	ok(my $data = $pdc->parse_file($file), "...and re-parsing is correct");
	ok($data->[0]->{key1} eq "value1", "...and the first key is correct");
	ok($data->[0]->{key2} eq "value2", "...and the second key is correct");
	unlink $file;

	ok($pdc->write_file($file, {"key1" => "value3", "key2" => "value4"}, {"gzip" => 1, "clobberFile" => 1}), "Writing file with gzip is okay");
	ok($data = $pdc->parse_file($file, {tryGzip => 1}), "...and parsing the zipped file is correct");
	ok($data->[0]->{key1} eq "value3", "...and the first key is correct");
	ok($data->[0]->{key2} eq "value4", "...and the second key is correct");

	unlink $file;

};
