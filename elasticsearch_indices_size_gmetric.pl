#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use DateTime;
use JSON::XS;
use LWP::UserAgent;

my $gmetric = '/usr/bin/gmetric';
my $ymd = DateTime->now->ymd('.');
my $host = 'http://localhost:9200';
my $ua = LWP::UserAgent->new;
my $url = "$host/*-$ymd/_stats/store";

my $get_stats = $ua->get($url);
my $response;
if ($get_stats->is_success) {
    $response = decode_json($get_stats->content);
}
else {
    die $response->status_line;
}

my $total_size = $response->{_all}->{total}->{store}->{size_in_bytes};
system(`$gmetric --name="elasticsearch_total" --value="$total_size" --units="bytes" --type="float"`);

my $indices = $response->{indices};

foreach my $index (keys %$indices) {
    my $store_size = $indices->{$index}->{total}->{store}->{size_in_bytes};
    # Strip off YYYY.MM.DD
    $index =~ s/-$ymd//g;
    # - to _
    $index =~ s/-/_/g;
    system(`$gmetric --name="$index" --value="$store_size" --units="bytes" --type="float"`);
}
