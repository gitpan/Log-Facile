package Log::Facile;

use strict;
use vars qw($VERSION);
our $VERSION = '0.02';

use Carp;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(
    qw( file debug_flag )
);

sub new {
    my ($class, $log_file) = @_;
    bless { 
        file => $log_file 
    }, $class;
}

sub _write {
    my($self, $level, $message) = @_;
    my $date = $self->_current_date();
    my $log_mes = $date.' ['.$level.'] '.$message."\n";

    open my $log, ">> ".$self->file or croak $!;
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
    # TODO
}

sub _current_date {
    my($self, $pat) = @_;
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

  my $logger = Log::Facile->new("tmp.log");
  $logger->info('Log::Facile instance created!');
  $logger->debug('flag off');
  $logger->error('error occurred! detail.......');

  $logger->set('debug_flag', 1);
  $logger->debug('flag on');

This sample puts following logging.

  2008/08/25 01:01:49 [INFO] Log::Facile instance created!
  2008/08/25 01:01:49 [ERROR] error occurred! detail.......
  2008/08/25 01:01:49 [DEBUG] flag on

=head1 DESCRIPTION

Log::Facile provides so facile logging that is intended for personal tools.

=head2 TODO

log swapping, more tests.

=head1 AUTHOR

Kazuhiro Sera, E<lt>webmaster@seratch.ath.cxE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kazuhiro Sera

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
