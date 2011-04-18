#!/usr/bin/perl

# The Ur symbol.  Everything starts here.
%pools;


sub parse_conf() {
  my $conf = shift;

  open(CONFFILE, "<", $conf) or die "I can't open the config file you gave me";

  while(<CONFFILE>) {
    my $line = $_;

    # clean up the input stream a bit...
    $line =~ s/#.*$//;            # comments
    if($line =~ /^ *$/) { next; } # whitespace only

	# pools are where everything starts...  Therefore, the first thing we do
	# is pull the 'POOL' lines out and populate the %pools hash...  all other operations
	# have a 'tag' argument (2nd field) that ties that operation to its pool.
    # POOL:label:user:pass
    if($line =~ /^POOL:~:(.*):~:(.*):~:(.*):~:$/) {
#      print "P - $1 - $2 - $3\n";
      my ($label, $user, $pass) = ($1, $2, $3);

      # these null array references anchor their respective lists of
      # objects (but not _those_ kind of objects...*g*).
      my $befores_aref   = [];
      my $afters_aref    = [];
      my $commands_aref  = [];
      my $targets_aref   = [];

      my @pool_attr = ($user, $pass, $targets_aref, $befores_aref, $afters_aref, $commands_aref);

      $pools{ $label } = \@pool_attr;
    }

    # COMMAND:pool:command:when:clean:
    elsif($line =~ /^COMMAND:~:(.*):~:(.*):~:(.*):~:(.*):~:$/) {
#      print "C - $1 - $2 - $3 - $4\n";
      my ($label, $command, $epoch, $clean) = ($1, $2, $3, $4);

      # If it's the 'ALL' pool or it's attached to a pool we've seen,
      # push it into the struct... otherwise, this is a script typo
      # and we die.
      if($label =~ /ALL/) {
        foreach my $pool (keys %pools) {   
          my $cmd_aref = $pools{ $pool }[5];
          push(@$cmd_aref, $command);
          $num_cmds = scalar @{$cmd_aref};
        } 
      } elsif(exists $pools{$label}) {     # Have we seen this pool name?
        my $cmd_aref = $pools{ $label }[5];
        push(@$cmd_aref, $command);
        $num_cmds = scalar @{$cmd_aref};
      } else {                             # No.  No we have not.
        die "I found a command that's looking for a pool that isn't defined... abort."
      } 
    }

    # MEMBER:pool:hostname:
    elsif($line =~ /^MEMBER:(.*):~:(.*):~:$/) {
      my ($label, $hostname) = $1, $2;



    }

    # PUSH:pool:lpath:rpath:when:
    elsif($line =~ /^PUSH:(.*):~:(.*):~:(.*):~:(.*):~:$/) {

      my ($label, $command, $epoch, $clean) = ($1, $2, $3, $4);
    }

    # PULL:pool:lpath:rpath:when:
    elsif($line =~ /^PULL:(.*):~:(.*):~:(.*):~:(.*):~:$/) {
      my ($label, $command, $epoch, $clean) = ($1, $2, $3, $4);
    } else {
      print "I didn't recognize this line: $line"
    }
  }
}

sub dump_struct() {
  while (my ($key, $value) = each(%pools)) {
      my $cmd_list_aref = $$value[5];
      print "I'm seeing " . scalar @$cmd_list_aref . " commands for pool $key:\n";
      foreach(@$cmd_list_aref) { print "  command for pool $key: " . $_ . "\n"; }
#      print "dump: $qarray_ref => " . scalar @$qarray_ref . "\n";
      print "\n";
  }
}


# ************ Main here *************************
@ARGV == 1 or die "You gotta gimme a config file to parse... you know this dude...\n";

($conf) = @ARGV;

&parse_conf($conf);

&dump_struct();
