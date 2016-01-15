#!/usr/bin/perl
#
# Script that checks nginx cache zones size and compare to max_size on config.
# Will check if cache zone is near max size and warn if true.
# Will check if cache zone it's empty and warn if true
#
# Warning: it assume all cache paths max_size are set in gb
#
# Questions or beers: <guzman.braso@gmail.com>
#
use warnings;
use strict;

# Directory to explore for cache folders:
my $cachedir = "/var/nginx-cache/";
# Directory to check for proxy_cache_path settings
my $confdir = "/etc/nginx/conf.d/";
# top usage % to consider a cache small
my $small_threshold = "20";
# top usage % to consider a cache normal
# everything above will generate a warning
my $normal_threshold = "60";

my @cache_dirs = grep { -d } glob "$cachedir".'*';
my @config_lines = `grep proxy_cache_path ${confdir}*`;

if ($ARGV[0] && $ARGV[0] eq "help") {
  print "Usage: $0 [help|summary|show_empty]\n";
  exit 0;
}

sub dirSize {
  my($dir)  = @_;
  my($size) = 0;
  my($fd);
 
  opendir($fd, $dir) or die "$!";
 
  for my $item ( readdir($fd) ) {
    next if ( $item =~ /^\.\.?$/ );
 
    my($path) = "$dir/$item";
 
    $size += ((-d $path) ? dirSize($path) : (-f $path ? (stat($path))[7] : 0));
  }
 
  closedir($fd);
 
  return($size);
}

my $i = 0;
my @empty_caches;
my @small_caches;
my @normal_caches;
my @warning_caches;
my %all_caches;
foreach my $configline (@config_lines) {
  my ( $cache_path ) = $configline =~ m/proxy_cache_path (.*) levels/i;
  $all_caches{$cache_path}=1;
  my ( $cache_max_size ) = $configline =~ m/max_size=(.*)g\;/i;
  my $cache_max_size_bytes = $cache_max_size * 1024 * 1024 * 1024;
  my $cache_max_size_human = $cache_max_size." GB";
  my $cache_real_size = dirSize($cache_path);
  my $cache_real_size_human = ($cache_real_size / 1024 / 1024 / 1024) ." GB";
  if ($cache_real_size == 0) {
    push (@empty_caches,$cache_path);
  } else {
    my $cache_used_percentage =  int( (($cache_real_size * 100) / $cache_max_size_bytes) + 0.5);
    if ($cache_used_percentage < $small_threshold) {
      push (@small_caches,$cache_path);
    } elsif ($cache_used_percentage < $normal_threshold) {
      push (@normal_caches,$cache_path);
    } else {
      push (@warning_caches,$cache_path);
      print "Warning: $cache_path - Usage: $cache_used_percentage% ($cache_real_size_human of $cache_max_size_human)\n";
    }
  }
  $i++;
} 

my $cachedir_useless = 0;
foreach my $cachedir (@cache_dirs) {
  if ( !$all_caches{$cachedir} || $all_caches{$cachedir} == 0) {
    $cachedir_useless++;
    print "Warning: Useless Dir not found in config: $cachedir\n";
  }
}

if ($ARGV[0] && $ARGV[0] eq "summary") {
  print "Found ".$#config_lines." configured cachepaths in nginx and ".$#cache_dirs." actual paths in nginx cache folder\n";
  print "Results:\n";
  print "- ". ( $#empty_caches + 1 )." empty caches (complete empty, 0 byte used)\n";
  print "- ". ( $#small_caches + 1 )." small caches (less than ${small_threshold}% used)\n";
  print "- ". ( $#normal_caches + 1 )." normal caches (between ${small_threshold}% and ${normal_threshold}% used)\n";
  print "- ". ( $#warning_caches + 1 )." warning caches (over ${normal_threshold}% used)\n";
  print "- ". $cachedir_useless ." directories not configured as cache\n";
}

if ($ARGV[0] && $ARGV[0] eq "show_empty") {
  foreach my $cachedir (@empty_caches) {
    print "0 byte cache: $cachedir\n";
  }
}

# Nice exit values, false if any warning, else true.
exit 1 if ($cachedir_useless > 0 || $#warning_caches != -1 );
exit 0;
