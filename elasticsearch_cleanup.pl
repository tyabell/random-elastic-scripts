#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use DateTime;
use Log::Log4perl;
use List::MoreUtils qw(uniq);
use LWP::UserAgent;

my $logging_config = q(
    log4perl.rootLogger = INFO, SYSLOG
    log4perl.appender.SYSLOG = Log::Dispatch::Syslog
    log4perl.appender.SYSLOG.min_level = info
    log4perl.appender.SYSLOG.ident = elasticsearch_cleanup.pl
    log4perl.appender.SYSLOG.facility = LOCAL0
    log4perl.appender.SYSLOG.layout = PatternLayout
    log4perl.appender.SYSLOG.layout.ConversionPattern=%F %L %c - %m%n
);
Log::Log4perl::init( \$logging_config );
my $log = Log::Log4perl->get_logger();

my $host="http://localhost:9200";
my $ua = LWP::UserAgent->new;
my $dt = DateTime->now;
my $ymd = $dt->subtract( months => 12 )->ymd('.');

# Get the indices from Elasticsearch, toss them in an array and sort them
my $get_indices = $ua->get("$host/_cat/indices?h=index");
my @indices = split('\n', $get_indices->decoded_content);

# We want the title of each index 'logstash or logstash-$foo' but not 'logstash-$foo-YYYY.MM.DD,
# and we want them unique so we aren't trying multiple deletes on each index
my @unique;
foreach my $index(@indices) {
    # Here we capture (logstash|logstash-$foo) but we don't include YYYY.MM.DDD
    if ( $index =~ /(logstash.*?-(?=\d+))/m ) {
        push @unique, $1;
    }
}
@unique = uniq(@unique);

# For each unique index, we're going to delete the logs
foreach my $index(@unique) {
    $log->info("Found $index for clean-up");
    my $delete_index = HTTP::Request->new(DELETE => "$host/$index$ymd/");
    my $tmp = $ua->request($delete_index);
    if ($tmp->is_success) {
        $log->info("Deleting Elasticsearch Index $index$ymd completed");
    }
    else {
        $log->info("Deleting Elasticsearch Index $index$ymd failed");
    }
}
