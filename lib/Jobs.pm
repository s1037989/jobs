package Jobs;
use Mojo::Base 'Mojolicious';

use Jobs::Model::Jobs;
use Mojo::Pg;

use Mojo::Sendgrid;

use Date::Simple 'today';
use Locale::Currency::Format;

currency_set('USD', '#,###', FMT_COMMON);

sub startup {
  my $self = shift;

  push @{$self->app->commands->namespaces}, 'Jobs::Command';

  # Configuration
  $self->plugin('Config');
  $self->secrets($self->config('secrets'));

  # Model
  $self->helper(pg => sub { state $pg = Mojo::Pg->new(shift->config('pg')) });
  $self->helper(
    jobs => sub { state $jobs = Jobs::Model::Jobs->new(pg => shift->pg) });
  $self->helper(sendgrid => sub { Mojo::Sendgrid->new($self->config('sendgrid')) });
  $self->helper(currency => sub { currency_format('USD', $_[1], FMT_COMMON) });
  $self->helper(printer => sub {
    my $self = shift;
    my $printer = $self->config('printer');
    my $print = $self->render_to_string(@_);
    $self->app->sendgrid->mail(to => $printer, from => $printer, subject => 'Job Ticket', html => $print)->send;
    return $print;
  });

  # Migrate to latest version if necessary
  my $path = $self->home->child('migrations', 'jobs.sql');
  $self->pg->auto_migrate(1)->migrations->name('jobs')->from_file($path);

  # Controller
  my $r = $self->routes;
  $r->get('/' => sub { shift->redirect_to('jobs') });
  $r->get('/jobs')->to('jobs#index');
  $r->get('/jobs/week')->to('jobs#week')->name('jobs_week');
  $r->get('/jobs/create')->to('jobs#create')->name('create_job');
  $r->post('/jobs')->to('jobs#store')->name('store_job');
  $r->get('/jobs/:id')->to('jobs#show')->name('show_job');
  $r->get('/jobs/:id/edit')->to('jobs#edit')->name('edit_job');
  $r->get('/jobs/:id/print')->to('jobs#print')->name('print_job');
  $r->put('/jobs/:id')->to('jobs#update')->name('update_job');
  $r->delete('/jobs/:id')->to('jobs#remove')->name('remove_job');
}

1;
