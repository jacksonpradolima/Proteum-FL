my $SchriptName = $0; 
$SchriptName =~ s|.*/||;

sub arguments {
	my $args = {
		key => ' ',
	};
	$args->{D} = ".";
	$args->{op} = 1;
	while (my $arg=shift(@ARGV)) {
		if ($arg =~ /^-h$/) { usage(); }
		if ($arg =~ /^-D$/) { $args->{D} = shift @ARGV; next; }
		if ($arg =~ /^-All$/) { $args->{op} = 1; next; }
		if ($arg =~ /^-OpClass$/) { $args->{op} = 2; next; }
		if ($arg =~ /^-Selective$/) { $args->{op} = 3; next; }
		if ($arg =~ /^-./) { print STDERR "Unknown option: $arg \n";usage();}
		$arg =~ s/.c$//;
		$args->{program}=$arg;
	}
	if ( ! ( $args->{program} ) ) {
		print STDERR "No program defined \n" ;
		usage();
	}
	$args;
}

sub usage {
	print STDERR
	"Usage:\t$SchriptName <options> file
	  Produces mutant descriptions

	  -D <directory>        Project Directory (source code) 
	  -All 			all unit level operators 
	  -OpClass		Operators class Set  	
	  -Selective 		Selective Set  \n";
	exit -1;
}

my $args = arguments();

$D =  "$args->{D}/";

$source = $args->{program};
$executable = $args->{program};
$operators = $args->{op};

$testName = "test";
$compilationComand = "\"gcc $source.c -o $executable\"";
################################################################################################################################
chdir($D);
system ("pteste -create -S $source -E $executable  -D $D -C $compilationComand -research $testName" );######
system ("pteste  -l -D $D $testName");######
print "li -D $D -P __$source $source  __$source";
system ("li -D $D -P __$source $source  __$source" );
system ("li -l -D $D __$source __$source" );
system ("tcase -create -D $D  $testName" );
system ("muta -create -D $D  $testName" );

#all unit level operators
if ($operators == 1 ){
system ("muta-gen -D $D -u-OAAA 100 0 -u-OAAN 100 0 -u-OABA 100 0 -u-OABN 100 0 -u-OAEA 100 0 -u-OALN 100 0 -u-OARN 100 0 -u-OASA 100 0 -u-OASN 100 0 -u-OBAA 100 0 -u-OBAN 100 0 -u-OBBA 100 0 -u-OBBN 100 0 -u-OBEA 100 0 -u-OBLN 100 0 -u-OBNG 100 0 -u-OBRN 100 0 -u-OBSA 100 0 -u-OBSN 100 0 -u-OCNG 100 0 -u-OCOR 100 0 -u-OEAA 100 0 -u-OEBA 100 0 -u-OESA 100 0 -u-Oido 100 0 -u-OIPM 100 0 -u-OLAN 100 0 -u-OLBN 100 0 -u-OLLN 100 0 -u-OLNG 100 0 -u-OLRN 100 0 -u-OLSN 100 0 -u-ORAN 100 0 -u-ORBN 100 0 -u-ORLN 100 0 -u-ORRN 100 0 -u-ORSN 100 0 -u-OSAA 100 0 -u-OSAN 100 0 -u-OSBA 100 0 -u-OSBN 100 0 -u-OSEA 100 0 -u-OSLN 100 0 -u-OSRN 100 0 -u-OSSA 100 0 -u-OSSN 100 0 $testName" );
system ("muta-gen -D $D -u-SBRC 100 0 -u-SBRn 100 0 -u-SCRB 100 0 -u-SCRn 100 0 -u-SDWD 100 0 -u-SGLR 100 0 -u-SMTC 100 0 -u-SMTT 100 0 -u-SMVB 100 0 -u-SRSR 100 0 -u-SSDL 100 0 -u-SSWM 100 0 -u-STRI 100 0 -u-STRP 100 0 -u-SWDD 100 0 $testName" );
system ("muta-gen -D $D -u-VDTR 100 0 -u-VGAR 100 0 -u-VGPR 100 0 -u-VGSR 100 0 -u-VGTR 100 0 -u-VLAR 100 0 -u-VLPR 100 0 -u-VLSR 100 0 -u-VLTR 100 0 -u-VSCR 100 0 -u-VTWD 100 0 $testName" );
system ("muta-gen -D $D -u-Cccr 100 0 -u-Ccsr 100 0 -u-CRCR 100 0 $testName" );
}

#Operators class Set
if ($operators == 2 ){
system ("muta-gen -D $D -u-OAAA 100 0 -u-OAAN 100 0 -u-OABA 100 0 -u-OABN 100 0 -u-OAEA 100 0 -u-OALN 100 0 -u-OARN 100 0 -u-OASA 100 0 -u-OASN 100 0 -u-OBAA 100 0 -u-OBAN 100 0 -u-OBBA 100 0 -u-OBBN 100 0 -u-OBEA 100 0 -u-OBLN 100 0 -u-OBNG 100 0 -u-OBRN 100 0 -u-OBSA 100 0 -u-OBSN 100 0 -u-OCNG 100 0 -u-OCOR 100 0 -u-OEAA 100 0 -u-OEBA 100 0 -u-OESA 100 0 -u-Oido 100 0 -u-OIPM 100 0 -u-OLAN 100 0 -u-OLBN 100 0 -u-OLLN 100 0 -u-OLNG 100 0 -u-OLRN 100 0 -u-OLSN 100 0 -u-ORAN 100 0 -u-ORBN 100 0 -u-ORLN 100 0 -u-ORRN 100 0 -u-ORSN 100 0 -u-OSAA 100 0 -u-OSAN 100 0 -u-OSBA 100 0 -u-OSBN 100 0 -u-OSEA 100 0 -u-OSLN 100 0 -u-OSRN 100 0 -u-OSSA 100 0 -u-OSSN 100 0 $testName" );
}

#selective Set
if ($operators == 3 ){
system ("muta-gen -D $D -u-Cccr 100 0 -u-OAAN 100 0 -u-OCNG 100 0 -u-Oido 100 0 -u-OLLN 100 0 -u-ORSN 100 0 -u-SSDL 100 0 -u-STRP 100 0 -u-VGSR 100 0 $testName" );
}
system ("muta -l  test > mutantDescription.txt");
