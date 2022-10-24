package YAML::yq::Helper;

use 5.006;
use strict;
use warnings;
use YAML;
use File::Slurp qw (read_file write_file);

=head1 NAME

YAML::yq::Helper - Wrapper for yq for basic tasks so comments are preserved.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use YAML::yq::Helper;

    my $yq = YAML::yq::Helper->new(file='/etc/suricata/suricata-ids.yaml');


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new

Inits the object.

    - file :: The YAML file to operate on.

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $exists = `/bin/sh -c "which yq"`;
	if ( $? != 0 ) {
		die("yq not found in the path");
	}

	if ( !defined( $opts{file} ) ) {
		die('No file specified');
	}

	if ( !-e $opts{file} ) {
		die( '"' . $opts{file} . '" does not exist' );
	}

	if ( !-f $opts{file} ) {
		die( '"' . $opts{file} . '" is not a file' );
	}

	if ( !-r $opts{file} ) {
		die( '"' . $opts{file} . '" is not readable' );
	}

	my $self = {
		file   => $opts{file},
		qfile  => quotemeta( $opts{file} ),
		ensure => 0,
		ver    => undef,
	};
	bless $self;

	my $raw = read_file( $self->{file} );
	if ( $raw =~ /^\%YAML\ 1\.1/ ) {
		$self->{ensure} = 1;
		$self->{ver}    = '1.1';
	}
	elsif ( $raw =~ /^\%YAML\ 1\.1/ ) {
		$self->{ensure} = 1;
		$self->{ver}    = '1.2';
	}

	return $self;
}

=head2 clear_array

Clears the entries in a array, but does not delete the array.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->clear_array(var=>'rule-files');

=cut

sub clear_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	}
	elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( $self->is_array_clear( var => $opts{var} ) ) {
		return;
	}

	if ( $opts{var} !~ /\[\]$/ ) {
		$opts{var} = $opts{var} . '[]';
	}

	my $string = `yq -i "del $opts{var}" $self->{qfile}`;

	$self->ensure;
}

=head2 clear_hash

Clears the entries in a hash, but does not delete the hash.

Will die if called on a item that is not a hash.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->clear_hash(var=>'rule-files');

=cut

sub clear_hash {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	}
	elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( $self->is_hash_clear( var => $opts{var} ) ) {
		return;
	}

	if ( $opts{var} !~ /\[\]$/ ) {
		$opts{var} = $opts{var} . '[]';
	}

	my $string = `yq -i "del $opts{var}" $self->{qfile}`;

	$self->ensure;
}

=head2 delete_array

Deletes an array. If it is already undef, it will just return.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->delete_array(var=>'rule-files');

=cut

sub delete_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	}
	elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( !$self->is_defined( var => $opts{var} ) ) {
		return;
	}

	if ( !$self->is_array( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a array' );
	}

	if ( $opts{var} =~ /\[\]$/ ) {
		$opts{var} =~ s/\[\]$//;
	}

	my $string = `yq -i "del $opts{var}" $self->{qfile}`;

	$self->ensure;
}

=head2 delete_hash

Deletes an hash. If it is already undef, it will just return.

Will die if called on a item that is not a hash.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->delete_hash(var=>'rule-files');

=cut

sub delete_hash {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	}
	elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( !$self->is_defined( var => $opts{var} ) ) {
		return;
	}

	if ( !$self->is_hash( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a hash or is undef' );
	}

	if ( $opts{var} =~ /\[\]$/ ) {
		$opts{var} =~ s/\[\]$//;
	}

	my $string = `yq -i "del $opts{var}" $self->{qfile}`;

	$self->ensure;
}

=head2 ensure

Makes sure that the YAML file has the
version at the top.

    $yq->ensure;

=cut

sub ensure {
	my ($self) = @_;

	if ( !$self->{ensure} ) {
		return;
	}

	my $raw = read_file( $self->{file} );

	# starts
	if ( $raw =~ /^\%YANL/ ) {
		return;
	}

	# add dashes to the start of the raw if it is missing
	if ( $raw !~ /^\-\-\-\n/ ) {
		$raw = "---\n\n" . $raw;
	}

	# adds the yaml version
	$raw = '%YAML ' . $self->{ver} . "\n" . $raw;

	write_file( $self->{file}, $raw ) or die($@);

	return;
}

=head2 is_array

Checks if the specified variable in a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( $yq->is_array(var=>'rule-files') ){
        print "array...\n:";
    }

=cut

sub is_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	}
	elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;
	if ( $string =~ /\[\]/ ) {
		return 1;
	}
	elsif ( $string =~ /\{\}/ ) {
		return 0;
	}
	elsif ( $string eq "null\n" ) {
		return 0;
	}

	my $yaml;
	eval { $yaml = Load($string); };
	if ($@) {
		die($@);
	}

	if ( ref($yaml) eq 'ARRAY' ) {
		return 1;
	}

	return 0;
}

=head2 is_array_clear

Checks if a array is clear or not.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( $yq->is_array_clear(var=>'rule-files') ){
        print "clear...\n:";
    }

=cut

sub is_array_clear {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	}
	elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( !$self->is_array( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a array or is undef' );
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;
	if ( $string =~ /\[\]/ ) {
		return 1;
	}

	return 0;
}

=head2 is_defined

Checks if the specified variable is defined or not.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( $yq->is_defined('vars.address-groups') ){
        print "defined...\n:";
    }

=cut

sub is_defined {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	}
	elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;

	if ( $string eq "null\n" ) {
		return 0;
	}

	return 1;
}

=head2 is_hash

Checks if the specified variable in a hash.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( $yq->is_hash('vars.address-groups') ){
        print "hash...\n:";
    }

=cut

sub is_hash {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	}
	elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;

	if ( $string =~ /\[\]/ ) {
		return 0;
	}
	elsif ( $string =~ /\{\}/ ) {
		return 1;
	}	elsif ( $string eq "null\n" ) {
		return 0;
	}


	my $yaml = Load($string);

	if ( ref($yaml) eq 'HASH' ) {
		return 1;
	}

	return 0;
}

=head2 is_hash_clear

Checks if a hash is clear or not.

Will die if called on a item that is not a hash.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( $yq->is_hash_clear(var=>'rule-files') ){
        print "clear...\n:";
    }

=cut

sub is_hash_clear {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	}
	elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( !$self->is_hash( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a hash or is undef' );
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;
	if ( $string =~ /\{\}/ ) {
		return 1;
	}

	return 0;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yaml-yq-helper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=YAML-yq-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YAML::yq::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=YAML-yq-Helper>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/YAML-yq-Helper>

=item * Search CPAN

L<https://metacpan.org/release/YAML-yq-Helper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of YAML::yq::Helper
