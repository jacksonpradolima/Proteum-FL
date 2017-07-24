my $SchriptName = $0; 
$SchriptName =~ s|.*/||;

sub arguments {
	my $args = {
		key => ' ',
	};
	$args->{params} = "";
	$args->{t} = "3";
	$args->{D} = ".";
	while (my $arg=shift(@ARGV)) {
		if ($arg =~ /^-h$/) { usage(); }
		if ($arg =~ /^-D$/) { $args->{D} = shift @ARGV; next; }
		if ($arg =~ /^-F$/) { $args->{F} = shift @ARGV; next; }
		if ($arg =~ /^-P$/) { $args->{P} = shift @ARGV; next; }
		if ($arg =~ /^-parms$/) { $args->{params} = shift @ARGV; next; }
		if ($arg =~ /^-t$/) { $args->{t} = shift @ARGV; next; }
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
	  Records the Execution traces of the failing and passing tests

	  -D <directory>        Project Directory (source code) 
	  -F <name>        	Failling Test Cases
	  -P <name>      	Passing Test Cases
	  -parms <args> 	gcc arguments 
	  -t <sec>        	execution timeout, default 3 sec \n";
	exit -1;
}


my $args = arguments();

$D = "$args->{D}/";
$Ffilename = $args->{F};
$Pfilename = $args->{P};
$sourcename = $args->{program};
$params = $args->{params};
$timeout = scalar $args->{t};
#--------------------------------------------------------------------------------------------------------------------
$OutputSize = 100000;
$exe = "instrum";
$Statement_matrix = "Statement_matrix.txt";
$filename = "$sourcename.c";
$gcda = "$sourcename.gcda";
#--------------------------------------------------------------------------------------------------------------------
chdir($D);

%ExecutableLines = ();
%TestLines = ();
@tests = ();
DetermineExecutableLines();

#read tests, first Failed test second Passed tests
open(TESTINPUT, "<$Ffilename") or die;
while(<TESTINPUT>) {
	my $test = trim($_);
	push(@tests, $test );
}
close(TESTINPUT);
open(TESTINPUT, "<$Pfilename") or die;
while(<TESTINPUT>) {
	my $test = trim($_);
	push(@tests, $test );
}
close(TESTINPUT);


#executes tests
$TestId = 0;
while( $TestId < @tests ) {
	my $test = $tests[$TestId];
	print "$test $TestId\n";
	executeTest("$test");
	analyzeGcov( $TestId );
	$TestId ++;
}

printMattrix();

#--------------------------------------------------------------------------------------------------------------------
sub executeTest( $ ){
	( $testcase )= @_;
	system("./doalarm $timeout ./$exe $testcase &> /dev/null");
#	open(ResultOutput, "./doalarm $timeout ./$exe $testcase; echo \$\?; |") or die;
#	my $original = "";my $kkk = 0;
#	while (  <ResultOutput> ){
#		$original = "$original".trim($_);
#		last if ($kkk++ == $OutputSize);
#	} 
#	close(ResultOutput);
}

sub DetermineExecutableLines (){
	system ("rm $gcda");
	system ("gcc $params -fprofile-arcs -ftest-coverage $filename -o instrum");
	system ("gcov $filename");
	open(INPUT, "<$filename.gcov") or die;
	while(<INPUT>) {#reads gcov file and determines the executable lines
	#only executable lines are going to be mutated
		$line = $_;
		$line = trim($line);
		my $Index = index ( $line, "#####:" );
		if ( $Index > -1 ){#executable line
			$Index += 6;
			my $lineNum = trim ( substr( $line, $Index, index ( $line, ":", $Index + 1 ) -  $Index ) );#executable lines
			@{ $ExecutableLines{$lineNum} } = ();
		}
	}
	close(INPUT);
}

sub analyzeGcov ( $ ){
	( $TestId )= @_;
	@{ $TestLines{$TestId} } = ();
	system ("gcov $filename");
	open(INPUT, "<$filename.gcov") or die;
	while(<INPUT>) {#reads gcov file and determines the lines that where executed
		$line = $_;
		$line = trim($line);
		my $Index1 = index ( $line, "#####:" );
		my $Index2 = index ( $line, "-:" );
		my $Index3 = index ( $line, "====:" );
		if ( ! ( $Index1 > -1 || $Index2 > -1 || $Index3 > -1 )  ){#the line was executed
			my $Index = index ( $line, ":" )+1; 
			my $lineNum = trim ( substr( $line, $Index, index ( $line, ":", $Index + 1 ) -  $Index ) );#executed line number
			push( @{ $ExecutableLines{$lineNum} }, $TestId );
			push( @{ $TestLines{$TestId} }, $lineNum );
		}
	}
	close(INPUT);
	system ("rm $gcda");
}

sub printMattrix ( ){
#print the statement Matrix
	open(OUTPUT, ">$Statement_matrix");
	my @ExecLines = keys (%ExecutableLines);
	for my $ttt (@ExecLines){
	    print OUTPUT "$ttt ";
	}print OUTPUT "\n";
	for(my $i = 0; $i < $TestId; $i++ ){
		my %currExec = map { $_ => 1 } @{ $TestLines{ $i } };#executed lines by the i test
		for my $ttt (@ExecLines){
			if ( exists( $currExec{$ttt} ) ){
				print OUTPUT "1 ";
			}
			else{
				print OUTPUT "0 ";	
			}
		}print OUTPUT "\n";
	}
	close(OUTPUT);
}

sub trim($)
{
	my $string = shift();
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

