use File::Find;
sub process_file {
return if -d;
    $file = $File::Find::name;
    if($file =~ /\/(.*?)\/wcat-output\.log/) {
    print "Processing $file\n";
        $scenario = $1;
        open DAT, "< $file";
seek DAT, -5000, 2;
        while(<DAT>)
        {
             if(/DURATION\s*(\d+)\//)
             {
                 $myhash{$scenario}{"Duration"} = $1*1.0/60/60;                 
             }  
             if(/Normal Requests\s*=\s*(\d+) \(\s*(\d+)\/sec/)
             {
                 $myhash{$scenario}{"TotalRequests"} = $1;                 
                 $myhash{$scenario}{"Throughput"} = $2;                 
             }  
             if(/Total Errors\s* =\s*(\d+) /)
             {
                 $myhash{$scenario}{"TotalErrors"} = $1; 
		$myhash{$scenario}{"Reliability"} = ($myhash{$scenario}{"TotalRequests"} - $myhash{$scenario}{"TotalErrors"})*100/$myhash{$scenario}{"TotalRequests"};                 
             }  
             if(/Time To Last Byte\s* =\s*(\d+) /)
             {
                 $myhash{$scenario}{"Latency"} = $1;                 
             }  
        }
        close(DAT);
    }
}
find(\&process_file, @ARGV);
printf "%-50s %-12s %-15s %-15s %-15s %-15s %-15s\n","Scenario","Duration","TotalRequests", "TotalErrors" , "Latency", "Throughput", "Reliability";
foreach $key (sort keys %myhash)
{ next if ($key =~ /Private/);
    printf "%-50s %-12.4s %-15s %-15s %-15s %-15s %-15s\n", $key, $myhash{$key}{"Duration"}, $myhash{$key}{"TotalRequests"},$myhash{$key}{"TotalErrors"} ,
    $myhash{$key}{"Latency"} ,$myhash{$key}{"Throughput"}, $myhash{$key}{"Reliability"};
#    push( @{$results{$key}} , {$key, $myhash{$key}{"throughput"}, $myhash{$key}{"latency"},$myhash{$key}{"cpu"} ,
 #   $myhash{$key}{"memory"} ,$myhash{$key}{"requests"}, $myhash{$key}{"throughputRatio"},  $myhash{$key}{"latencyRatio"}, $myhash{$key}{"memoryRatio"}});
}

open DAT, ">summary.csv";
print DAT "Scenario,Throughput,Latency,CPU,Memory,Requests\n";
foreach $key (sort keys %myhash)
{
#    printf DAT "%s,%s,%s,%s,%s,%s\n", $key, $myhash{$key}{"throughput"}, $myhash{$key}{"latency"},$myhash{$key}{"cpu"} ,$myhash{$key}{"memory"},$myhash{$key}{"memory"};
}
close(DAT);

