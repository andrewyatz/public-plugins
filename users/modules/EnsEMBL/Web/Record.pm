package EnsEMBL::Web::Record;

### For backward compatibility
### This packages replaces EnsEMBL::Web::Data::Record temporarily for object type UserData, untill UserData is properly re-written to make methods calls to actual Rose Record object instead of using hash keys
### Objects belonging to this call is only returned by EnsEMBL::Web::User::get_record method

use strict;
use warnings;

use EnsEMBL::Web::Tools::MethodMaker qw(add_method);

use base qw(EnsEMBL::Web::Root);

sub new {
  my ($class, $object) = @_;
  foreach my $key (keys %$object) {
    add_method($class, $key, sub { return shift->{$key}; }) unless $class->can($key) && $key =~ /^_/;
  }
  return bless $object, $class;
}

sub from_rose_objects {
  my ($class, $rose_objects) = @_;
  return map {
    my $record = $_->as_tree;
    $record->{'__rose_object'} = $_;
    $record->{$_} = $record->{'data'}->{$_} for keys %{$record->{'data'}};
    delete $record->{'data'};
    $class->new($record);
  } @$rose_objects;
}

sub id {
  return shift->{'record_id'};
}

sub clone {
  my $self        = shift;
  my $class       = ref $self;
  my $rose_object = delete $self->{'__rose_object'};
  my $clone       = $self->deepcopy($self);
  $self->{'__rose_object'} = $rose_object;
  $clone->{'__rose_object'} = $rose_object->clone_and_reset;
  $clone->{'__rose_object'}->cloned_from($self->id);
  $clone->{'cloned_from'} = $self->id;
  return $class->new($clone);
}

sub owner {
  my ($self, $owner)  = @_;
  my $rose_object     = $self->{'__rose_object'};
  $rose_object->record_type($owner->RECORD_TYPE);
  $rose_object->record_type_id($owner->get_primary_key_value);
  return $rose_object->record_type eq 'group' ? $rose_object->group : $rose_object->user;
}

sub save {
  shift->{'__rose_object'}->save(@_);
}

sub cloned_from {
  return shift->{'cloned_from'};
}

1;