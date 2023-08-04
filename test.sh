#!/bin/bash

#!/bin/bash

assert() {
    # expected の "\n" を改行コードをとして解釈させる
    expected=`echo -e "$1"`
    input="$2"

    echo "$input" > tmp.rb
    ruby minrubyc.rb tmp.rb > tmp.s
    gcc tmp.s libminruby.c -o tmp
    actual=`./tmp`

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
        exit 1
    fi
}

assert "10\n20\n" "p 10; p 20"
assert "305" "p((10+20*30)/2)"
assert "5" "p 30/6"
assert "72" "p 8*9"
assert "20" "p 30-10"
assert "30" "p 10+20"
assert "-10" "p(-10)"
assert "4649" "p 4649"

echo OK
