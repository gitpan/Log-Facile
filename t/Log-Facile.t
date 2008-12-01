use strict;
use Test::More qw(no_plan);

BEGIN { use_ok('Log::Facile') };

ok chdir $ENV{HOME};

my $log_file = './Log-Facile.test.tmp.log';
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

my $swap_dir = './Log-Facile.test/';
my $swap1 = $swap_dir.'/'.$logger->{log_file}.'.1';
my $swap2 = $swap_dir.'/'.$logger->{log_file}.'.2';

mkdir './Log-Facile.test' or warn 'mkdir error - '.$!;
ok $logger->set('swap_dir', $swap_dir);
ok $logger->swap();

ok open $io, $swap1 or warn 'file open error - '.$!;
$i = 0;
while (<$io>) {
   my $regexp = ${$regexp_array}[$i];
   ok $_ =~ /$regexp/, 'output ok';
   $i++;
}

ok $logger->info("second swapped");
ok $logger->swap($swap_dir);

my $regexp_ar_sw2 = [ 
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[INFO\] second swapped',
];
=head
open $io, $swap2 or warn 'file open error - '.$!;
$i = 0;
while (<$io>) {
   my $regexp = ${$regexp_ar_sw2}[$i];
   ok $_ =~ /$regexp/, 'output ok';
   $i++;
}
=cut

unlink $swap1 or warn 'file delete error - '.$!;
unlink $swap2 or warn 'file delete error - '.$!;

ok $logger->info("third swapped");
ok $logger->swap();
unlink $swap1 or warn 'file delete error - '.$!;

ok $logger->swap();

rmdir $swap_dir or warn 'rmdir error - '.$!;

__END__
