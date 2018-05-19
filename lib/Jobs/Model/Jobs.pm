package Jobs::Model::Jobs;
use Mojo::Base -base;

use Mojo::Collection;

use Date::Simple qw/date today/;

has 'pg';

sub add {
  my ($self, $job) = @_;
  return $self->pg->db->insert('jobs', $job, {returning => 'id'})->expand->hash->{id};
}

sub all { shift->pg->db->select('jobs')->expand->hashes->to_array }

sub calendar {
  my ($self, $week, $weeks) = @_;
  $week = $week ? date($week) : today;
  $weeks ||= 1;
  $week -= 7 if $weeks > 2;
  my $calendar;
  warn $weeks;
  $calendar->{$week-$week->day_of_week} = $self->weekly($week) and $week+=7 for 1 .. $weeks;
  return $calendar;
}

sub daily {
  my $self = shift;
  my $date = shift || today;
  $self->pg->db->select('jobs', undef, {scheduled => $date})->expand->hashes->to_array
}

sub find {
  my ($self, $id) = @_;
  return $self->pg->db->select('jobs', '*', {id => $id})->expand->hash;
}

sub remove {
  my ($self, $id) = @_;
  $self->pg->db->delete('jobs', {id => $id});
}

sub save {
  my ($self, $id, $job) = @_;
  $self->pg->db->update('jobs', $job, {id => $id});
}

sub weekly {
  my $self = shift;
  my $date = $_[0] ? date(shift) : today;
  my $start = $date - $date->day_of_week;
  my @dates;
  push @dates, $start+$_ for (0..6);
  my $weekly = Mojo::Collection->new;
  push @$weekly, $self->pg->db->select('jobs', undef, {scheduled => $_->as_str})->expand->hashes->to_array for @dates;
  return $weekly;
}

1;
