package Log::Facile;

use strict;
use vars qw($VERSION);
our $VERSION = '1.00';

use Carp;

# log template config
my $tmpl_hash_key = 'template';
my @tmpl_accessor = ( 'TEMPLATE',
                      'DATE',
                      'LEVEL', 
                      'MESSAGE', );

# available accessor list
my @accessor = ( 'log_file',
                 'level_debug',
                 'level_info',
                 'level_error',
                 'level_warn',
                 'level_fatal',
                 'swap_dir',
                 'date_format',
                 'debug_flag',
                 $tmpl_hash_key, );

# constructor
sub new {
    my ($class, $log_file, $swap_dir) = @_;

    bless { 
        log_file => $log_file,
        swap_dir => $swap_dir, 
        date_format => 'yyyy/mm/dd hh:mi:ss',
        $tmpl_hash_key => { 'TEMPLATE' => 'DATE [LEVEL] MESSAGE',
                            'DATE' => undef,
                            'LEVEL' => undef,
                            'MESSAGE' => undef, },
    }, $class;
}

# getter
sub get {
    my ($self, $name, $tmpl_key ) = @_;

    # log template value
    if ( _is_tmpl_accessor($name, $tmpl_key) == 1 ) {
        return $self->{$tmpl_hash_key}->{$tmpl_key};
    # new template value
    } elsif ( _is_tmpl_accessor($name, $tmpl_key) == 2 ) {
        return $self->{$tmpl_hash_key};
    # get field
    } elsif ( _is_valid_accessor($name) ) {
        return $self->{$name};
    # error
    } else {
        return 0;
    }
}

# setter
sub set {
    my ($self, $name, $value_or_key, $tmpl_value) = @_;

    if ( _is_tmpl_accessor($name, $value_or_key) == 1 ) {
        $self->{$tmpl_hash_key}->{$value_or_key} = $tmpl_value;
    } elsif ( _is_tmpl_accessor($name, $value_or_key) == 2 ) {
        push @tmpl_accessor, $value_or_key;
        $self->{$tmpl_hash_key}->{$value_or_key} = $tmpl_value;
    } elsif ( _is_tmpl_accessor($name, $value_or_key) == 255 ) {
        return 0;
    } elsif ( _is_valid_accessor($name) ) {
        $self->{$name} = $value_or_key;
    } else {
        return 0;
    }
    return $self;
}

# tmpl accessor check
sub _is_tmpl_accessor {
    my ($name, $key) = @_;

    my $enable = 0;
    if ( defined $name && $name eq $tmpl_hash_key ) {
        $enable = 2;
        for my $each (@tmpl_accessor) {
            if ( defined $key && $each eq $key ) {
                $enable = 1; last;
            } elsif ( defined $key 
                      && ( $each =~ m/$key/ || $key =~ m/$each/ ) ) {
                croak "Can't use '".$key."' to template "
                      ."because '".$each."' has already used.";
                $enable = 255;
            }
        }
    }
    return $enable;
}

# accessor check
sub _is_valid_accessor {
    my $name = shift;

    my $enable = 0;
    for my $each (@accessor) {
       if ( defined $name && $name eq $each ) {
           $enable = 1; last;
       }
    }
    croak 'invalid field name :-P - '.$name if ! $enable;
    return $enable;
}

sub _get_log_value {
    my ($self, $key, $value) = @_;

    # get defined object
    if ( defined $key 
         && _is_tmpl_accessor($tmpl_hash_key, $key) == 1
         && defined $self->get($tmpl_hash_key)->{$key} ) {
        return $self->get($tmpl_hash_key)->{$key};
    # get date default sub
    } elsif ( defined $key 
         && $key eq 'DATE'
         && ! defined $self->get($tmpl_hash_key)->{'DATE'} ) {
        return $self->_current_date();
    # return accepted value
    } else {
        return $value;
    }
}

