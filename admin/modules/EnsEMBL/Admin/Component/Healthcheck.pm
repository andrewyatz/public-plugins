=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Admin::Component::Healthcheck;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component);

use Rose::DateTime::Util qw(format_date parse_date);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
  $self->configurable( 0 );
}

sub caption {
  return '';
}

sub no_healthcheck_found {
  ## @param Flag telling whether control reports were found for the applied filter 
  ## @return Text to be displayed in case no healthcheck found
  my ($self, $flag) = @_;

  my $object  = $self->object;
  my $type    = $object->view_type;
  my $param   = $object->view_param;
  my $title   = $object->view_title;
  my $release = $object->requested_release;
  my $session = $object->last_session_id;

  if ($flag) {
    return sprintf q(<p>No 'PROBLEM' reports found%s.</p>), $type && $param ? sprintf(" for %s '%s'", $title, $param) : '';
  }
  if (!$release || !$session) {
    return q(<p>Healthchecks have not been performed for this release.</p>);
  }
  if ($type && $param) {
    return sprintf q(<p>Healthcheck for %s '%s' was not run during the last healtcheck session of release %s.</p>), lc $title, $param, $release;
  }
  return q(<p>No healthcheck reports found.</p>);
}

sub get_all_releases_dropdown_form {
  ## Return Web:Form for all releases drodown
  my ($self, $label, $name) = @_;

  my $object  = $self->object;
  my $first   = $object->first_release;
  my $last    = $object->current_release;
  my $skip    = $object->requested_release;

  my $form    = $self->new_form({'method' => 'get', 'action' => ''});
  $form->add_field({
    'label'       => $label,
    'inline'      => 1,
    'field_class' => 'hc-formfield',
    'elements'    => [{
      'type'        => 'dropdown',
      'name'        => $name,
      'values'      => [ reverse map {$_ == $skip ? () : {'caption' => "Release $_", 'value' => $_}} $first..$last ]
    }, {
      'value'       => 'Go',
      'type'        => 'submit'
    }]
  });
  return $form;
}

