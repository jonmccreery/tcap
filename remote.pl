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
	# have a 'tag' argument (2nd field) that ties that operation to its pool.  We use
	# this to index into the %pools hash.
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
          $num_cmds = scalar @{ $cmd_aref };
        } 
      } elsif(exists $pools{ $label }) {     # Have we seen this pool name?
        my $cmd_aref = $pools{ $label }[5];
        push(@$cmd_aref, $command);
        $num_cmds = scalar @{$cmd_aref};
      } else {                             # No.  No we have not.
        die "I found a command that's looking for a pool that isn't defined... abort."
      } 
    }

    # MEMBER:label:hostname:
    elsif($line =~ /^MEMBER:~:(.*):~:(.*):~:$/) {
#      print "M - $1 - $2\n";
      my ($label, $hostname) = ($1, $2);
      if(exists $pools{ $label }) {
	    my $targets_aref = $pools{ $label }[2];
		push(@$targets_aref, $hostname);
	  } else {
	    die "A MEMBER command referenced a pool that isn't defined.  Aborting."
      }
    }

    # PUSH:label:lpath:rpath:epoch:clean:
    elsif($line =~ /^PUSH:~:(.*):~:(.*):~:(.*):~:(.*):~:$/) {
      my ($label, $lpath, $rpath, $epoch, $clean) = ($1, $2, $3, $4);
	  if($label =~ /ALL/) {
	    foreach my $pool (keys %pools) {
		  if    ($epoch eq "before") { $idx = 3; }
		  elsif ($epoch eq "after")  { $idx = 4; }
		  else  { die "Invalid epoch." }

		  my $push_aref = $pools{ $pool }[$idx];
		  my @push_atom = ("PUSH", $lpath, $rpath, $clean);
		  push(@$push_aref, \@push_atom);
		}
      } elsif (exists $pools{ $label }) {
		if ($epoch == "before") {
          my $push_aref = $pools{ $label }[3];
		  my @push_atom = ("PUSH", $lpath, $rpath, $clean);
		  push(@$push_aref, \@push_atom);
		} elsif ($epoch == "after") {
		  my $push_aref = $pools{ $label }[4];
		  my @push_atom = ("PUSH", $lpath, $rpath, $clean);
		  push(@$push_aref, \@push_atom);
		} else {
		  die "Invalid epoch.";
		}
	  } else { die "A PUSH command referenced a pool that isn't defined. Aborting." }
    }

    # PULL:pool:lpath:rpath:epoch:
    elsif($line =~ /^PULL:~:(.*):~:(.*):~:(.*):~:(.*):~:$/) {
      my ($label, $lpath, $rpath, $epoch) = ($1, $2, $3, $4);
	  if($label =~ /ALL/) {
	    foreach my $pool (keys %pools) {
		  if    ($epoch eq "before") { $idx = 3; }
		  elsif ($epoch eq "after")  { $idx = 4; }
		  else  { die "invalid epoch." }

		  my $push_aref = $pools{ $pool }[$idx];
		  my @push_atom = ("PULL", $lpath, $rpath, $clean);
		  push(@$push_aref, \@push_atom);
		}
      } elsif (exists $pools{ $label }) {
		if ($epoch eq "before") {
          my $push_aref = $pools{ $label }[3];
		  my @push_atom = ("PULL", $lpath, $rpath, $clean);
		  push(@$push_aref, \@push_atom);
		} elsif ($epoch eq "after") {
		  my $push_aref = $pools{ $label }[4];
		  my @push_atom = ("PULL", $lpath, $rpath, $clean);
		  push(@$push_aref, \@push_atom);
		} else {
		  die "Invalid epoch.";
		}
	  } else { die "A PULL command referenced a pool that isn't defined. Aborting." }
    } else {
      print "I didn't recognize this line: $line"
    }
  }
}

sub dump_struct() {
  while (my ($key, $value) = each(%pools)) {
	  my $pool         = $key;
	  my $user         = $$value[0];
	  my $pass         = $$value[1];
	  my $targets_aref = $$value[2];
      my $cmds_aref    = $$value[5];
	  my $befores_aref = $$value[3];
	  my $afters_aref  = $$value[4];

	  print "Pool: $pool user: $user pass: $pass\n";
	  foreach(@$targets_aref) { my $tgt = $_; print "  tgt: $tgt \n"; }
      foreach(@$cmds_aref)    { my $cmd = $_; print "  cmd: $cmd \n"; }
      foreach(@$befores_aref) { 
	    my $before = $_;
		my $cmd    = $$before[0];
		my $local  = $$before[1];
		my $remote = $$before[2];
		my $clean  = $$before[3];

		print "  before: $cmd: $local: $remote\n"; 
	  }
      foreach(@$afters_aref) { 
	    my $after = $_;
		my $cmd    = $$after[0];
		my $local  = $$after[1];
		my $remote = $$after[2];
		my $clean  = $$after[3];

		print "  after: $cmd: $local: $remote\n"; 
	  }
      print "\n";
  }
}


# ************ Main here *************************
@ARGV == 1 or die "You gotta gimme a config file to parse... you know this dude...\n";

($conf) = @ARGV;

&parse_conf($conf);

&dump_struct();
