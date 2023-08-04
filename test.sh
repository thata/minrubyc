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

assert "4649" '4649'

echo OK
