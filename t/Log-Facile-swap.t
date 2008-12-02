use strict;
use Test::More qw(no_plan);

use Log::Facile;

ok chdir $ENV{HOME};

my $log_file = './Log-Facile-swap.test.tmp.log';
ok my $logger = Log::Facile->new($log_file);

ok $logger->info("info");

my $regexp_array = [ 
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[INFO\] info',
];

my $swap_dir = './Log-Facile.test';
my $swap1 = $swap_dir.'/'.$logger->{log_file}.'.1';
my $swap2 = $swap_dir.'/'.$logger->{log_file}.'.2';

mkdir $swap_dir or warn 'mkdir error - '.$!;
ok $logger->set('swap_dir', $swap_dir);
ok $logger->swap();

ok open my $io, $swap1 or warn 'file open error - '.$!;
my $i = 0;
while (<$io>) {
   my $regexp = ${$regexp_array}[$i];
   ok $_ =~ /$regexp/, 'output ok';
   $i++;
}

ok $logger->info('second swapped');
ok $logger->swap($swap_dir);

my $regexp_ar_sw2 = [ 
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[INFO\] second swapped',
];

ok open $io, $swap1 or warn 'file open error - '.$!;
$i = 0;
while (<$io>) {
   my $regexp = ${$regexp_ar_sw2}[$i];
   ok $_ =~ /$regexp/, 'output ok';
   $i++;
}
ok open $io, $swap2 or warn 'file open error - '.$!;
$i = 0;
while (<$io>) {
   my $regexp = ${$regexp_array}[$i];
   ok $_ =~ /$regexp/, 'output ok';
   $i++;
}

unlink $swap1 or warn 'file delete error - '.$!;
unlink $swap2 or warn 'file delete error - '.$!;

ok $logger->info('third swapped');
ok $logger->swap();
unlink $swap1 or warn 'file delete error - '.$!;

ok $logger->swap();

rmdir $swap_dir or warn 'rmdir error - '.$!;

__END__
