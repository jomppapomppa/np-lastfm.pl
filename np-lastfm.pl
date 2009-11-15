# np-last.fm v0.2 - Joni Rantala
# ------------------------------------------------
#
# 1. Copy np-lastfm.pl to ~/.irssi/scripts/ folder
# 2. Change username (in %CONFIG) to your Last.fm username
# 3. Type /script load np-lastfm to irssi
# 4. Type /np to show now playing
#

use strict;
use LWP;
use Irssi;
use vars qw(%CONFIG $VERSION %IRSSI);

my %CONFIG = (
  # Your Last.fm username
  username  => "",
  # Format of the now playing message (variables %artist %track)
  np_format => "np: %artist - %track",
  # Message if no track is playing
  no_track  => "No track playing =("
);

$VERSION = "0.2";
%IRSSI   = (
  authors     => "Joni Rantala",
  contact     => "jomppa(at)jomppa.net",
  name        => "Last.fm Now Playing",
  description => "Simple now playing script that gets current artist and track name from Last.fm",
  license     => "GPL"
);

sub get_tracks {
  my $url = "http://ws.audioscrobbler.com/2.0/user/${CONFIG{'username'}}/recenttracks.xml";
  my $req = HTTP::Request->new("GET", $url);
  my $ua  = LWP::UserAgent->new(keep_alive => 1, timeout => 5);
  $ua->agent("LastFmNpScript0.2");
  my $res = $ua->request($req);
  if ($res->is_success()) {	
    return($res->content());
  }
  return(0);
}

sub playing_track($) {
  my ($data)  = @_;
  $data =~ s/((\s{2,}|\n))//g;
  return(undef) unless $data =~ /nowplaying=\"true\"/;
  my ($start, $len, $artist, $track);
  $start  = index($data, "<track");
  $len    = index($data, "</track>") + 8 - $start;
  $data   = substr($data, $start, $len);
  $data   =~ /([^>]+)<\/artist><name>(.*)<\/name/;
  $artist = $1;
  $track  = $2;
  return(($artist, $track));
}

sub format_track() {
  my (@data) = playing_track(get_tracks());
  return("") if (scalar @data != 2);
  my $format;
  my ($artist, $track) = @data;
  $format = $CONFIG{'np_format'};
  $format =~ s/%artist/$artist/e;
  $format =~ s/%track/$track/e;
  return($format);
}

sub now_playing() {
  my ($data, $server, $window) = @_;
  return unless $window;
  my $np = format_track();
  if ($np eq "") {
    $window->print($CONFIG{'no_track'});
  }
  else {
    $window->command("MSG $window->{name} ${np}");
  }
}

Irssi::command_bind np => \&now_playing;
