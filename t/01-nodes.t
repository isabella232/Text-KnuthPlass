#!perl
use strict;
use warnings;
use Test::More tests => 5;

# test 1
use_ok("Text::KnuthPlass");

my $t = Text::KnuthPlass->new(
    'hyphenator' => Text::KnuthPlass::DummyHyphenator->new(),
    'indent' => 0,
    'measure' => sub { 12 * length shift } 
);
sub dump_nodelist {
    my $output; 
    for (@_) {
        if ($_->isa("Text::KnuthPlass::Box")) { 
            $output .= "[".$_->value()."/".$_->width()."]";
        }
        if ($_->isa("Text::KnuthPlass::Glue")) {
            $output .= "<".$_->width()."+".$_->stretch()."-".$_->shrink().">";
        }
        if ($_->isa("Text::KnuthPlass::Penalty")) {
            $output .= "(".$_->penalty().($_->flagged() && "!").")";
        }
    }
    return $output;
}

# test 2
is( dump_nodelist($t->break_text_into_nodes("I am a test")),
    '[I/12]<12+6-4>[am/24]<12+6-4>[a/12]<12+6-4>[test/48]<0+10000-0>(-10000!)');

$t = Text::KnuthPlass->new(
    'measure' => sub { 12 * length shift } 
);

my @nodes = $t->break_text_into_nodes("Representing programmable hyphenation");
# test 3
is( dump_nodelist(@nodes),
    '[Rep/36](50!)[re/24](50!)[sent/48](50!)[ing/36]<12+6-4>[pro/36](50!)[grammable/108]<12+6-4>[hy/24](50!)[phen/48](50!)[ation/60]<0+10000-0>(-10000!)');

$t = Text::KnuthPlass->new(
    'linelengths' => [52],
    'tolerance' => 30,
    'indent' => 0,
    'hyphenator' => Text::KnuthPlass::DummyHyphenator->new()
);
my $para= "This paragraph has been typeset using the classic Knuth and Plass algorithm, as used in TeX, plus the Liang hyphenation algorithm, implemented in Perl by Simon Cozens.";
my @lines = $t->typeset($para);
my $output;
for (@lines) {
    for (@{$_->{'nodes'}}) {
        if ($_->isa("Text::KnuthPlass::Box")) { $output .= $_->value() }
        elsif ($_->isa("Text::KnuthPlass::Glue")) { $output .= " "; }
    }
    if ($_->{'nodes'} and $_->{'nodes'}[-1]->is_penalty()) { $output .= "-"; }
    $output .="\n";
}
# test 4
is($output, <<EOF, "Try typesetting something");
This paragraph has been typeset using the classic 
Knuth and Plass algorithm, as used in TeX, plus the 
Liang hyphenation algorithm, implemented in Perl by 
Simon Cozens.
EOF

$t = Text::KnuthPlass->new(
    'linelengths' => [45],
    'indent' => 0,
    'hyphenator' => Text::Hyphen->new()
);
@lines = $t->typeset($para);
sub out_text {
    my @lines = @_;
    $output = "";
    for my $line (@lines) {
        for (@{$line->{'nodes'}}) {
            if ($_->isa("Text::KnuthPlass::Box")) { $output .= $_->value(); }
            elsif ($_->isa("Text::KnuthPlass::Glue")) { 
                my $w = int(0.5+( $_->width() + $line->{'ratio'} *
                ($line->{'ratio'} < 0 ? $_->shrink() : $_->stretch())));
                $output .= " " x $w;
            }
        }
        if ($line->{'nodes'}[-1]->is_penalty()) { $output .= "-"; }
        $output .="\n";
    }
    return $output;
}
# test 5
is(out_text(@lines), <<EOF, "With hyphens");
This paragraph has been typeset using the clas-
sic Knuth and Plass algorithm, as used in TeX, 
plus the Liang hyphenation algorithm, imple-
mented in Perl by Simon Cozens.
EOF
