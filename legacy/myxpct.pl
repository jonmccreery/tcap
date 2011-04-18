#!/usr/bin/perl
#
#
#

use Expect;

my $payload = $ARGV[0];

my @servers=("192.168.122.1", "192.168.1.201");
my $username="root";
my $password="got69hic";
my $spawn = new Expect;

foreach $server (@servers) {
	my $command="sftp $username\@$server";

	$spawn=Expect->spawn($command);

my $PROMPT = '[\]\$\>\#]\s$';

my $ret = $spawn->expect(10,
	[ qr/\(yes\/no\)\?\s*$/ => sub { $spawn->send("yes\n"); exp_continue; } ],
	[ qr/assword:\s*$/ => sub { $spawn->send("got69hic\n"); exp_continue; } ],
	[ qr/ogin:\s*$/ => sub { $spawn->send("$username\n"); exp_continue; } ],
	[ qr/$PROMPT/   => sub { $spawn->send("put $payload /tmp\n"); 
				 $spawn->send("quit\n");   } ],
	);
}



$spawn->interact();
exit;
