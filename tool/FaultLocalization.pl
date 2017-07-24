my $SchriptName = $0; 
$SchriptName =~ s|.*/||;

sub arguments {
	my $args = {
		key => ' ',
	};
	$args->{D} = ".";
	while (my $arg=shift(@ARGV)) {
		if ($arg =~ /^-h$/) { usage(); }
		if ($arg =~ /^-D$/) { $args->{D} = shift @ARGV; next; }
		if ($arg =~ /^-F$/) { $args->{F} = shift @ARGV; next; }
		if ($arg =~ /^-P$/) { $args->{P} = shift @ARGV; next; }
		if ($arg =~ /^-./) { print STDERR "Unknown option: $arg \n";usage();}
	}
	if ( ! ( $args->{F} ) ) {
		print STDERR "No Failing tests defined \n" ;
		usage();
	}
	$args;
}

sub usage {
	print STDERR
	"Usage:\t$SchriptName <options> file
	 Generate the fault localizaton results

	  -D <directory>        Project Directory (source code) 
	  -F <name>        	Failling Test Cases
	  -P <name> 		Passing Test Cases \n";
	exit -1;
}


my $args = arguments();

$D =  $args->{D};
$Ffilename = $args->{F};
$Pfilename = $args->{P};
system ("java ComputeMutantSuspiciousness $D $Ffilename $Pfilename");
