#!/usr/bin/perl
#  
#  Report how much disk space each user is consuming.
#
#
# TODO:  maybe check more than just /home
#

#
# User Stats
#
my %users;
# $users{$username} --> [ UID, Description, Home dir, MB used in home dir ]
my $num_total_users;
#
# same as %users except only include users using more than 1MB
my %users_active;
my $active_threshold = 1;
my $num_active_users;
#
my @active_userids;
my $usage_active_total = 0;
my $usage_active_max;
my $usage_active_avg;
my $usage_active_median;


#
# Collect RAW data
#

my $date = `date`;
chomp $date;

my $dftxt = `/bin/df -P /home | /usr/bin/tail -n 1`;
chomp $dftxt;

my $pwtxt = `/bin/cat /etc/passwd`;
chomp $pwtxt;

my $dutxt = `/usr/bin/du -ms /home/\*`;
chomp $dutxt;



#
# make sense of the data
#

my @dfhome = split('\s+', $dftxt);

foreach my $l ( split('\n', $pwtxt) ) {
    my @fields = split(':', $l);
    my $uid  = $fields[2] ;
    #if ( $uid > 499 && $uid < 1001 ) {
    # skip amur (501) and kbende (503)
    if ( $uid > 501 && $uid < 1000 && $uid != 503 ) {
        $users{ $fields[0] } = [ $uid, $fields[4], $fields[5], 0 ];
    }
}

my %duinfo;
foreach my $l ( split('\n', $dutxt) ) {
    my @fields = split('\s+', $l);
    $duinfo{$fields[1]} = $fields[0];
} 

foreach my $u ( sort keys %users ) {
    # get du info for the home dir
    $users{$u}[3] = $duinfo{ $users{$u}[2] };
}


foreach my $u ( keys %users ) {
    # check if using more than 1MB
    #print "$users{$u}[3] >?  $active_threshold  \n";
    if ( $users{$u}[3] > $active_threshold ) {
        $users_active{$u} = $users{$u};
        $usage_active_total += $users{$u}[3];
    }
}

$num_total_users = scalar keys %users;

# active users, sorted from largest to smallest
foreach my $u ( sort { $users_active{$b}[3] <=> $users_active{$a}[3] }  keys %users_active ) {
   #print "-- $u - $users_active{$u}[3] \n";
   push @active_userids, $u;
}

$num_active_users = scalar @active_userids;
$usage_active_max = $users{$active_userids[0]}[3];

$usage_active_avg = int $usage_active_total / $num_active_users;

my $med_num = int ($num_active_users / 2);
my $med_uid = $active_userids[$med_num];
$usage_active_median = $users_active{$med_uid}[3];




#
# Print out the info
#


print " \n";
print "Disk usage report for MICROCORE\n";
print "-------------------------------\n";
print " \n";
print "  $date \n";
print " \n";


print " \n";
print "Summary of Usage: \n";
print " \n";
print "----------------------   --------  \n";
printf("%20s    %8d \n",                     "Total # of users:",  $num_total_users);
printf("%20s    %8d      (Threshold: %d MB) \n", "Active # of users:", $num_active_users, $active_threshold);
printf("%20s    %8d  MB \n",                     "Usage Max:",  $usage_active_max);
printf("%20s    %8d  MB  (Among active users) \n",                     "Usage Mean:",  $usage_active_avg);
printf("%20s    %8d  MB  (Among active users) \n",                     "Usage Median:",  $usage_active_median);
print "----------------------   --------  \n";
print " \n";



print " \n";
print "Usage per drive: \n";
print " \n";
print "  MB used  Mount Point   % Full \n";
print "---------  ------------  ------\n";
printf("%8d    %-12s %4s \n", $dfhome[2]/(1024), $dfhome[5], $dfhome[4]);
print "---------  ------------  ------\n";
print " \n";




print " \n";
print "Usage per directory: \n";
print " \n";
print "  MB used  Home Directory     User \n";
print "---------  -----------------  ------------------------\n";
foreach my $u ( sort keys %users ) {
    #print "$u --- $users{$u}[0] --\n";
    printf("%8d    %-16s  %-24s \n", $users{$u}[3], $users{$u}[2], $users{$u}[1] );
    
}
print "---------  -----------------  ------------------------\n";
print " \n";


print " \n";



