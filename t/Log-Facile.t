use strict;
use Test::More qw(no_plan);

BEGIN { use_ok('Log::Facile') };

my $log_file = 'Log::Facile.tmp';
ok my $logger = Log::Facile->new($log_file);

ok $logger->info("info log test");
ok unlink $log_file or warn $!;

