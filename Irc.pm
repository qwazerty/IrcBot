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
        host => shift,
        port => shift,
        proto => shift,
        nick => shift,
        pass => shift,
        chan => shift,
        socket => undef,
    };
    bless $self, $class;
    return $self;
}

sub connect {
    my ($self, $host, $port, $proto) = @_;
    if ($host) {
        $self->{host} = $host;
    }
    if ($port) {
        $self->{port} = $port;
    }
    if ($proto) {
        $self->{proto} = $proto;
    }
    $self->{socket} = new IO::Socket::INET (
        PeerHost => $self->{host},
        PeerPort => $self->{port},
        Proto => $self->{proto},
    ) or die "Could not create socket : $!\n";

    print "Connected to $self->{host} on port $self->{port}.\n";
    my $thread = threads->create(sub {
        while (1) {
            $self->{socket}->send("PING\n");
            print "[DEBUG] PING $self->{host}.\n";
            sleep (60);
        }
    });
}

sub authenticate {
    my ($self, $nick, $pass) = @_;
    if ($nick) {
        $self->{nick} = $nick;
    }
    if ($pass) {
        $self->{pass} = $pass;
    }
    if (defined $self->{pass}) {
        $self->{socket}->send("PASS $self->{pass}\n");
    }
    $self->{socket}->send("NICK $self->{nick}\n");
}

sub join {
    my ($self, $chan) = @_;
    if ($chan) {
        $self->{chan} = $chan;
    }
    $self->{socket}->send("JOIN $self->{chan}\n");
    print "Joined channel $self->{chan}.\n";
}

sub run_listen {
    my ($self) = @_;
    my $socket = $self->{socket};
    while (1)
    {
        my $data = <$socket>;
        if (defined $data) {
            if ($data =~ /:(\w*)[^\s]* PRIVMSG $self->{chan} :(.*)$/) {
                print "[$1] $2\n";
            }
        }
    }
}
