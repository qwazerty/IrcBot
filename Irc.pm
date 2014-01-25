#!/usr/bin/perl

package Irc;

# Imports
use strict;
use warnings;
use threads;
use IO::Socket::INET;
use Time::HiRes qw (sleep);

# Flush after write
$| = 1;

sub new {
    my $class = shift;
    my $self = {
        _host => shift,
        _port => shift,
        _proto => shift,
        _nick => shift,
        _pass => shift,
        _chan => shift,
        _socket => undef,
    };
    bless $self, $class;
    return $self;
}

sub connect {
    my ($self, $host, $port, $proto) = @_;
    if ($host) {
        $self->{_host} = $host;
    }
    if ($port) {
        $self->{_port} = $port;
    }
    if ($proto) {
        $self->{_proto} = $proto;
    }
    $self->{_socket} = new IO::Socket::INET (
        PeerHost => $self->{_host},
        PeerPort => $self->{_port},
        Proto => $self->{_proto},
    ) or die "Could not create socket : $!\n";

    print "Connected to $self->{_host} on port $self->{_port}.\n";
    my $thread = threads->create(sub {
        while (1) {
            sleep (60);
            $self->{_socket}->send("PING\n");
        }
    });
}

sub authenticate {
    my ($self, $nick, $pass) = @_;
    if ($nick) {
        $self->{_nick} = $nick;
    }
    if ($pass) {
        $self->{_pass} = $pass;
    }
    if (defined $self->{_pass}) {
        $self->{_socket}->send("PASS $self->{_pass}\n");
    }
    $self->{_socket}->send("NICK $self->{_nick}\n");
}

sub join {
    my ($self, $chan) = @_;
    if ($chan) {
        $self->{_chan} = $chan;
    }
    $self->{_socket}->send("JOIN $self->{_chan}\n");
    print "Joined channel $self->{_chan}.\n";
}

sub run_listen {
    my ($self) = @_;
    my $socket = $self->{_socket};
    while (1)
    {
        my $data = <$socket>;
        if (defined $data) {
            if ($data =~ /:(\w*)[^\s]* PRIVMSG $self->{_chan} :(.*)$/) {
                print "[$1] $2\n";
            }
            else {
                print "[DEBUG] $data";
            }
        }
    }
}
