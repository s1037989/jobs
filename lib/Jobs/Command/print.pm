package Jobs::Command::print;
use Mojo::Base 'Mojolicious::Command';

use Date::Simple qw/date today/;

has description => 'print daily jobs';
has usage => sub { shift->extract_usage };

sub run {
  my ($self, $date) = @_;

  foreach my $job ( @{$self->app->jobs->daily($date ? date($date) : today)} ) {
    say $job->{name};
    $self->app->printer('jobs/job_ticket', job => $job);
  }
}

1;
