package Jobs::Controller::Jobs;
use Mojo::Base 'Mojolicious::Controller';

use Date::Simple 'today';

sub create { shift->render(job => {}) }

sub edit {
  my $self = shift;
  $self->render(job => $self->jobs->find($self->param('id')));
}

sub print {
  my $self = shift;
  my $job = $self->jobs->find($self->param('id'));
  my $printer = $self->app->printer('jobs/job_ticket', job => $job);
  $self->render(printer => $printer, job => $self->jobs->find($self->param('id')));
}

sub index {
  my $self = shift;
  my $week = $self->session('week') || today->as_iso;
  my $weeks = $self->session('weeks') || 1;
  $self->render(jobs => $self->jobs->calendar($week, $weeks));
}

sub remove {
  my $self = shift;
  $self->jobs->remove($self->param('id'));
  $self->redirect_to('jobs');
}

sub show {
  my $self = shift;
  $self->render(job => $self->jobs->find($self->param('id')));
}

sub store {
  my $self = shift;

  my $v = $self->_validation;
  return $self->render(action => 'create', job => {}) if $v->has_error;

  my $id = $self->jobs->add($v->output);
  $self->redirect_to('show_job', id => $id);
}

sub update {
  my $self = shift;

  my $v = $self->_validation;
  return $self->render(action => 'edit', job => {}) if $v->has_error;

  my $id = $self->param('id');
  $self->jobs->save($id, $v->output);
  $self->redirect_to('show_job', id => $id);
}

sub week {
  my $self = shift;
  my $week = $self->param('week');
  my $weeks = $self->param('weeks');
  $week =~ /\d{4}-\d{2}-\d{2}/ or $week = today->as_iso;
  $weeks =~ /\d+/ or $weeks = 1;
  $self->session(week => $week)->session(weeks => $weeks)->redirect_to($self->url_for('jobs'));
}

sub _validation {
  my $self = shift;

  my $v = $self->validation;
  $v->input->{$_} ||= 0 for qw/grinder chipper/;
  $v->required('name');
  $v->required('contacted');
  $v->required('scheduled');
  $v->required('estimate');
  $v->required('address');
  $v->required('phone');
  $v->required('description');
  $v->optional('grinder');
  $v->optional('chipper');

  return $v;
}

1;