# get log output string
sub _get_log_str {
    my ($self, $date, $level, $message) = @_;

    # template hash
    my $t_hash = $self->get($tmpl_hash_key);
    # log template string
    my $log_str = $t_hash->{'TEMPLATE'};

    # default values
    $log_str =~ s/DATE/$date/g;
    $log_str =~ s/LEVEL/$level/g;
    $log_str =~ s/MESSAGE/$message/g;

    # user defined values
    for my $key (@tmpl_accessor) {
        my $replace = $self->_get_log_value($key);
        $log_str =~ s/$key/$replace/g;
    }
    return $log_str;
}

# log writer
sub _write {
    my ($self, $p_level, $p_message) = @_;

    # default values
    my $date = $self->_get_log_value('DATE');
    my $level = $self->_get_log_value('LEVEL', $p_level);
    my $message = $self->_get_log_value('MESSAGE', $p_message);

    # log string
    my $log_str = $self->_get_log_str($date,$level,$message).$/;

    # execute writing log file
    open my $log, ">> ".$self->get('log_file') 
        or croak 'log file open error - '.$!;
    print $log $log_str;
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
        my $log_dir = $self->get('log_file');
        $log_dir =~ s/(.+\/).+$/$1/;
        $self->set('swap_dir', $log_dir);
    }

    # get log filename prefix
    my $file_pref = $self->get('log_file');
    $file_pref =~ s/.+\/(.+?)$/$1/;

    # move current log file
    if ( ! -d $self->get('swap_dir') ) {
        mkdir $self->get('swap_dir')
            or croak 'create swap dir error - '.$!;
    }
    if ( -f $self->get('log_file') ) { 
        rename $self->get('log_file'), 
            $self->get('swap_dir').'/'.$file_pref 
            or croak 'current file move error - '.$!;
    } else {
        return 1;
    }

    # rename files
    opendir my $s_dir, $self->get('swap_dir') 
        or croak 'dir open error - '.$!;

    for my $each (grep /$file_pref/, reverse sort readdir $s_dir) {
        $each = $self->get('swap_dir').'/'.$each;
        my $rename_pref = $self->get('swap_dir').'/'.$file_pref.'.';
        if ($each =~ /\.(\d)$/) {
            rename $each, $rename_pref.($1+1) 
                or croak 'rename error ('.$rename_pref.($1+1).') - '.$!;
        } else {
            rename $each, $rename_pref.'1' 
                or croak 'rename error ('.$rename_pref.'.1) - '.$!;
        }
    }
    closedir $s_dir 
        or croak 'dir close error - '.$!;
}

# get current datetime
sub _current_date {
    my($self, $pat) = @_;

    # datetime values
    my @da = localtime(time);
    my $year4 = sprintf("%04d", $da[5]+1900);
    my $year2 = sprintf("%02d", $da[5]+1900-2000);
    my $month = sprintf("%02d", $da[4]+1);
    my $day   = sprintf("%02d", $da[3]);
    my $hour  = sprintf("%02d", $da[2]);
    my $min   = sprintf("%02d", $da[1]);
    my $sec   = sprintf("%02d", $da[0]);

    # date format
    my $date_str = (defined $self->get('date_format'))
                     ? $self->get('date_format') 
                     : 'yyyy/mm/dd hh:mi:ss';

    # replace format values
    $date_str =~ s/yyyy/$year4/g;
    $date_str =~ s/yy/$year2/g;
    $date_str =~ s/mm/$month/g;
    $date_str =~ s/dd/$day/g;
    $date_str =~ s/hh/$hour/g;
    $date_str =~ s/mi/$min/g;
    $date_str =~ s/ss/$sec/g;

    return $date_str;
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

The default log template is

  'TEMPLATE' => 'DATE [LEVEL] MESSAGE',

'DATE', 'LEVEL', 'MESSAGE' is default log items. It is able to add more items. 

You can modify the log template like this.

  $logger->set('date_format', 'dd/mm/yy hh:mi:ss');
  $logger->set('template', 'HOSTNAME', $hostname);
  $logger->set('template', 'TEMPLATE', 'HOSTNAME - DATE (LEVEL) MESSAGE');

  $logger->info('template changed.');

Outputs followings.

  localhost - 07/12/08 01:40:11 (INFO) template changed.

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
