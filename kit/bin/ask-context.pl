#!/usr/bin/perl
# Option 3 helper for start.sh (Linux/macOS; same logic as ask.ps1 on Windows).
# Writes the prompt for one question - matching vault text + the top encyclopedia articles - and prints the sources.
# Usage: perl ask-context.pl <vault dir or ""> <kiwix url or ""> <out file> <question>
use strict; use warnings; use File::Find; use Encode qw(decode);
binmode STDOUT, ':utf8';
my ($vault, $kiwix, $out, $q) = @ARGV;
my %stop = map { $_ => 1 } qw(the and for with what how who why when where which does did can should would could
  are was were has had have this that these those from into about there their them they will not but all any some you your our);
my ($budget_vault, $budget_article) = (12000, 5000);  # chars; ~8k tokens total keeps a 16k context and a CPU usable
my %seen; my @words = grep { length >= 3 && !$stop{$_} && !$seen{$_}++ } split /[^a-z0-9]+/, lc $q;

sub chunks {  # paragraphs merged into ~700-char pieces
  my ($t, @o) = (shift); my $c = '';
  for my $p (split /\r?\n/, $t) {
    $p =~ s/^\s+|\s+$//g; next unless length $p;
    if (length $c && length($c) + length($p) > 700) { push @o, $c; $c = '' }
    $c = length $c ? "$c\n$p" : $p;
  }
  push @o, $c if length $c; @o;
}
sub pick {  # best keyword matches within budget, in original order
  my ($ch, $budget, $keep_first) = @_; my (@s, @take); my $n = 0;
  for my $i (0 .. $#$ch) {
    my $l = lc $ch->[$i]; my $hits = grep { index($l, $_) >= 0 } @words;
    $hits += 99 if $keep_first && $i == 0;
    push @s, [$i, $hits] if $hits;
  }
  for my $x (sort { $b->[1] <=> $a->[1] || $a->[0] <=> $b->[0] } @s) {
    my $len = length $ch->[$x->[0]]; next if $n + $len > $budget;
    push @take, $x->[0]; $n += $len;
  }
  join "\n...\n", map { $ch->[$_] } sort { $a <=> $b } @take;
}
sub get {  # curl is on every target; LWP is not
  open my $f, '-|', 'curl', '-s', '--max-time', '20', shift or return '';
  local $/; my $r = <$f> // ''; close $f; decode('UTF-8', $r);
}
sub unent {
  my $h = shift; my %e = (amp => '&', lt => '<', gt => '>', quot => '"', apos => "'", nbsp => ' ');
  $h =~ s/&#(\d+);/chr $1/ge; $h =~ s/&#x([0-9a-f]+);/chr hex $1/gie; $h =~ s/&(\w+);/exists $e{$1} ? $e{$1} : "&$1;"/ge; $h;
}
sub text {  # article HTML -> plain text, references dropped
  my $h = shift;
  $h =~ s/<(script|style)\b.*?<\/\1>/ /gis; $h =~ s/<br\s*\/?>|<\/(?:p|li|h\d|tr|div|table)>/\n/gi; $h =~ s/<[^>]+>//g;
  $h = unent($h); $h =~ s/[ \t]+/ /g; $h =~ s/\[\d+\]//g; $h =~ s/^[ \t]*References[ \t]*\n.*//ms; $h;
}

my (@parts, @src);
if ($vault && -d $vault) {
  my @docs;
  find({ no_chdir => 1, wanted => sub {
    if (-d && m{/(\.[^/]+|System Volume Information|\$RECYCLE\.BIN)$}) { $File::Find::prune = 1; return }
    push @docs, $_ if -f && /\.(txt|md)$/i && !/\.llm-context\.txt$/;
  } }, $vault);
  my @ch;
  for my $d (sort @docs) {
    open my $f, '<:encoding(UTF-8)', $d or next; local $/; my $t = <$f> // ''; close $f;
    (my $name = $d) =~ s{.*/}{};
    push @ch, map { "[$name] $_" } chunks($t);
  }
  my $all = join "\n", @ch;
  my $picked = length($all) <= $budget_vault ? $all : pick(\@ch, $budget_vault);
  if (length $picked) {
    push @parts, "=== YOUR NOTES (from the vault) ===\n$picked";
    my %u; push @src, map { "Vault: $_" } grep { !$u{$_}++ } $picked =~ /^\[([^\]]+)\] /mg;
  }
}
if ($kiwix && @words) {
  (my $pat = join ' ', @words) =~ s/([^A-Za-z0-9])/sprintf '%%%02X', ord $1/ge;
  my $xml = get("$kiwix/search?pattern=$pat&format=xml&pageLength=2");
  while ($xml =~ /<item>(.*?)<\/item>/gs) {
    my $it = $1;
    my ($title) = $it =~ /<title>(.*?)<\/title>/s; my ($link) = $it =~ /<link>(.*?)<\/link>/s;
    my ($book) = $it =~ /<book>.*?<title>(.*?)<\/title>/s;
    next unless $link;
    $title = unent($title // ''); $book = unent($book // 'Encyclopedia');
    push @parts, "=== ENCYCLOPEDIA ARTICLE: $title ===\n" . pick([chunks(text(get($kiwix . unent($link))))], $budget_article, 1);
    push @src, "$book: $title";
  }
}
open my $o, '>:utf8', $out or die "cannot write $out\n";
print $o <<"EOT";
You are a calm, practical assistant, possibly helping in an emergency. Answer using the SOURCES below.
After each point, name its source in brackets: the exact article title or file name shown below. If the sources do not cover
the question, say so plainly, then give general knowledge marked "(not from your sources)".
For medical questions: give clear practical steps and say when to get professional help. Be concise.
=== SOURCES ===
EOT
print $o @parts ? join("\n\n", @parts) : '(none found)', "\n";
close $o;
print "  - $_\n" for @src;
