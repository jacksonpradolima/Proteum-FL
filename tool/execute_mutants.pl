my $SchriptName = $0; 
$SchriptName =~ s|.*/||;

sub arguments {
	my $args = {
		key => ' ',
	};
	$args->{params} = "";
	$args->{t} = "3";
	$args->{D} = ".";
	$args->{procs} = "4";
	while (my $arg=shift(@ARGV)) {
		if ($arg =~ /^-h$/) { usage(); }
		if ($arg =~ /^-D$/) { $args->{D} = shift @ARGV; next; }
		if ($arg =~ /^-F$/) { $args->{F} = shift @ARGV; next; }
		if ($arg =~ /^-P$/) { $args->{P} = shift @ARGV; next; }
		if ($arg =~ /^-parms$/) { $args->{params} = shift @ARGV; next; }
		if ($arg =~ /^-t$/) { $args->{t} = shift @ARGV; next; }
		if ($arg =~ /^-procs$/) { $args->{procs} = shift @ARGV; next; }
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
	  Executes the mutants

	  -D <directory>        Project Directory (source code) 
	  -F <name>        	Failling Test Cases
	  -P <name>      	Passing Test Cases
	  -parms <args> 	gcc arguments 
	  -t <sec>        	execution timeout, default 3 sec \n
	  -procs <Number>      	No of processes, default 4 sec \n";
	exit -1;
}


my $args = arguments();

$D = "$args->{D}/";
$Ffilename = $args->{F};
$Pfilename = $args->{P};
$sourcename = $args->{program};
$params = $args->{params};
$timeout = scalar $args->{t};
$NoProcs = scalar $args->{procs};

#--------------------------------------------------------------------------------------------------------------------
$folder = "mutants";
$OutputSize = 10000;
$orig = "original";
$MutantLines = "MutantLines";
$Mutant_matrix = "Mutant_matrix.txt";
$filename = "$sourcename.c";
$Statement_matrix = "Statement_matrix.txt";
$mutdesc = "mutantDescription.txt";
for ( my $i = 1; $i <= $NoProcs; $i++ ){
	push( @procs, $i );
}
#--------------------------------------------------------------------------------------------------------------------
chdir($D);
%TestLines = ();#statement map
%ExecutableMutants = ();#considered mutants determined by the FOM_LAST (intersection of all failed tests)
%LinesMutants = ();#Mutant per Line, for a given line which mutants belong
%KilledMutants = ();#Mutants killed by the failed test cases, used in removing the live mutants
system ("gcc $params $filename -o $orig");

ReadStatementMap();
MutantLines();

#reads the failed tests
@TestCases = ();
open(TESTINPUT, "<$Ffilename") or die;
while(<TESTINPUT>) {
	my $test = trim($_);
	push( @TestCases, "$test" );	
}
close(TESTINPUT);

my $start = time;

#executes the failed test cases
foreach my $proc (@procs) {
    my $pid;
    next if $pid = fork;    # Parent goes to next server.
    die "fork failed: $!" unless defined $pid;

    # From here on, we're in the child.  Do whatever the
    # child has to do...  The process we want to deal
    # with is in $proc.
	
	for( my $tmpTest = 0; $tmpTest < @TestCases; $tmpTest++ ) {
		if ( $tmpTest % @procs == $proc - 1 ){
			#print ("############################################ $TestCases[$tmpTest], $tmpTest");
			executemutants($TestCases[$tmpTest], $tmpTest, $proc);	
		}
	}
	exit;  # Ends the child process.
}

# The following waits until all child processes have
# finished, before allowing the parent to die.
1 while (wait() != -1);

RemoveLiveMutatns();

#reads the passed tests
@TestCases = ();
open(TESTINPUT, "<$Pfilename") or die;
while(<TESTINPUT>) {
	my $test = trim($_);
	push( @TestCases, "$test" );	
}
close(TESTINPUT);

#executes the passed test cases
foreach my $proc (@procs) {
    my $pid;
    next if $pid = fork;    # Parent goes to next server.
    die "fork failed: $!" unless defined $pid;

    # From here on, we're in the child.  Do whatever the
    # child has to do...  The process we want to deal
    # with is in $proc.
	
	for( my $tmpTest = 0; $tmpTest < @TestCases; $tmpTest++ ) {
		if ( $tmpTest % @procs == $proc - 1 ){
			#print ("############################################ $TestCases[$tmpTest], $tmpTest");
			executemutants($TestCases[$tmpTest], $tmpTest, $proc);	
		}
	}
	exit;  # Ends the child process.
}

# The following waits until all child processes have
# finished, before allowing the parent to die.
1 while (wait() != -1);


print "All done!\n";
my $duration = time - $start;
print "Execution time: $duration \n";

my $tmp = @procs;
printMattrix( $tmp );

#--------------------------------------------------------------------------------------------------------------------
sub executemutants( $ ){
	($testcase, $TestId, $ProcId) = @_;
	my @TestMutants = ();
	#execute original
	open(ResultOutput, "./doalarm $timeout ./$orig $testcase |") or die;
	my $original = "";$kkk = 0;
	while ( <ResultOutput> ){
		my $rrrr = $_;
		if ($kkk++ < $OutputSize){
			$original = "$original".trim($rrrr);
		}
	} 
	close(ResultOutput);

	#execute mutants
	my @CoveredLines = @{ $TestLines{$TestId} };
	my $currLine = (@CoveredLines)-1;
	#gia oles tis grames tou programmatos pou ginonte cover
	while ( $currLine >= 0 ) {
		my @LIVEmutants = @{ $LinesMutants{$CoveredLines[$currLine]} };
		my $i_test = (@LIVEmutants)-1;
		#gia olous tous mutants (@LIVEmutants) tis gramis $CoveredLines[$currLine]
		while ( $i_test >= 0 ) {
			my $currMut = $LIVEmutants[$i_test];
			#print  "./doalarm $timeout ./$folder"."/$currMut $testcase; echo \$\?; |";
			open(MUT, "./doalarm $timeout ./$folder"."/$currMut $testcase |") or die;
			my $result = "";$kkk = 0;
			while ( <MUT> ){
				my $rrrr = $_;
				if ($kkk++ < $OutputSize){
					$result = "$result".trim($rrrr);
				}
			} 
			if (!( $original eq $result )){	
				push( @TestMutants, $currMut );
			}
			close(MUT);
			$i_test--;
		}
		$currLine--;
	}

#prints the results of the current run
	open(OUTPUT, ">>$Mutant_matrix"."$ProcId");
	my @ExecMutants = keys (%ExecutableMutants);
	my %currExec = map { $_ => 1 } @TestMutants;#killed mutants by the i test
	for my $ttt (@ExecMutants){
		if ( exists( $currExec{$ttt} ) ){
			print OUTPUT "1 ";
		}
		else{
			print OUTPUT "0 ";	
		}
	}print OUTPUT "\n";
	close(OUTPUT);
}


sub printMattrix ( $ ){
#print the statement Matrix
	( $ProcNum ) = @_;
	open(OUTPUT, ">>$Mutant_matrix");
	my @ExecMutants= keys (%ExecutableMutants);
	
	@inputs = ();
	for(my $i = 1; $i <= $ProcNum; $i++ ){
		my $KK;
		open($KK, "<$Mutant_matrix"."$i") or die;
		push (@inputs, $KK);
	}

OUTER_LOOP:
	while (){
		for(my $i = 0; $i < $ProcNum; $i++ ){
			$in = $inputs[$i];
			$KK = <$in>;
			last OUTER_LOOP unless defined $KK;
			print OUTPUT "$KK";
		}
	}

	close(OUTPUT);
	for(my $i = 0; $i < $ProcNum; $i++ ){
		close($inputs[$i]);
	}
}

sub DetermineKilled ( ){
#print the statement Matrix
#determines the killed mutants by the failed tests and sums 
	my $ProcNum = @procs;
	open(OUTPUT, ">$Mutant_matrix");
	my @ExecMutants= keys (%ExecutableMutants);
	for my $ttt (@ExecMutants){
	    print OUTPUT "$ttt ";
	}print OUTPUT "\n";

	@inputs = ();
	for(my $i = 1; $i <= $ProcNum; $i++ ){
		my $KK;
		open($KK, "<$Mutant_matrix"."$i");
		push (@inputs, $KK);
	}

OUTER_LOOP:
	while (){
		for(my $i = 0; $i < $ProcNum; $i++ ){
			$in = $inputs[$i];
			$KK = <$in>;
			last OUTER_LOOP unless defined $KK;
			print OUTPUT "$KK";

			my $mutant_id = 0;
			my @values = split(' ', $KK);
	  		foreach my $val (@values) {
				if ( ! ( trim ( $val ) eq "" ) ){
					if ( trim ( $val ) eq "1"  ){
						@{ $KilledMutants{$ExecMutants[$mutant_id]} } = ();
					}
					$mutant_id++;
				}
	  		}
		}
	}
	close(OUTPUT);
	for(my $i = 0; $i < $ProcNum; $i++ ){
		close($inputs[$i]);
	}
	for(my $i = 1; $i <= $ProcNum; $i++ ){
		system( "mv $Mutant_matrix"."$i $Mutant_matrix"."$i"."a");
	}
}

sub trim($)
{
	my $string = shift();
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
#--------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------

sub ReadStatementMap ( ){# computes %TestLines
	open(INPUT, "<$Statement_matrix") or die;
	my $firstLine = <INPUT>;#read the first line of the killability matrix
	$firstLine = trim ($firstLine);
	my @Lines = ();
	$line_number = 0;
	my @values = split(' ', $firstLine);
	  foreach my $val (@values) {
		if ( ! ( trim ( $val ) eq "" ) ){
			$Lines[$line_number] = trim ($val);
			$line_number++;
		}
	  }
	my $testid = 0;
	while(<INPUT>) {
		chop;
	  	$line = $_;
		$TestLines{$testid} = ();
		my $line_id = 0;
		my @values = split(' ', $line);
	  	foreach my $val (@values) {
			if ( ! ( trim ( $val ) eq "" )  ){
				if ( trim ( $val ) eq "1"  ){
					push(@{$TestLines{$testid}}, $Lines[$line_id] );
				}
				$line_id++;
			}
	  	}
		$testid++;
	}
	close(INPUT);
}

sub MutantLines ( ){
	open(INPUT, "<$MutantLines") or die;
	while(<INPUT>) {
		chop;
	  	$line = $_;
		my $LineId = trim ( substr( $line, 0, index ( $line, ":" ) ) );
		my @values = split(' ',  substr( $line, index ( $line, ":" ) + 1 ) );
		foreach my $val (@values) {
			if ( ! ( trim ( $val ) eq "" ) ){
				push(@{$LinesMutants{$LineId}}, $val );
				@{ $ExecutableMutants{$val} } = ();
			}
	  	}
	}
	close(INPUT);
}

sub RemoveLiveMutatns( ) {
	DetermineKilled();
	my $removedMutants = 0;
	my @lines = keys (%LinesMutants);
	foreach my $lineId (@lines) {
		for (my $i = 0; $i < @{$LinesMutants{$lineId}}; $i ++ ) {
			my $Mutant = ${$LinesMutants{$lineId}}[$i];	
			if ( ! ( exists ( $KilledMutants{$Mutant} ) ) ){ 
				splice @{$LinesMutants{$lineId}}, $i, 1;
				$i--;
				$removedMutants++;
			}
		}
	}	
	print "Removed mutants = $removedMutants \n";
}

