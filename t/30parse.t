#!/usr/bin/perl -w

use Test::More tests => 44;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';
}


my $mod = "Parse::DebControl";

#Object initialization - 2 tests

	use_ok($mod);
	ok($pdc = new Parse::DebControl(), "Parser object creation works fine");

#Object default failure - 2 tests

	ok(!$pdc->parse_mem(), "Parser should fail if not given a name");
	ok(!$pdc->parse_file(), "Parser should fail if not given a filename");

#Single item (no ending newline) parsing - 5 tests

	my $data;
	ok($data = $pdc->parse_mem("Description: foo"), "Parser for one-line returns valid data");
	ok(exists($data->[0]->{Description}), "...and the data exists");
	ok($data->[0]->{Description} eq "foo", "...and is the correct value");
	ok(@$data == 1, "...and there's only one stanza");
	ok(keys %{$data->[0]} == 1, "...and there's only item in the stanza");

#Multiple item (no ending newline) parsing - 6 tests

	ok($data = $pdc->parse_mem("Item: value1\nOtherItem : value2\nFinalItem:value3"), "Multiple items read in correctly");
	ok(@$data == 1, "...and there's only one stanza");
	ok(keys %{$data->[0]} == 3, "...and there are three items in the stanza");
	ok($data->[0]->{Item} eq "value1", "...and the first key is correct");
	ok($data->[0]->{OtherItem} eq "value2", "...and the second key is correct");
	ok($data->[0]->{FinalItem} eq "value3", "...and the third key is correct");

#Multiple Stanza (with ending newline) parsing - 9 tests
# These tests also make sure we strip off ending newlines

	ok($data = $pdc->parse_mem("Title: hello\nSection: unknown\n\nManifest: 12345.67890\nOther: value\nThreshold : unknown\n\n\n"), "Parses in a complex structure, and returns valid data");
	ok(@$data == 2, "...and there are two stanzas");
	ok(keys %{$data->[0]} == 2, "...and the first stanza is the right size");
	ok(keys %{$data->[1]} == 3, "...and the second stanza is the right size");
	ok($data->[0]->{Title} eq "hello", "First stanza: The first data piece is correct");
	ok($data->[0]->{Section} eq "unknown", "...and the second data piece");
	ok($data->[1]->{Manifest} eq "12345.67890", "Second stanza: and the (numeric) first data piece");
	ok($data->[1]->{Other} eq "value", "...and the second value");
	ok($data->[1]->{Threshold} eq "unknown", "...and the third value");

#Single Stanza (overflowline no ending newline) parsing - 4 tests
# Here we make sure multilines and period-only lines get stripped

	ok($data = $pdc->parse_mem("Description: Item1\n Hello\n	World\n .\n Again"), "Parse a complex multi-line, single-stanza structure");
	ok(@$data == 1, "...and there is one stanza");
	ok(keys %{$data->[0]} == 1, "...and the first stanza is the right size"); 
	ok($data->[0]->{Description} eq "Item1\nHello\nWorld\n\nAgain", "...and the data is correct");

#Single Stanza (Tie::IxHash test) - 6 tests

	SKIP: {
		eval { require Tie::IxHash };
		skip "Tie::IxHash is not installed", 6 if($@);

		ok($data = $pdc->parse_mem("Description: item\nCorona: GoodWithLime\nOther-Item: here\n\n", {'useTieIxHash' => 1}), "Parse a single stanza item with Tie::IxHash support");
		ok(@$data == 1, "...and there is one stanza");
		ok(keys %{$data->[0]} == 3, "...and the stanza is the right size");
		ok((keys %{$data->[0]})[0] eq "Description", "...and the order is right (first item)");
		ok((keys %{$data->[0]})[1] eq "Corona", "...and the order is right (second item)");
		ok((keys %{$data->[0]})[2] eq "Other-Item", "...and the order is right (third item)");
		
	}

#Single Stanza using caseDiscard - 6 tests

	ok($data = $pdc->parse_mem("Key1: value1\nKey2: value2\nKEY3: Value3", {'discardCase' => 1}), "Parse a simple structure with discardCase");
	ok(@$data == 1, "...and there is one stanza");
	ok(keys %{$data->[0]} == 3, "...and the stanza is the right size");
	ok((exists($data->[0]->{key1}) and $data->[0]->{key1} eq "value1"), "The first entry exists and has the right value");
	ok((exists($data->[0]->{key2}) and $data->[0]->{key2} eq "value2"), "...and the second value");
	ok((exists($data->[0]->{key3}) and $data->[0]->{key3} eq "Value3"), "...and the third value");

#Side conditions - 4 tests

	ok($data = $pdc->parse_mem("Key1:\nKey2: value2\nkey3: value3"), "Parse a simple structure with a bad (blank) value");
	ok(@$data == 1, "...and there is one stanza");
	ok(keys %{$data->[0]} == 3, "...and the stanza is the right size");
	ok($data->[0]->{Key1} eq "", "...and the blank key is correct");
