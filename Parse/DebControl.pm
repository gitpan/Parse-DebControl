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
$VERSION = '1.2';

@ISA=qw(Exporter);
@EXPORT=qw/new parse_file parse_mem write_file write_mem DEBUG/;

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
	my ($this, $filename, $options) = @_;
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
	
	return $this->_parseDataHandle($fh, $options);
};

sub parse_mem {
	my ($this, $data, $options) = @_;

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

	return $this->_parseDataHandle($IOS, $options);

};

sub write_file {
	my ($this, $filenameorhandle, $dataorarrayref, $options) = @_;

	unless($filenameorhandle)
	{
		$this->_dowarn("write_file failed because no filename or filehandle was given");
		return;
	}

	unless($dataorarrayref)
	{
		$this->_dowarn("write_file failed because no data was given");
		return;
	}

	my $handle = $this->_getValidHandle($filenameorhandle, $options);

	unless($handle)
	{
		$this->_dowarn("write_file failed because we couldn't negotiate a valid handle");
		return;
	}

	my $arrayref = $this->_makeArrayref($dataorarrayref);

	my $string = $this->_makeControl($arrayref);
	
	print $handle $string;
	close $handle;

	return length($string);
}

sub write_mem {
	my ($this, $dataorarrayref, $options) = @_;

	unless($dataorarrayref)
	{
		$this->_dowarn("write_mem failed because no data was given");
		return;
	}

	my $arrayref = $this->_makeArrayref($dataorarrayref);

	my $string = $this->_makeControl($arrayref);

	return $string;
}

sub DEBUG
{
        my($this, $verbose) = @_;
        $verbose = 1 unless(defined($verbose) and int($verbose) == 0);
        $this->{_verbose} = $verbose;
        return;

}

sub _getValidHandle {
	my($this, $filenameorhandle, $options) = @_;

	if(ref $filenameorhandle eq "GLOB")
	{
		unless($filenameorhandle->opened())
		{
			$this->_dowarn("Can't get a valid filehandle to write to, because that is closed");
			return;
		}

		return $filenameorhandle;
	}else
	{
		my $openmode = ">>";
		$openmode=">" if $options->{clobberFile};
		$openmode=">>" if $options->{appendFile};

		my $handle;

		unless(open $handle,"$openmode$filenameorhandle")
		{
			$this->_dowarn("Couldn't open file: $openmode$filenameorhandle for writing");
			return;
		}

		return $handle;
	}
}

sub _makeArrayref {
	my ($this, $dataorarrayref) = @_;

        if(ref $dataorarrayref eq "ARRAY")
        {
		return $dataorarrayref;
        }else{
		return [$dataorarrayref];
	}
}

sub _makeControl
{
	my ($this, $dataorarrayref) = @_;
	
	my $str;

	foreach my $stanza(@$dataorarrayref)
	{
		foreach my $key(keys %$stanza)
		{
			my @lines = split("\n", $stanza->{$key});
			$str.="$key\: ".(shift @lines)."\n";

			foreach(@lines)
			{
				if($_ eq "")
				{
					$str.=" .\n";
				}
				else{
					$str.=" $_\n";
				}
			}

		}

		$str.="\n";
	}

	chomp($str);
	return $str;
	
}

