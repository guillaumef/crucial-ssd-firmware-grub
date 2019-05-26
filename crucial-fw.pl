#!/usr/bin/perl

use strict;
use LWP::UserAgent();
use HTTP::Request();
use Archive::Extract();
use Archive::Zip();
use File::Copy qw/move/;
use File::Basename qw/dirname/;

my $LDIR      = dirname( $0 );
## K/V list file of FW to download
my $LIST      = "$LDIR/crucial-fw.cfg";
## Put downloaded firmware here (raw zip files)
my $DWN_DIR   = "$LDIR/crucial-fw";
## Temporary directory for loopback mount
my $MNT_DIR   = "$LDIR/mnt";
## Grub target file
my $GRUB_FILE = "/etc/grub.d/45_crucial-fw";
## Grub target directory
my $ISO_DIR   = "/boot/crucial-fw";

my @local_disks = ();
my @args = @ARGV;
while (@args) {
  $_ = shift @args;
  if (/^(-h|--help)$/) {
    print <<EOF;
 $0 <options>
   Options:
     -h | --help  : usage
     -a | --all   : generate all grub menu entries
                    (default behavior is to scan for SSD types)
     -t | --type  : specific ssds type to generate (multiple allowed)
     -l | --list  : list ssds type managed
EOF
    exit(0);
  }
  if (/^(-a|--all)$/) {
    my $rh = &load_cfg();
    @local_disks = keys %{$rh};
  }
  if (/^(-t|--type)$/) {
    push @local_disks, (shift @args);
  }
  if (/^(-l|--list)$/) {
    my $rh = &load_cfg();
    print "SSDs managed:\n\t",join( "\n\t" , sort {$a cmp $b} keys %{$rh} )."\n";
    exit(0);
  }
}

#
# Work...
#

sub err { print STDERR join(' ', ('Err:', @_))."\n"; exit(1); }
sub warn { print STDERR join(' ', ('Warn:', @_))."\n"; }

sub get_ssd_mdl
{
	my @disks=`ls -1 /dev/disk/by-id/ata*`;
	chomp @disks;
	my @valid_Disks;
	foreach (@disks)
	{
		chomp;
		my $Model;
		next if ($_ =~ /-part\d+$/);
		if ($_ =~ /[Cc]rucial/)
		{
			if ($_ =~ m/[Cc]rucial_[a-zA-Z]+[0-9]*([a-zA-Z]+\d*)[A-Z]*\d*/i)
			{
				push(@valid_Disks,uc($1));
			}
		}
		elsif ($_ =~ /-M4-/)
		{
			push(@valid_Disks,'M4');
		}
		elsif ($_ =~ /ata-CT\d+/)
		{
			$_ =~ m/ata-[A-Z]+\d+([a-zA-Z]+\d*)[a-zA-Z]+\d+/;
			push(@valid_Disks,uc($1));
		}
		elsif ($_ =~ /[Ss]amsung/i)
		{
			$_ =~ m/.*_SSD_(\d+_[a-zA-Z]*)_.*/;
			push(@valid_Disks,uc($1));
		}
		elsif ($_ =~ /ata-C300-/)
		{
			push(@valid_Disks,'C300');
		}
		elsif ($_ =~ /ata-INTEL_SSDSA2M/)
		{
			push(@valid_Disks,'X25-M');
		}
		else
		{
			next;
		}
	}
	return @valid_Disks;
}

