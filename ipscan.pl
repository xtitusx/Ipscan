#!/usr/bin/perl

@ipconfig = `ipconfig`;

foreach (@ipconfig)
{
      if ((m/Adresse IPv4/) || (m/IPv4 Address/))
      {
        $ipconfig = $_;
        $ipconfig =~ s/\ //g;
        @ipaddress = split(/:/,$ipconfig);
        $ipaddress = @ipaddress[1];
        chomp $ipaddress;
      }

      if ((m/Masque de sous-r.{1}?seau/) || (m/Subnet Mask/))
      {
        $ipconfig = $_;
        $ipconfig =~ s/\ //g;
        @netmask = split(/:/,$ipconfig);
        $netmask = @netmask[1];
        chomp $netmask;
      }
}

@networkoct123 = split(/\./, $ipaddress);
$networkoct123 = @networkoct123[0].'.'.@networkoct123[1].'.'.@networkoct123[2].'.';

$pattern =   $networkoct123.'*';
@route_print = `route print $pattern`;

foreach (@route_print)
{
      if (m/$networkoct123/)
      {
        $route_print = $_;
        @network =split(/\ /,$route_print);
        foreach (@network)
        {
            if (m/$networkoct123/)
            {
                $network = $_;
                chomp $network;
                last;
            }
        }
        last;
      }
}

@ip_start = split(/\./, $network);
$ip_start = @ip_start[3] + 1;

@ip_range = split(/\./, $netmask);

if (@ip_range[0] ne "255" | @ip_range[1] ne "255" | @ip_range[2] ne "255")
{
  die "Error Network Address : Class C required\n";
}

$ip_range = @ip_range[3];
$ip_range = 255 - $ip_range - 1;
$ip_end = $ip_start + $ip_range;

$broadcast = @networkoct123[0].'.'.@networkoct123[1].'.'.@networkoct123[2].'.'.$ip_end;

printf ("%s", "IPADDRESS : $ipaddress\n");
printf ("%s", "NETMASK : $netmask\n");
printf ("%s", "NETWORK : $network\n");
printf ("%s", "BROADCAST : $broadcast\n");
printf ("%s", "\n");
printf ("%s", "IP Address\tMAC Address\n");

%date_res;
%ping_res;
%arp_res;
%reverse_ping_res;

for ($i=$ip_start;$i<$ip_end;$i++) {

    $date_res{$networkoct123.$i} = Date();
    $ping_res{$networkoct123.$i} = `ping -n 1 $networkoct123$i`;
    $arp_res{$networkoct123.$i} = `arp -a $networkoct123$i`;
}

keys %ping_res;
%reverse_ping_res = reverse %ping_res;

$tmp = $ipaddress;
$tmp =~ s/\.|\r|\n|\t//g;

for ($i=$ip_start;$i<$ip_end;$i++) {

  foreach $ping_res(values %ping_res) {

    $ip_temp = $reverse_ping_res{$ping_res};
    @ip_temp = split(/\./,$ip_temp);
    $ip_temp = @ip_temp[3];

    if ($i eq $ip_temp)
    {
      $save_ping_res = $ping_res;
      $ping_res =~ s/\ |\r|\n|\t//g;

      $n=$ping_res=~m/(perte0%|[^10]0%loss)/;

      if ($n eq 1 )
      {
        $ip = $reverse_ping_res{$save_ping_res};
        $tmp2 = $ip;
        $tmp2 =~ s/\.|\r|\n|\t//g;

        if ($tmp eq $tmp2)
        {
          @ipconfigall = `ipconfig /ALL`;
          foreach (@ipconfigall)
          {
            $line = $_;
            $line =~ s/\ |\r|\n|\t//g;
            $n=$line=~ m/(Adressephysique|PhysicalAddress)/;

            if ($n eq 1)
            {
              $ipconfigall = $line;
              @mac = split(/:/,$ipconfigall);
              $mac = @mac[1];
              $mac =~ s/\r|\n|\t//g;
              last;
            }
          }
        }
        else {         
          $arp = $arp_res{$ip};
          $arp =~ s/\n//g;
          $arp =~ s/\s+/\ /g;
          @mac = split(/\ /,$arp);
          $j = 0;
          $mac="N/A";
          foreach(@mac)
          {
            if (m/$ip/)
            {
              $mac = @mac[$j+1];
              last;
            }
            $j++;
          }
        }
        $date = $date_res{$ip};
        printf ("%s", "$ip\t$mac\n");
        open(IPSCAN, ">>ipscan.csv") || die "Unable to open ipscan.csv";
        print IPSCAN $ip.';'.$mac.';'.$date."\n";
        close(IPSCAN);
        }
      }
  }
}

print "\nAppuyez sur [Enter]";
<STDIN>;

sub Date
{
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

$time = "";
$day = "";

if (length ($hour) < 2) {$time = "0";}
$time = $time . $hour . ':';
if (length ($min) < 2) {$time = $time . "0";}
$time = $time . $min;

$mon = $mon + 1;
if (length($mon) < 2)  {$day = "0";}
$day = $day . $mon . '/';
if (length($mday) < 2) {$day = $day . "0";}
$day = $day . $mday;

$date = $time.'-'."20" . substr($year,1,2) . '/' . $day;
return $date;
}
