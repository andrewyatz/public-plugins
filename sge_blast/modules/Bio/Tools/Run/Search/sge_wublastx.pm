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


=head1 NAME

Bio::Tools::Run::Search::sge_wublastx - SGE BLASTX searches

=head1 SYNOPSIS

  see Bio::Tools::Run::Search::SGE_WuBlast
  see Bio::Tools::Run::Search::wublastx

=head1 DESCRIPTION

Multiple inheretance object combining
Bio::Tools::Run::Search::SGE_WuBlast and
Bio::Tools::Run::Search::wublastx

=cut

# Let the code begin...
package Bio::Tools::Run::Search::sge_wublastx;
use strict;

use vars qw( @ISA );

use Bio::Tools::Run::Search::SGE_WuBlast;
use Bio::Tools::Run::Search::wublastx;

@ISA = qw( Bio::Tools::Run::Search::SGE_WuBlast 
           Bio::Tools::Run::Search::wublastx );

BEGIN{
}

# Nastyness to get round multiple inheretance problems.
sub program_name{return Bio::Tools::Run::Search::wublastx::program_name(@_)}
sub algorithm   {return Bio::Tools::Run::Search::wublastx::algorithm(@_)}
sub version     {return Bio::Tools::Run::Search::wublastx::version(@_)}
sub parameter_options{
  return Bio::Tools::Run::Search::wublastx::parameter_options(@_)
}

#----------------------------------------------------------------------
1;

