#!/usr/bin/perl


@ARGV == 1 or die "I need an arg here..\n";

($conf) = @ARGV;
open(CONFFILE, "<", $conf) or die "I can't open the config file you gave me";

while(<CONFFILE>) {
  $line = $_;
  $line =~ s/#.*$//;
  if($line =~ /^ *$/) { next; }
# print $line;

  # POOL:label:user:pass
  if($line =~ /^POOL:(.*):(.*):(.*):$/) { 
    print "P - $1 - $2 - $3\n";
	my $label, $user, $pass;
	($label, $user, $pass) = $1,$2,$3;
	$pools{ $label } = \($user, $pass);

	while ( my ($key, $value) = each(%pools)) {
	  print "$key => $value\n";
	}
  }
  # COMMAND:pool:command:when:clean:
  elsif($line =~ /^COMMAND:(.*):(.*):(.*):(.*):$/) { 
#   print "C - $1 - $2 - $3 - $4\n";
  }
  # MEMBER:pool:hostname:
  elsif($line =~ /^MEMBER:(.*):(.*):$/) { 
#   print "M - $1 - $2\n";
  }
  # PUSH:pool:lpath:rpath:when:
  elsif($line =~ /^PUSH:(.*):(.*):(.*):(.*):$/) { 
#   print "H - $1 - $2 - $3 - $4\n";
  }
  # PULL:pool:lpath:rpath:when:
  elsif($line =~ /^PULL:(.*):(.*):(.*):(.*):$/) { 
#   print "L - $1 - $2 - $3 - $4\n";
  } else {
    print "I didn't recognize this line: $line\n"
  }
}

