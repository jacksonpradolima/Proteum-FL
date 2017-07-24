my $SchriptName = $0; 
$SchriptName =~ s|.*/||;

sub arguments {
	my $args = {
		key => ' ',
	};
	$args->{params} = "";
	$args->{D} = ".";
	while (my $arg=shift(@ARGV)) {
		if ($arg =~ /^-h$/) { usage(); }
		if ($arg =~ /^-D$/) { $args->{D} = shift @ARGV; next; }
		if ($arg =~ /^-F$/) { $args->{F} = shift @ARGV; next; }
		if ($arg =~ /^-parms$/) { $args->{params} = shift @ARGV; next; }
		if ($arg =~ /^-./) { print STDERR "Unknown option: $arg \n";usage();}
		#$arg =~ s/.c$//;
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
	  Generates and Compiles the mutants

	  -D <directory>        Project Directory (source code) 
	  -F <name>        	Failling Test Cases
	  -parms <args> 	gcc arguments \n";
	exit -1;
}


my $args = arguments();

$D =  "$args->{D}/";
$Ffilename = $args->{F};
$params = $args->{params};
$filename = $args->{program};

#--------------------------------------------------------------
$mutdesc = "mutantDescription.txt";
$outputFolder = "mutants";
$NoCompile = "Notcompiled";
$MutantLines = "MutantLines";
$MutantLinesAll = "MutantLinesAll";
$Statement_matrix = "Statement_matrix.txt";
$gcda = "$sourcename.gcda";
%TestLines = ();#statement map
#--------------------------------------------------------------#Reads gcov file and determines the executable lines
%LinesMutants = ();
%LinesMutantsAll = ();
%ExecutableMutants = ();
system ("mkdir $D"."$outputFolder");
system ("cp proteum.h $D"."$outputFolder/");
chdir($D);


ReadStatementMap();
DetermineExecutableLines();

#determines the failed test cases
my $ii = 0;
#assumes that the Statement_matrix is built by executing the failed tests first
open(TESTINPUT, "<$Ffilename") or die;
while(<TESTINPUT>) {
	$_;
	push(@FTests, $ii );
	$ii++;
}
close(TESTINPUT);


#determines the intersection of the failed test cases
my %original = ();
my @isect = ();
my $ii = 0;
map { $original{$_} = 1 } @{$TestLines{$FTests[$ii]}};$ii++;
for($ii = 1; $ii < @FTests; $ii++ ) {
	my $currtest = $FTests[$ii];
	@isect = grep { $original{$_} } @{$TestLines{$currtest}};
	%original = ();
	map { $original{$_} = 1 } @isect;
}

#--------------------------------Read Mutant Description and initialize mutants
@offset=();@chars=();@MUTANTSTATEMENT=();
@offset2=();@chars2=();@MUTANTSTATEMENT2=();
open(INPUT, "<$mutdesc") or die;
$MutantNUM=0;
$i = ""; $flag = 0;
while(<INPUT>) {
	$line = $_;
	$line = trim($line);#print(index ( $line, "Operator:" )." ");
	if ( index ( $line, "Offset:" ) > -1 && $flag == 1 ){
		$offset2[$i] = trim (substr( $line, 8, index ( $line, "," ) - 8 ));
		$chars2[$i] = trim (substr( $line, index ( $line, "out" ) + 4 , index ( $line, "characters" ) - index ( $line, "out" ) - 4 ));
		$flag = 2;
	}
	if ( index ( $line, "Offset:" ) > -1 && $flag == 0 ){
		$offset[$i] = trim (substr( $line, 8, index ( $line, "," ) - 8 ));
		$chars[$i] = trim (substr( $line, index ( $line, "out" ) + 4 , index ( $line, "characters" ) - index ( $line, "out" ) - 4 ));
		$flag = 1;
	}
	if ( index ( $line, "Get on:" ) > -1 && $flag == 2 ){
		if ( length($line) == 7 ){
			$MUTANTSTATEMENT2[$i] = " ";
		}
		else{
			$MUTANTSTATEMENT2[$i] = trim (substr( $line, 8, length($line) ));
		}
	}
	if ( index ( $line, "Get on:" ) > -1 && $flag == 1 ){
		if ( length($line) == 7 ){
			$MUTANTSTATEMENT[$i] = " ";
		}
		else{
			$MUTANTSTATEMENT[$i] = trim (substr( $line, 8, length($line) ));
		}
	}
	if ( index ( $line, "MUTANT #" ) > -1 ){
		$i = trim (substr( $line, 8, length($line) ));
		$flag = 0;
		$MutantNUM++;
	}
}
close(INPUT);
#---------------------------mutants creation-----------------------------------
open(OUTPUTLOG, ">$NoCompile") or die;
for ($count = 0; $count < $MutantNUM; $count++){
	open(INPUT, "<$filename") or die;
	$seek1 =  $offset[$count]-1;
	read INPUT, $first, $seek1;

	$CurrMutantLine = ( $first =~ tr/\n// );$CurrMutantLine ++;#line of mutant
	if ( exists( $LinesMutants{$CurrMutantLine} ) ){
	if ( exists ( $original{$CurrMutantLine} )  ){#ean einai executable line kai anikei sto intersection twn statements pou ginonte cover apo ta failed tests
		open(OUTPUT, ">>$outputFolder/muta".$count.".c") or die;
		print OUTPUT "#include \"proteum.h\" \n";#print "$outputFolder/muta".$count.".c";

		$chars1 = $chars[$count];
 		seek ( INPUT, $seek1 + $chars1, 0 );
		print OUTPUT " $first $MUTANTSTATEMENT[$count]";
		if ( exists ( $MUTANTSTATEMENT2[$count] ) ){
			#print "$count \n";
			$seek2 =  $offset2[$count]-1;
			$chars2 = $chars2[$count];
			$seek2 = $seek2 - $seek1 -$chars1;
			read INPUT, $second, $seek2; 
			#print "$second : $chars2 c \n";
			print OUTPUT " $second $MUTANTSTATEMENT2[$count]";
		}	

		while(<INPUT>) {
			$line = $_;
			print OUTPUT " $line";
		}
		close(OUTPUT);

		open (COMPPROB, "gcc -w $params $outputFolder/muta".$count.".c -o $outputFolder/muta".$count." |");
		$GGG = "";
		while (<COMPPROB>){
			$GGG = $GGG.$_;
		}	
		close (COMPPROB);
		if ( index ($GGG, " error:") != -1 ){
			#print ("kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk $count \n");
			print OUTPUTLOG "$count \n";
		}
		else{
			push( @{ $LinesMutants{$CurrMutantLine} }, "muta".$count );
			push( @{ $LinesMutantsAll{$CurrMutantLine} }, "muta".$count );
			@{ $ExecutableMutants{"muta".$count} } = ();
		}
	}
	else{
		push( @{ $LinesMutantsAll{$CurrMutantLine} }, "muta".$count );	
	}
	}
	close(INPUT);
}
close(OUTPUTLOG);

@key = sort {scalar( $LinesMutants{$a} ) <=> scalar ( $LinesMutants{$b} ) } keys (%LinesMutants);
open(OUTPUT, ">$MutantLines") or die;
for $ttt ( @key ) {
    print OUTPUT "$ttt: @{ $LinesMutants{$ttt} }\n";
}
close(OUTPUT);

@key = sort {scalar( $LinesMutantsAll{$a} ) <=> scalar ( $LinesMutantsAll{$b} ) } keys (%LinesMutantsAll);
open(OUTPUT, ">$MutantLinesAll") or die;
for $ttt ( @key ) {
    print OUTPUT "$ttt: @{ $LinesMutantsAll{$ttt} }\n";
}
close(OUTPUT);
exit();

sub trim($)
{
	my $string = shift();
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
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
			@{ $LinesMutants{$lineNum} } = ();
			@{ $LinesMutantsAll{$lineNum} } = ();
		}
	}
	close(INPUT);
}


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

