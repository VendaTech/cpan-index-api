use strict;
use warnings;

use Test::Most;
use Data::Dumper;
use CPAN::Index::API::File::Whois;

my $whois = <<'EndOfWhois';
<?xml version="1.0" encoding="UTF-8"?>
<cpan-whois xmlns='http://www.cpan.org/xmlns/whois'
            last-generated='Tue Sep 18 04:19:04 2012 GMT'
            generated-by='Id'>
 <cpanid>
  <id>AFOXSON</id>
  <type>author</type>
  <fullname></fullname>
 </cpanid>
 <cpanid>
  <id>YOHAMED</id>
  <type>author</type>
  <fullname></fullname>
  <email>moe334578-pause@yahoo.com</email>
 </cpanid>
</cpan-whois>
EndOfWhois

my $index = CPAN::Index::API::File::Whois->read_from_string($whois);

warn $index->content;

ok 1;

done_testing;
