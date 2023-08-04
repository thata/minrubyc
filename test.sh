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

assert "305" "(10+20*30)/2"
assert "5" "30/6"
assert "72" "8*9"
assert "20" "30-10"
assert "30" "10+20"
assert "-10" "-10"
assert "4649" "4649"

echo OK
