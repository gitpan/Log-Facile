package Log::Facile;

use strict;
use vars qw($VERSION);
our $VERSION = '0.03';

use Carp;

sub new {
    my ($class, $log_file) = @_;
    bless { 
        log_file => $log_file 
    }, $class;
}

sub get {
    my ($self, $name) = @_;
    return $self->{$name};
}

sub set {
    my ($self, $name, $value) = @_;
    $self->{$name} = $value;
}

sub _write {
    my($self, $level, $message) = @_;
    my $date = $self->_current_date();
    my $log_mes = $date.' ['.$level.'] '.$message."\n";

    open my $log, ">> ".$self->get('log_file') or croak $!;
    print $log $log_mes;
    close $log or croak $!;
}

sub debug {
    my ($self, $mes) = @_;
    if ( $self->get('debug_flag') ) {
        return $self->_write("DEBUG", $mes);
    }
}

sub info {
    my ($self, $mes) = @_;
    return $self->_write("INFO", $mes);
}

sub error {
    my ($self, $mes) = @_;
    return $self->_write("ERROR", $mes);
}

sub swap {
    my $self = shift;

    # get log filename prefix
    my $file_pref = $self->{log_file};
    if ( $file_pref =~ m/.+\/(.+?)$/ ) {
         $file_pref =~ s/.+\/(.+?)$/$1/;
    }

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

    my $format = $self->get('date_format');

    # TODO customize format

    my @da = localtime(time);
    return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
                   $da[5]+1900, $da[4]+1, $da[3], $da[2], $da[1], $da[0]);
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

  $logger->set('debug_flag', 1);
  $logger->debug('flag on');

This sample puts following logging.

  2008/08/25 01:01:49 [INFO] Log::Facile instance created!
  2008/08/25 01:01:49 [ERROR] error occurred! detail.......
  2008/08/25 01:01:49 [DEBUG] flag on

Log swapping sample is following.

  $logger->set('swap_dir', '/foo/var/log/old');
  $logger->swap();

This time swapped log filename is 'tmp.log.1'.
This file will be renamed 'tmp.log.2' while upcoming log swapping.
I mean, the incremented number means older.

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
