package Parse::DebControl;

###########################################################
#       Parse::DebControl - Parse debian-style control
#		files (and other colon key-value fields)
#
#       Copyright 2003 - Jay Bonci <jaybonci@cpan.org>
#       Licensed under the same terms as perl itself
#
###########################################################

use strict;
use IO::Scalar;

use vars qw($VERSION @ISA @EXPORT);
$VERSION = '1.0';

@ISA=qw(Exporter);
@EXPORT=qw/new parse_file parse_mem DEBUG/;

sub new {
	my ($class, $debug) = @_;
	my $this = {};

	my $obj = bless $this, $class;
	if($debug)
	{
		$obj->DEBUG();
	}
	return $obj;
};

sub parse_file {
	my ($this, $filename) = @_;
	unless($filename)
	{
		$this->_dowarn("parse_file failed because no filename parameter was given");
		return;
	}	

	my $fh;
	unless(open($fh,"$filename"))
	{
		$this->_dowarn("parse_file failed because $filename could not be opened for reading");
		return;
	}
	
	return $this->_parseDataHandle($fh);
};

sub parse_mem {
	my ($this, $data) = @_;

	unless($data)
	{
		$this->_dowarn("parse_mem failed because no data was given");
		return;
	}

	my $IOS = new IO::Scalar \$data;

	unless($IOS)
	{
		$this->_dowarn("parse_mem failed because IO::Scalar creation failed.");
		return;
	}

	return $this->_parseDataHandle($IOS);

};

sub DEBUG
{
        my($this, $verbose) = @_;
        $verbose = 1 unless(defined($verbose) and int($verbose) == 0);
        $this->{_verbose} = $verbose;
        return;

}

sub _parseDataHandle
{
	my ($this, $handle) = @_;

	my $structs;

	unless($handle)
	{
		$this->_dowarn("_parseDataHandle failed because no handle was given. This is likely a bug in the module");
		return;
	}

	my $data;
	my $linenum = 0;
	my $lastfield = "";

	foreach my $line (<$handle>)
	{
		#Sometimes with IO::Scalar, lines may have a newline at the end
		chomp $line;
		$linenum++;
		if($line =~ /^[^\t\s]/)
		{
			#we have a valid key-value pair
			if($line =~ /(.*?)\s*\:\s*(.*)$/)
			{
				$data->{$1} = $2;
				$lastfield = $1;
			}else{
				$this->_dowarn("Parse error on line $linenum of data; invalid key/value stanza");
				return $structs;
			}

		}elsif($line =~ /^[\t\s](.*)/)
		{
			#appends to previous line

			unless($lastfield)
			{
				$this->_dowarn("Parse error on line $linenum of data; indented entry without previous line");
				return $structs;
			}
			if($1 eq ".")
			{
				$data->{$lastfield}.="\n";
			}else
			{
				$data->{$lastfield}.="\n$1";
			}

		}elsif($line =~ /^[\s\t]*$/){
			if(keys %$data > 0){
				push @$structs, $data;
			}
			$data = {};
			$lastfield = "";
		}else{
			$this->_dowarn("Parse error on line $linenum of data; unidentified line structure");
			return $structs;
		}

	}

	if(keys %$data > 0)
	{
		push @$structs, $data;
	}

	return $structs;
}

sub _dowarn
{
        my ($this, $warning) = @_;

        if($this->{_verbose})
        {
                warn "DEBUG: $warning";
        }

        return;
}


1;

__END__

=head1 NAME

Parse::DebControl - Easy OO parsing of debian control-like files

=head1 SYNOPSIS

	use Parse::DebControl

	$parser = new Parse::DebControl;

	$data = $parser->parse_mem($control_data);
	$data = $parser->parse_file('./debian/control');

	$parser->DEBUG();

=head1 DESCRIPTION

	Parse::DebControl is an easy OO way to parse debian control files and 
	other colon separated key-value pairs. It's specifically designed
	to handle the format used in Debian control files, template files, and
	the cache files used by dpkg.

	For basic format information see:
	http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-controlsyntax

	This module does not actually do any intelligence with the file content
	(because there are a lot of files in this format), but merely handles
	the format. It can handle simple control files, or files hundreds of lines 
	long efficiently and easily.

=head2 Class Methods

=over 4

=item * C<new()>

=item * C<new(I<$debug>)>

Returns a new Parse::DebControl object. If a true parameter I<$debug> is 
passed in, it turns on debugging, similar to a call to C<DEBUG()> (see below);

=back

=over 4

=item * C<parse_file($control_filename)>

Takes a scalar containing formatted data. Will parse as much as it can, 
warning (if C<DEBUG>ing is turned on) on parsing errors. 

Returns an array of hashes, containing the data in the control file, split up
by stanza.  Stanzas are deliniated by newlines, and multi-line fields are
expressed as such post-parsing.  Single periods are treated as special extra
newline deliniators, per convention.

=back

=over 4

=item * C<parse_mem($control_data)>

Similar to C<parse_file>, except takes data as a scalar. Returns the same
array of hashrefs;

=back

=over 4

=item * C<DEBUG()>

Turns on debugging. Calling it with no paramater or a true parameter turns
on verbose C<warn()>ings.  Calling it with a false parameter turns it off.
It is useful for nailing down any format or internal problems.

=back

=head1 CHANGES

=over 4

=item * B<Version 1.0> - April 23rd, 2003

This is the initial public release for CPAN, so everything is new.

=back

=head1 BUGS

None that I know of.  Please report any to jaybonci@cpan.org

=head1 TODO

=over 4

=item Tie::IxHash support

=item Control file writing (as compared to writing)

=item Case-insensitive hash construction

These items will be implemented as as an options hash to the parsing functions

=back

=head1 COPYRIGHT

Parse::DebControl is copyright 2003 Jay Bonci E<lt>jaybonci@cpan.orgE<gt>.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
