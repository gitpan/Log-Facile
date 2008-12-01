package Log::Facile;

use strict;
use vars qw($VERSION);
our $VERSION = '0.05';

use Carp;

my @accessor = ( 'log_file',
                 'level_debug',
                 'level_info',
                 'level_error',
                 'level_warn',
                 'level_fatal',
                 'swap_dir',
                 'date_format',
                 'debug_flag', );

sub new {
    my ($class, $log_file, $swap_dir) = @_;
    bless { 
        log_file => $log_file,
        swap_dir => $swap_dir, 
    }, $class;
}

sub get {
    my ($self, $name) = @_;
    if ( _is_valid_accessor($name) ) {
        return $self->{$name};
    } else {
        croak 'invalid field name :-P - '.$name;
        return 0;
    }
}

sub set {
    my ($self, $name, $value) = @_;
    if ( _is_valid_accessor($name) ) {
        $self->{$name} = $value;
        return $self;
    } else {
        croak 'invalid field name :-P - '.$name;
        return 0;
    }
}

sub _is_valid_accessor {
    my $name = shift;
    my $enable = 0;
    for my $each (@accessor) {
       if ($each eq $name) {
           $enable = 1; last;
       }
    }
    return $enable;
}

sub _write {
    my($self, $level, $message) = @_;
    my $date = $self->_current_date();
    my $log_mes = $date.' ['.$level.'] '.$message."\n";

    open my $log, ">> ".$self->get('log_file') 
        or croak 'log file open error - '.$!;
    print $log $log_mes;
    close $log 
        or croak 'log file close error - '.$!;
}

sub debug {
    my ($self, $mes) = @_;
    if ( $self->get('debug_flag') ) {
        my $level = defined $self->get('level_debug') 
                        ? $self->get('level_debug')
                        : 'DEBUG';
        return $self->_write($level, $mes);
    } else {
        return 1;
    }
}

sub info {
    my ($self, $mes) = @_;
    my $level = defined $self->get('level_info') 
                    ? $self->get('level_info')
                    : 'INFO';
    return $self->_write($level, $mes);
}

sub error {
    my ($self, $mes) = @_;
    my $level = defined $self->get('level_error') 
                    ? $self->get('level_error')
                    : 'ERROR';
    return $self->_write($level, $mes);
}

sub warn {
    my ($self, $mes) = @_;
    my $level = defined $self->get('level_warn') 
                    ? $self->get('level_warn')
                    : 'WARN';
    return $self->_write($level, $mes);
}

sub fatal {
    my ($self, $mes) = @_;
    my $level = defined $self->get('level_fatal') 
                    ? $self->get('level_fatal')
                    : 'FATAL';
    return $self->_write($level, $mes);
}

sub swap {
    my ($self, $swap_dir) = @_;

    # set swap dir
    if ( defined $swap_dir ) {
        $self->set('swap_dir', $swap_dir);
    } elsif ( ! defined $self->get('swap_dir') ) {
        my $log_dir = $self->{log_file};
        $log_dir =~ s/(.+\/).+$/$1/;
        $self->set('swap_dir', $log_dir);
    }

    # get log filename prefix
    my $file_pref = $self->{log_file};
    $file_pref =~ s/.+\/(.+?)$/$1/;

    # move current log file
    if ( -f $self->{log_file} ) { 
        rename $self->{log_file}, $self->{swap_dir}.'/'.$file_pref 
            or croak 'current file move error - '.$!;
    } else {
        return 1;
    }

    # rename files
    opendir my $s_dir, $self->{swap_dir} or croak 'dir open error - '.$!;
    for my $each (grep /$file_pref/, reverse sort readdir $s_dir) {
        $each = $self->{swap_dir}.'/'.$each;
        my $rename_pref = $self->{swap_dir}.'/'.$file_pref.'.';
        if ($each =~ /\.(\d)$/) {
            rename $each, $rename_pref.($1+1) 
                or croak 'rename error ('.$rename_pref.($1+1).') - '.$!;
        } else {
            rename $each, $rename_pref.'1' 
                or croak 'rename error ('.$rename_pref.'.1) - '.$!;
        }
    }
    closedir $s_dir or croak 'dir close error - '.$!;
}

sub _current_date {
    my($self, $pat) = @_;

    my @da = localtime(time);
    my $year4 = sprintf("%04d", $da[5]+1900);
    my $year2 = sprintf("%02d", $da[5]+1900-2000);
    my $month = sprintf("%02d", $da[4]+1);
    my $day   = sprintf("%02d", $da[3]);
    my $hour  = sprintf("%02d", $da[2]);
    my $min   = sprintf("%02d", $da[1]);
    my $sec   = sprintf("%02d", $da[0]);

    my $format = (defined $self->get('date_format'))
                     ? $self->get('date_format') 
                     : 'yyyy/mm/dd hh:mi:ss';

    $format =~ s/yyyy/$year4/g;
    $format =~ s/yy/$year2/g;
    $format =~ s/mm/$month/g;
    $format =~ s/dd/$day/g;
    $format =~ s/hh/$hour/g;
    $format =~ s/mi/$min/g;
    $format =~ s/ss/$sec/g;

    return $format;
}

1;
__END__

=head1 NAME

Log::Facile - Perl extension for facile logging

=head1 SYNOPSIS

  use Log::Facile;

  my $logger = Log::Facile->new('/foo/var/log/tmp.log');
  $logger->info('Log::Facile instance created!');
  $logger->debug('flag off');
  $logger->error('error occurred! detail.......');
  $logger->warn('warning');
  $logger->fatal('fatal error!');

  $logger->set('debug_flag', 1);
  $logger->debug('flag on');

This sample puts following logging.

  2008/08/25 01:01:49 [INFO] Log::Facile instance created!
  2008/08/25 01:01:49 [ERROR] error occurred! detail.......
  2008/08/25 01:01:49 [WARN] warning
  2008/08/25 01:01:49 [FATAL] fatal error!
  2008/08/25 01:01:49 [DEBUG] flag on

Log swapping sample is following.

  $logger->swap('/foo/var/log/old');

or

  $logger->set('swap_dir', '/foo/var/log/old');
  $logger->swap();

This time swapped log filename is 'tmp.log.1'.
This file will be renamed 'tmp.log.2' while upcoming log swapping.
I mean, the incremented number means older.

You can change date output format from default('yyyy/mm/dd hh:mi:ss').

  $logger->set('date_format', 'yyyy-mm-dd hh-mi-ss');
  $logger->info('date format changed');
  $logger->set('date_format', 'yymmdd hhmiss');
  $logger->info('date format changed');

This logger outputs date in following format.

  2008-11-29 19-23-03 [INFO] date format changed
  081129 192304 [INFO] date format changed

This is how to change level display string.

  $logger->set('level_debug', 'DBG')
         ->set('level_info',  'INF')
         ->set('level_error', 'ERR');

  $logger->info('Log::Facile instance created!');
  $logger->debug('flag off');
  $logger->error('error occurred! detail.......');

Outputs followings.

  2008/11/30 04:28:51 [INF] Log::Facile instance created!
  2008/11/30 04:28:51 [DBG] flag off
  2008/11/30 04:28:51 [ERR] error occurred! detail.......

Aside, the accessors in this module checks your typo. 
  
  $logger->set('level_errror', 'ERR')

will be croaked.

  invalid field name :-P - level_errror at ./sample.pl line 22  

=head1 DESCRIPTION

Log::Facile provides so facile logging that is intended for personal tools.

=head1 AUTHOR

Kazuhiro Sera, E<lt>webmaster@seratch.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kazuhiro Sera

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
