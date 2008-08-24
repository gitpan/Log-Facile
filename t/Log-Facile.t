use strict;
use Test::More qw(no_plan);

BEGIN { use_ok('Log::Facile') };

ok chdir $ENV{HOME};
my $log_file = 'Log-Facile.test.tmp.log';
ok my $logger = Log::Facile->new($log_file);

#ok $logger->debug('debug off');
ok $logger->set('debug_flag', 1);
ok $logger->debug("debug on");
ok $logger->info("info");
ok $logger->error("error");

my $regexp_array = [ 
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[DEBUG\] debug on',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[INFO\] info',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[ERROR\] error',
];

ok open my $io, $log_file or warn $!;
my $i = 0;
while (<$io>) {
   my $regexp = ${$regexp_array}[$i];
   ok $_ =~ /$regexp/, 'output ok';
   $i++;
}
ok unlink $log_file or warn $!;