sub get_healthcheck_link {
  ## Returns a formatted link for healthcheck page depending upon following keys
  ## params keys 
  ##  - type: view type of the link eg. species, testcase etc.
  ##  - param: value of the filter parameter
  ##  - caption: caption to be displayed
  ##  - title: goes in title attribute
  ##  - release: release id
  ##  - cut_long: flag stating whether or not to cut the long caption of the link
  ##  - class: Class attribute
  my ($self, $params) = @_;

  my $caption = exists $params->{'caption'} && defined $params->{'caption'} ? $params->{'caption'} : '';
  $caption = $params->{'param'} || '<i>unknown</i>' if $caption eq '';
  return $caption unless $params->{'param'};

  my $title   = $params->{'title'} || $caption;
  my $param   = $params->{'param'};
  my $release = $params->{'release'};
  my $class   = $params->{'class'} ? qq( class="$params->{'class'}") : '';
  exists $params->{'cut_long'} && $params->{'cut_long'} eq 'cut' && length $caption > 23 and $caption = substr($caption, 0, 20).'&#8230;';

  if ($params->{'type'} eq 'species') {
    return $self->object->validate_species($param) 
      ? qq(<a$class href="/$param/Healthcheck/Details/Species?release=$release" title="List all failed test reports for Speices $title in release $release">$caption</a>)
      : qq(<a$class href="/Healthcheck/Details/Species?release=$release;q=$param" title="List all failed test reports for Speices $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'testcase') {
    return qq(<a$class href="/Healthcheck/Details/Testcase?release=$release;q=$param" title="List all failed test reports for Testcase $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'database_type') {
    return qq(<a$class href="/Healthcheck/Details/DBType?release=$release;q=$param" title="List all failed test reports for Database Type $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'database_name') {
    return qq(<a$class href="/Healthcheck/Details/Database?release=$release;q=$param" title="List all failed test reports for Database Name $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'team_responsible') {
    $param   = lc $param;
    $title   = join(' ', map {ucfirst lc $_} split('_', $param));
    $caption = exists $params->{'caption'} ? $params->{'caption'} : $title;
    return qq(<a$class href="/Healthcheck/Details/Team?release=$release;q=$param" title="List all failed test reports for Team $title in release $release">$caption</a>);
  }
  else {
    return $caption;
  }
}

sub hc_format_date {
  ## Formates date for displaying
  my ($self, $datetime) = @_;
  return $datetime ? format_date(parse_date($datetime), "%b %e, %Y at %H:%M") : '';
}

sub hc_format_compressed_date {
  ## Formates date for displaying the HC table column
  my ($self, $datetime) = @_; 
  return format_date(parse_date($datetime), "%d/%m/%y %H:%M");  
}

sub annotation_action {
  ## Returns a label for the action enums for annotation.
  my ($self, $value) = @_;

  my @actions = (
    'manual_ok'                       => 'Manual ok: not a problem for this release',
    'manual_ok_all_releases'          => 'Manual ok all release: not a problem for this species',
    'manual_ok_this_assembly'         => 'Manual ok this assembly',
    'manual_ok_this_genebuild'        => 'Manual ok this genebuild',
    'manual_ok_this_regulatory_build' => 'Manual ok this regulatory build',
    'healthcheck_bug'                 => 'Healthcheck bug: error should not appear, requires changes to healthcheck',
    'under_review'                    => 'Under review: Will be fixed/reviewed',
    'fixed'                           => 'Fixed',
    'note'                            => 'Note or comment'
  );

  return @actions if $value eq 'all';

  while (my ($val, $title) = splice @actions, 0, 2) {
    return {'value' => $value, 'title' => $title} if $val eq $value;
  }

  return {'value' => '', 'title' => ''};
}

sub group_report_counts {
  ## Creates a counting of all reports (rose objects) with failed_count key on the basis of parameter passed as views
  ## @param Report Rose objects (generated from 'count - group by' query)
  ## @param ArrayRef for all different views required
  ## @return HashRef (with keys as views requested) containing counting of all reports wrt views requested
  my ($self, $reports, $views) = @_;
  my $counter = { map {$_ => {}} @$views };
  foreach my $report (@$reports) {
    my $count = $report->failed_count;
    for (keys %$counter) {
      my $val = $report->$_ || '';
      $val    = ucfirst $val if $_ eq 'species'; # always keep first character of species name capital
      $counter->{$_}{$val || 'unknown'}{'all'} += $count;
      $counter->{$_}{$val || 'unknown'}{'new'} += $count if $report->first_session_id == $report->last_session_id;
    }
  }
  return $counter;
}

sub failure_summary_table {
  ## Returns a filure summary table for given view types
  ## Params Hashref with keys:
  ##  - type                species, testcase, database_name etc
  ##  - session_id          Id of the session run most recently in the given release
  ##  - release             release id
  ##  - count               Data structure containing counting of all reports wrt view type
  ##  - default_list        ArrayRef of default list of Testcases, DBTypes, Species or Databases as required
  ##  - release2            release id of the release to which reports are to be compared
  ##  - compare_count       Similar to count, but for compared reports
  my ($self, $params) = @_;

  (my $title  = ucfirst($params->{'type'})) =~ s/_/ /g;
  my $table   = $self->new_table([], [], {'class' => 'tint'});

  $table->add_columns(
    { 'key' => 'group',         'title' => $title, 'width' => qq(40%) },
    { 'key' => 'new_failed',    'title' => "Newly failed for last run (Session $params->{'session_id'} in v$params->{'release'})",  'align' => 'center' },
    { 'key' => 'total_failed',  'title' => "All failed for last run (Session $params->{'session_id'} in v$params->{'release'})",    'align' => 'center' },
  );

  # add 4th column if comparison is intended
  $table->add_columns(
    { 'key' => 'comparison',  'title' => "Failed in  release $params->{'release2'}", 'align' => 'center' },
  ) if exists $params->{'compare_count'};

  my $fails   = $params->{'count'};
  my $fails2  = $params->{'compare_count'};
  my $groups  = { map {$_ => 1} keys %$fails, keys %$fails2, @{$params->{'default_list'}} };

  for (sort keys %$groups) {

    my %fourth_cell = exists $params->{'compare_count'} ? (
      'comparison'  => $self->get_healthcheck_link({
        'type'        => $params->{'type'},
        'param'       => $_,
        'caption'     => $fails2->{$_}{'all'} || '0',
        'title'       => $_,
        'release'     => $params->{'release2'}
      })
    ) : ();
    $table->add_row({
      'group'       => $self->get_healthcheck_link({
        'type'        => $params->{'type'},
        'param'       => $_,
        'release'     => $params->{'release'}
      }),
      'new_failed'  => $fails->{$_}{'new'} || '0',
      'total_failed'  => $self->get_healthcheck_link({
        'type'        => $params->{'type'},
        'param'       => $_,
        'caption'     => $fails->{$_}{'all'} || '0',
        'title'       => $_,
        'release'     => $params->{'release'},
        'class'       => $fails->{$_}{'all'} ? 'hc-failsrow' : 'hc-nofailsrow',
      }),
      %fourth_cell
    });
  }
  return $table->render;
}

1;