sub _parseDataHandle
{
	my ($this, $handle, $options) = @_;

	my $structs;

	unless($handle)
	{
		$this->_dowarn("_parseDataHandle failed because no handle was given. This is likely a bug in the module");
		return;
	}

	my $data = $this->_getReadyHash($options);

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
				my $key = $1;
				my $value = $2;

				if($options->{discardCase})
				{
					$key = lc($key);					
				}

				$data->{$key} = $value;
				$lastfield = $key;
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
			$data = $this->_getReadyHash($options);
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

sub _getReadyHash
{
	my ($this, $options) = @_;
	my $data;

	if($options->{useTieIxHash})
	{
		eval("use Tie::IxHash");
		if($@)
		{
			$this->_dowarn("Can't use Tie::IxHash. You need to install it to have this functionality");
			return;
		}
		tie(%$data, "Tie::IxHash");
		return $data;
	}

	return {};
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

	$data = $parser->parse_mem($control_data, %options);
	$data = $parser->parse_file('./debian/control', %options);

	$writer = new Parse::DebControl;

	$string = $writer->write_mem($singlestanza);
	$string = $writer->write_mem([$stanza1, $stanza2]);

	$writer->write_file($filename, $singlestanza, %options);
	$writer->write_file($filename, [$stanza1, $stanza2], %options);

	$writer->write_file($handle, $singlestanza, %options);
	$writer->write_file($handle, [$stanza1, $stanza2], %options);

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

=item * C<parse_file($control_filename,I<%options>)>

Takes a scalar containing formatted data. Will parse as much as it can, 
warning (if C<DEBUG>ing is turned on) on parsing errors. 

Returns an array of hashes, containing the data in the control file, split up
by stanza.  Stanzas are deliniated by newlines, and multi-line fields are
expressed as such post-parsing.  Single periods are treated as special extra
newline deliniators, per convention.

The options hash can take parameters as follows. Setting the string to true
enables the option.

	useTieIxHash - Instead of an array of regular hashes, uses Tie::IxHash-
		based hashes
	discardCase  - Remove all case items from keys (not values)		

=back

=over 4

=item * C<parse_mem($control_data, I<%options>)>

Similar to C<parse_file>, except takes data as a scalar. Returns the same
array of hashrefs as C<parse_file>. The options hash is the same as 
C<parse_file> as well; see above.

=back

=over 4

=item * C<write_file($filename, $data, I<%options>)>

=item * C<write_file($handle, $data>

=item * C<write_file($filename, [$data1, $data2, $data3], I<%options>)>

=item * C<write_file($handle, [$data, $data2, $data3])>

This function takes a filename or a handle and writes the data out.  The 
data can be given as a single hash(ref) or as an arrayref of hash(ref)s. It
will then write it out in a format that it can parse. The order is dependant
on your hash sorting order. If you care, use Tie::IxHash.  Remember for 
reading back in, the module doesn't care.

The I<%options> hash can contain one of the following two items:

	appendFile  - (default) Write to the end of the file
	clobberFile - Overwrite the file given.

Since you determine the mode of your filehandle, passing it an options hash
obviously won't do anything; rather, it is ignored.

This function returns the number of bytes written to the file, undef 
otherwise.

=back

=over 4

=item * C<write_mem($data)>

=item * C<write_mem([$data1,$data2,$data3])>;

This function works similarly to the C<write_file> method, except it returns
the control structure as a scalar, instead of writing it to a file.  There
is no I<%options> for this file (yet);

=back

=over 4

=item * C<DEBUG()>

Turns on debugging. Calling it with no paramater or a true parameter turns
on verbose C<warn()>ings.  Calling it with a false parameter turns it off.
It is useful for nailing down any format or internal problems.

=back

=head1 CHANGES

=over 4

=item * B<Version 1.2> - April 24th, 2003

Fixed:

	* A bug in IxHash support where multiple stanzas
		might be out of order

=item * B<Version 1.1> - April 23rd, 2003

Added:

	* Writing support
	* Tie::IxHash support
	* Case insensitive reading support

=item * B<Version 1.0> - April 23rd, 2003

This is the initial public release for CPAN, so everything is new.

=back

=head1 BUGS

The module will let you parse otherwise illegal key-value pairs and pairs
with spaces. This is by design. In future versions, it may give you a warning.

=head1 TODO

=over 4

=item Handle line wrapping for long lines, maybe. 

	I'm debating whether or not this is outside the scope of this module

=back

=head1 COPYRIGHT

Parse::DebControl is copyright 2003 Jay Bonci E<lt>jaybonci@cpan.orgE<gt>.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
