use strict;
use Test::More qw(no_plan);

use Log::Facile;

ok chdir $ENV{HOME};

my $log_file = './Log-Facile-write.test.tmp.log';
ok my $logger = Log::Facile->new($log_file);

ok $logger->debug('debug off');
ok $logger->set('debug_flag', 1);
ok $logger->debug("debug on");
ok $logger->info("info");
ok $logger->error("error");
ok $logger->warn("warn");
ok $logger->fatal("fatal");

ok $logger->set('level_debug', 'DBG');
ok $logger->set('level_info', 'INF');
ok $logger->set('level_error', 'ERR');
ok $logger->set('level_warn', 'WRN');
ok $logger->set('level_fatal', 'FTL');

ok $logger->debug("debug on");
ok $logger->info("info");
ok $logger->error("error");
ok $logger->warn("warn");
ok $logger->fatal("fatal");

my $regexp_array = [ 
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[DEBUG\] debug on',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[INFO\] info',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[ERROR\] error',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[WARN\] warn',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[FATAL\] fatal',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[DBG\] debug on',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[INF\] info',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[ERR\] error',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[WRN\] warn',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[FTL\] fatal',
];

ok open my $io, $log_file or warn 'file open error - '.$!;
my $i = 0;
while (<$io>) {
   my $regexp = ${$regexp_array}[$i];
   ok $_ =~ /$regexp/, 'output ok';
   $i++;
}

unlink $log_file or croak $!;

__END__
