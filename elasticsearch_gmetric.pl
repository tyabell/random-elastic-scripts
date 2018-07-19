#!/usr/bin/perl

# Submits the number of active shards, VmPeak, VmSize, and open file descriptors to Ganglia
use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;

my $gmetric = "/usr/bin/gmetric";
my $host = "http://localhost:9200";
my $health = "/_cluster/health";
my $stats = "/_nodes/stats/process";
my $pid_file = "/var/run/elasticsearch/elasticsearch.pid";
my $pid;
my $VmPeak;
my $VmSize;
my $fh;

# Get the number of active_shards
my $ua = LWP::UserAgent->new;
my $response = $ua->get("$host" . "$health");
( my $active_shards ) = $response->decoded_content =~ m{"active_shards":(\d+)};
$response = $ua->get("$host" . "$stats");
( my $open_file_descriptors ) = $response->decoded_content =~ m{"open_file_descriptors":(\d+)};

# Get PID of Elasticsearch
open ( $fh, $pid_file);
    $pid = <$fh>;
close ($fh);

# Get values for VmPeak and VmSize
my $status = "/proc/$pid/status";
open ( $fh, $status) or die;
    while ( my $row = <$fh> ) {
        if ( $row =~ /VmPeak:\s+(\d+)/m ) {
            $VmPeak = $1;
        }
        if ( $row =~ /VmSize:\s+(\d+)/m ) {
            $VmSize = $1;
        }
    }
close ($fh);

# Submit everything to Ganglia
#print "$active_shards\n";
#print "$open_file_descriptors\n";
system(`$gmetric --name="Elasticsearch_Active_Shards" --value="$active_shards" --units="shards" --type="int32"`);
system(`$gmetric --name="Elasticsearch_Open_File_Descriptors" --value="$open_file_descriptors" --units="file_descriptors" --type="int32"`);
system(`$gmetric --name="Elasticsearch_VmPeak" --value="$VmPeak" --units="kB" --type="int32"`);
system(`$gmetric --name="Elasticsearch_VmSize" --value="$VmSize" --units="kB" --type="int32"`);
