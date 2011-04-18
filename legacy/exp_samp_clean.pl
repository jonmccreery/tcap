     #!/usr/bin/perl -w
     use strict;
     
     use Expect;
     
     ## configuration and constants
     my $LOSERS = (glob "~/.cpan-r-losers")[0];
     my $BELL = 15;                  # timeout seconds to send bell to user
     my $CPAN = qr/cpan> \z/;        # cpan shell prompt
    
    $ENV{TERM} = "dumb";            # keep CPAN.pm from being clever
    
    ## set up Expect objects
    my $cpan = Expect->new;
    $cpan->restart_timeout_upon_receive(1);
    $cpan->spawn('perl -MCPAN -eshell');
    
    my $stdin = Expect->init(\*STDIN);
    
    ## get to a CPAN shell prompt
    $cpan->expect
      (10,
       [$CPAN],
       [qr/another CPAN process.*not responding/s => sub {
          my $self = shift;
          $self->clear_accum;
          $self->send("y\r");
          exp_continue;             # look for cpan> prompt now
        }],
      ) or die "didn't get cpan prompt";
    
    ## make sure index is up to date
    $cpan->send("reload index\r");
    $cpan->expect(20, [$CPAN]) or die "missing prompt after reloading index";
    
    ## find out what's old
    my @packages = out_of_date_packages();
    
    ## get previous losers, and subtract them from the out-of-date list
    open LOSERS, "+<$LOSERS"
      or open LOSERS, ">$LOSERS"
      or die "Cannot create $LOSERS: $!";
    my @losers = split /\s+/, join "", <LOSERS>;
    
    my %losers = map { $_ => 1 } @losers;
    my @to_do_packages = grep !$losers{$_}, @packages;
    
    ## notify that we're not doing all of the out of date
    if (@packages and @losers) {
      print "\n### according to $LOSERS, we are skipping:\n",
        map "###  $_\n", @losers;
    }
    
    ## do we have anything to do?
    if (@to_do_packages) {
    
      ## incorporate dependencies automatically
      $cpan->send("o conf prerequisites_policy follow\r");
      $cpan->expect(5, [$CPAN]) or die "missing prompt after setting conf";
    
      ## and do the work!
      $cpan->send("install @to_do_packages\r");
    
      ## babysit the result, allow the user to interact if needed
      $stdin->stty(qw(raw -echo));
      $cpan->expect
        ($BELL,
         ## cpan expecting...
         [timeout => sub {
            my $self = shift;
            print "\cG";            # wake up, wake up, to a happy day!
            exp_continue;           # keep going
          }],
         [$CPAN],                   # exit if we see cpan prompt
         ## stdin expecting...
         -i => $stdin,
         [qr/.+/s => sub {
            my $self = shift;
            $cpan->send($self->match);
            exp_continue;           # and keep going
          }],
        );
      $stdin->stty(qw(sane));
    
      ## Oops.  Didn't get everything to work (it happens!)
      my @still_out_of_date = out_of_date_packages();
      if (@still_out_of_date) {
        print "\n### still out of date (saving to $LOSERS):\n",
          map "###  $_\n", @still_out_of_date;
      }
      ## record the new losers list so we won't try that next time
      seek LOSERS, 0, 0;
      truncate LOSERS, 0;
      print LOSERS map "$_\n", @still_out_of_date;
    }
    
    ## bye bye
    $cpan->send("exit\r");
    $cpan->soft_close;
   
   ## return a list of out of date packages using CPAN's "r" command
   ## presumes $cpan Expect object is at the CPAN prompt
   sub out_of_date_packages {
     $cpan->send("r\r");
     $cpan->expect(60, [qr/Package namespace.*\n/]) or die "missing banner";
     $cpan->expect(60, [$CPAN]) or die "missing CPAN prompt after 'r' output";
     map /^([\w:]+)\s+\d/, split /\r?\n/, $cpan->before;
   }
