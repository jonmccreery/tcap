#!/usr/bin/perl

%pools;


@ARGV == 1 or die "You gotta gimme a config file to parse... you know this dude...\n";

($conf) = @ARGV;
open(CONFFILE, "<", $conf) or die "I can't open the config file you gave me";

while(<CONFFILE>) {
  my $line = $_;

  # clean up the input stream a bit...
  $line =~ s/#.*$//;
  if($line =~ /^ *$/) { next; }

  # POOL:label:user:pass
  if($line =~ /^POOL:~:(.*):~:(.*):~:(.*):~:$/) { 
#    print "P - $1 - $2 - $3\n";
	my ($label, $user, $pass) = ($1, $2, $3);

	my @before   = [];
	my @after    = [];
	my @commands = [];
	my @targets  = [];

	my @pool_attr = ($user, $pass, \@targets, \@before, \@after, \@commands);

	$pools{ $label } = \@pool_attr;
  }

  # COMMAND:pool:command:when:clean:
  elsif($line =~ /^COMMAND:~:(.*):~:(.*):~:(.*):~:(.*):~:$/) { 
#    print "C - $1 - $2 - $3 - $4\n";
	my ($label, $command, $epoch, $clean) = ($1, $2, $3, $4);

	if($label =~ /ALL/) {
	  foreach my $pool (keys %pools) {
	    my $cmd_array_ref = $pools{ $pool }[5];
		push(@$cmd_array_ref, $command);
	    $num_cmds = scalar @{$cmd_array_ref};
	  }
	} 
	elsif(exists $pools{$label}) {
	  my $cmd_array_ref = $pools{ $label }[5];
	  push(@$cmd_array_ref, $command);
	  $num_cmds = scalar @{$cmd_array_ref};
	}
  }

  # MEMBER:pool:hostname:
  elsif($line =~ /^MEMBER:(.*):~:(.*):~:$/) { 
    my ($label, $user, $pass) = $1, $2, $3;
  }

  # PUSH:pool:lpath:rpath:when:
  elsif($line =~ /^PUSH:(.*):~:(.*):~:(.*):~:(.*):~:$/) { 
  }

  # PULL:pool:lpath:rpath:when:
  elsif($line =~ /^PULL:(.*):~:(.*):~:(.*):~:(.*):~:$/) { 
  } else {
    print "I didn't recognize this line: $line\n"
  }


}

while (my ($key, $value) = each(%pools)) {
    my $pool_ref = $$value[5];
	print "I'm seeing " . scalar @$pool_ref . " commands for pool $key:\n";
	foreach(@$pool_ref) { print "  command for pool $key: " . $_ . "\n"; }
	print "\n";
#    print "dump: $key => $cmd\n";
}