sub load_cfg
{
  my %h;
  open FH, $LIST || &err(".cfg file not found", $_);
  while (<FH>) {
    chomp;
    next if (/^\s*#/ || /^\s*$/);
    my ($n,$dwl) = (/^\s*(\w+)\s+([^\s]*)/);
    if (!$n) {
      &err( "Unknown line in list file", $_ );
    }
    $h{$n} ||= [];
    push @{$h{$n}}, $dwl;
  }
  close FH;
  return \%h;
}

if (! -f $LIST) {
 &err( "Need list file" );
}

# Load list
my %hfw;
my %hdrop;

if (! @local_disks) {
  @local_disks = &get_ssd_mdl();
}
my $rhcfg       = &load_cfg();

foreach my $n (keys %{$rhcfg}) {
  my $ra = $rhcfg->{$n};
  foreach my $dwl (@{$ra}) {
    if (grep(/$n/,@local_disks)) { $hfw{$n} ||= []; push @{$hfw{$n}}, $dwl; }
    else { $hdrop{$n} ||= []; push @{$hdrop{$n}}, $dwl; }
  }
}

# Download
mkdir $DWN_DIR;
if (! -d $DWN_DIR) {
 &err( "Failed to create download directory", $DWN_DIR);
}

# Open target for grub
open FGB, ">$GRUB_FILE";
print FGB <<EOF;
#!/bin/sh
exec tail -n +3 \$0
submenu 'Crucial Firmware Update' {
EOF

# Remove unused files
foreach my $tg (keys %hdrop) {
  my $ra = $hdrop{ $tg };
  foreach my $url (@{$ra}) {
    my ($lf) = ($url =~ '/([^/]*)$');
    unlink( "$DWN_DIR/$lf" );
    unlink( "$ISO_DIR/$tg.iso" );
    for (1 .. 10) {
      unlink( "$ISO_DIR/$tg-$_.iso" );
    }
  }
}

# Get each file
my $ua;
my $nbactive = 0;
foreach my $tg (sort {$a cmp $b} keys %hfw) {
  my $ra = $hfw{$tg};
  my $id = 0;
  unlink "$ISO_DIR/$tg.iso";
  foreach my $url (@{$ra}) {
    $id ++;
    if (!$url || $url !~ /zip$/i) {
      &warn( "Only manage url zip file", $url );
    }
    my ($lf) = ($url =~ '/([^/]*)$');
    my $iso = $lf; $iso =~ s/zip$/iso/;

    print "Target: $tg #$id ($lf, $iso)\n";

    if (! -f "$DWN_DIR/$lf" || ! -f "$ISO_DIR/$tg-$id.iso") {
      print STDERR "  Downloading..";
      $ua ||= new LWP::UserAgent();
      my $req = new HTTP::Request(GET => $url);
      my $r = $ua->request($req)->content;
      open FH, ">$DWN_DIR/$lf" or &err("$! $DWN_DIR/$lf");
      binmode FH;
      print FH $r;
      close FH;
      print STDERR " done\n";

      print STDERR "  Uncompressing..";
      my $ae = new Archive::Extract( archive => "$DWN_DIR/$lf" );
      my $ok = $ae->extract( to => $DWN_DIR );
      if (! $ok) {
        unlink "$DWN_DIR/$lf";
        &err( "Failed to extract file - wrong zip ?" );
      }
      my $iso = $ae->files->[0];
      print STDERR " $iso";
      if (! -f "$DWN_DIR/$iso") {
        &err( "Unable to get iso associated" );
      }
      print STDERR " done\n";

      print STDERR "  Moving to $tg-$id.iso";
      mkdir $ISO_DIR;
      move("$DWN_DIR/$iso", "$ISO_DIR/$tg-$id.iso");
      print STDERR " done\n";
    }

    if (! -f "$ISO_DIR/$tg-$id.iso") {
      print STDERR " unable to get $tg-$id.iso\n";
      exit(0);
    }

    print STDERR "  Mounting";
    mkdir $MNT_DIR;
    `mount -o loop $ISO_DIR/$tg-$id.iso $MNT_DIR 2> /dev/null`;
    print STDERR " done\n";

    if (! -d "$MNT_DIR/boot") {
      print STDERR " Failed to proceed, must be a problem with module isofs\n";
      rmdir $MNT_DIR;
      exit(0);
    }

    $nbactive ++;
    print STDERR "  Grub -> mode";
    print FGB <<EOF;
menuentry "$tg $id FW" {
 insmod loopback
 set isofile="$ISO_DIR/$tg-$id.iso"
 search -sf \$isofile
 loopback loop \$isofile
EOF

    if (-f "$MNT_DIR/boot/isolinux/memdisk" && -f "$MNT_DIR/boot/isolinux/boot2880.img") {
      print STDERR " linux16";
      print FGB <<EOF;
 linux16 (loop)/boot/isolinux/memdisk
 initrd16 (loop)/boot/isolinux/boot2880.img
EOF
      print STDERR " done\n";
    }
    elsif (-f "$MNT_DIR/boot/vmlinuz" && -f "$MNT_DIR/boot/core.gz") {
      print STDERR " initrd";
      my $append = &parse_isolinux( 'APPEND' );
      print FGB <<EOF;
 linux (loop)/boot/vmlinuz $append
 initrd (loop)/boot/core.gz
EOF
    }
    elsif (-f "$MNT_DIR/boot/vmlinuz64" && -f "$MNT_DIR/boot/corepure64.gz") {
      print STDERR " initrd";
      my $append = &parse_isolinux( 'APPEND' );
      print FGB <<EOF;
 linux (loop)/boot/vmlinuz64 $append
 initrd (loop)/boot/corepure64.gz
EOF
    }
    else {
      print STDERR " Unknown, failed.";
    }
    print FGB "}\n";
    print STDERR " done\n";

    print STDERR "  Unmounting";
    `umount $MNT_DIR`; 
    print STDERR " done\n";

    rmdir $MNT_DIR;
  }
}
print FGB "}\n";
close FGB;

if ($nbactive) {
  chmod 0755, $GRUB_FILE;

  print STDERR "\n";
  print STDERR "Generated in: $GRUB_FILE\n";
  print STDERR "      ISO in: $ISO_DIR\n";
  print STDERR "\n";
}
else {
  print STDERR "\n";
  print STDERR "No fw activated\n";
  print STDERR "\n";
  unlink( $GRUB_FILE );
}

exec('/usr/sbin/update-grub');


sub parse_isolinux {
 my $key = shift;
 my $out = '';
 open FH, "$MNT_DIR/boot/isolinux/isolinux.cfg";
 while (<FH>) {
  chomp;
  if (/\s*$key\s+(.*)/i) {
   $out = $1;
   last;
  }
 }
 close FH;
 return $out;
}


1;
__END__
