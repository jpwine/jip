#!/usr/bin/env bash

ttt=${test_target_tool:=./bin/jip}

test_passed=0
test_failed=0

function main () {
    echo "[${0##*/}/INFO] Test target tool: ${ttt#$(pwd)/}"
    
    result=0
    funcnames=$(declare -F | awk '{print $3}' | grep "^test_")
    
    for funcname in $funcnames
    do
        $funcname \
            && { ((test_passed++)); true; }  \
            || { echo "[${0##*/}/WARNING] $funcname: NG"; ((test_failed++)); false; }
    done

    echo "[${0##*/}/INFO] Test $test_passed / $((test_passed+test_failed)) passed"

    return $test_failed
}


function common () {
    if [ -p /dev/stdin ]; then
        stdins=$(cat -)
    fi
    expected_results="$1"
    shift
    output=$(echo "$stdins" | $ttt "$@")
    echo "$output" | check "$expected_results" || {
        printf "[${0##*/}/INFO] $funcname, args: %q, stdins: %q, output $output: expected: $expected_results\n" "$@" "$stdins"
        return 1
    }
}

function check () {
    cat - | grep -F "$1"
}

# LIST TEST

function test_LIST_001 () {
    common '["a"]' a
}

function test_LIST_101 () {
    echo b | common '["a","b"]' a -
}

function test_LIST_102 () {
    echo "b
c" | common '["a","b\nc"]' a -
}

function test_LIST_103 () {
    echo "b
c" | common '["a","b","c"]' -line-split a -
}

function test_LIST_111 () {
    echo '["b", 1]' | common '["a",["b",1]]' a -
}

function test_LIST_112 () {
    echo '["b",
1]' | common '["a",["b",1]]' a -
}

function test_LIST_113 () {
    echo '["b",1]
["c", 2]' | common '["a","[\"b\",1]\n[\"c\", 2]"]' a -
}

function test_LIST_114 () {
    echo '["b",1]
["c", 2]' | common '["a",["b",1],["c",2]]' -line-split a -
}

function test_LIST_121 () {
    echo '{"k":"v"}' | common '["a",{"k":"v"}]' a -
}

function test_LIST_122 () {
    echo '{"k":
"v"}' | common '["a",{"k":"v"}]' a -
}

function test_LIST_123 () {
    echo '{"k":"v"}
{"k2":"v2"}' | common '["a","{\"k\":\"v\"}\n{\"k2\":\"v2\"}"]' a -
}

function test_LIST_124 () {
    echo '{"k":"v"}
{"k2":"v2"}' | common '["a",{"k":"v"},{"k2":"v2"}]' -line-split a -
}

function test_LIST_131 () {
    echo '["b", 2]
["c", 3]
{"k": "v"}' | common '["a",["b",2],["c",3],{"k":"v"}]' -line-split a -
}

function test_LIST_132 () {
    echo '["b", 2]
{"k": "v"}
{"k2":"v2"}' | common '["a",["b",2],{"k":"v"},{"k2":"v2"}]' -line-split a -
}

function test_LIST_133 () {
    echo 'notype
["b", 2]
{"k2":"v2"}' | common '["a","notype",["b",2],{"k2":"v2"}]' -line-split a -
}

function test_LIST_201 () {
    common '["a","b"]' -merge a b
}

function test_LIST_211 () {
    common '["a","b\nc"]' -merge a "b
c"
}

function test_LIST_212 () {
    common '["a","b","c"]' -merge -line-split a "b
c"
}

function test_LIST_221 () {
    common '["a","b",2]' -merge a '["b",2]'
}

function test_LIST_222 () {
    common '["a","b",2]' -merge a '["b",
2]'
}

function test_LIST_223 () {
    common '["a","[\"b\",2]\n[\"c\", true]"]' -merge a '["b",2]
["c", true]'
}

function test_LIST_224 () {
    common '["a","b",2,"c",true]' -merge -line-split a '["b",2]
["c", true]'
}

function test_LIST_231 () {
    common '["a",{"k":"v"}]' -merge a '{"k":"v"}'
}

function test_LIST_232 () {
    common '["a",{"k":"v"}]' -merge a '{"k":
"v"}'
}

function test_LIST_233 () {
    common '["a","{\"k\":\"v\"}\n{\"k2\":false}"]' -merge a '{"k":"v"}
{"k2":false}'
}

function test_LIST_234 () {
    common '["a",{"k":"v"},{"k2":false}]' -merge -line-split a '{"k":"v"}
{"k2":false}'
}

function test_LIST_301 () {
    echo 'notype' | common '["a","notype"]' -merge a -
}

function test_LIST_311 () {
    echo 'notype
2' | common '["a","notype\n2"]' -merge a -
}

function test_LIST_312 () {
    echo 'notype
2' | common '["a","notype",2]' -merge -line-split a -
}

function test_LIST_321 () {
    echo '["b", false]' | common '["a","b",false]' -merge a -
}

function test_LIST_322 () {
    echo '["b",
false, true]' | common '["a","b",false,true]' -merge a -
}

function test_LIST_323 () {
    echo '["b",false, true]
["c", 2]' | common '["a","[\"b\",false, true]\n[\"c\", 2]"]' -merge a -
}


function test_LIST_324 () {
    echo '["b",false, true]
["c", 2]' | common '["a","b",false,true,"c",2]' -merge -line-split a -
}

function test_LIST_331 () {
    echo '{"k":"v"}' | common '["a",{"k":"v"}]' -merge a -
}

function test_LIST_332 () {
    echo '{"k":"v",
"k2":false}' | common '["a",{"k":"v","k2":false}]' -merge a -
}

function test_LIST_333 () {
    echo '{"k":"v"}
{"k2":false}' | common '["a","{\"k\":\"v\"}\n{\"k2\":false}"]' -merge a -
}

function test_LIST_334 () {
    echo '{"na":"han"}
{"kan":false}' | common '["a",{"na":"han"},{"kan":false}]' -merge -line-split a -
}

function test_LIST_341 () {
    echo '["b", 2]
["c", null]
{"k": "v"}' | common '["a","b",2,"c",null,{"k":"v"}]' -merge -line-split a -
}

function test_LIST_342 () {
    echo '["b", 2]
{"k":"v"}
{"k2":false}' | common '["a","b",2,{"k":"v"},{"k2":false}]' -merge -line-split a -
}

function test_LIST_343 () {
    echo 'notype
["b", 2]
{"k":"v"}' | common '["a","notype","b",2,{"k":"v"}]' -merge -line-split a -
}

# KV TEST

function test_KV_001 () {
    common '{"k":"v"}' -kv k:v
}

function test_KV_101 () {
    echo 'v2' | common '{"UnnamedKey1":"v2","k":"v"}' -kv k:v -
}

function test_KV_102 () {
    echo 'v2' | common '{"k":"v","k2":"v2"}' -kv k:v k2:-
}

function test_KV_103 () {
    echo 'v2' | common '{"k":"v2"}' -kv k:v k:-
}

function test_KV_104 () {
    echo 'k2:v2' | common '{"k":"v","k2":"v2"}' -kv k:v -
}

function test_KV_105 () {
    echo 'k:v2' | common '{"k":"v2"}' -kv k:v -
}

function test_KV_106 () {
    echo 'k:v2' | common '{"k":"v"}' -kv - k:v
}

function test_KV_107 () {
    echo 'a
b' | common '{"UnnamedKey1":"a\nb","k":"v"}' -kv k:v -
}

function test_KV_108 () {
    echo 'a
b' | common '{"c":"a\nb","k":"v"}' -kv k:v c:-
}

function test_KV_109 () {
    echo 'a
b' | common '{"UnnamedKey1":"b","c":"a","k":"v"}' -kv -line-split k:v c:-
}

function test_KV_110 () {
    echo 'a:b
e:f' | common '{"c":"a:b","e":"f","k":"v"}' -kv -line-split k:v c:-
}


function test_KV_111 () {
    echo '["a",1]' | common '{"c":["a",1],"k":"v"}' -kv k:v c:-
}

function test_KV_112 () {
    echo '["a",1]' | common '{"UnnamedKey1":["a",1],"k":"v"}' -kv k:v -
}

function test_KV_113 () {
    echo '["a",
1]' | common '{"UnnamedKey1":["a",1],"k":"v"}' -kv k:v -
}

function test_KV_114 () {
    echo '["a",1]
["b",2]' | common '{"UnnamedKey1":"[\"a\",1]\n[\"b\",2]","k":"v"}' -kv k:v -
}

function test_KV_115 () {
    echo '["a",1]
["b",2]' | common '{"UnnamedKey1":["b",2],"c":["a",1],"k":"v"}' -kv -line-split k:v c:-
}

function test_KV_116 () {
    echo '["a",1]
["b",2]' | common '{"UnnamedKey1":["a",1],"UnnamedKey2":["b",2],"k":"v"}' -kv -line-split k:v -
}

function test_KV_121 () {
    echo '{"a":1}' | common '{"UnnamedKey1":{"a":1},"k":"v"}' -kv k:v -
}

function test_KV_122 () {
    echo '{"a":
1}' | common '{"UnnamedKey1":{"a":1},"k":"v"}' -kv k:v -
}

function test_KV_123 () {
    echo '{"a":
1}' | common '{"b":{"a":1},"k":"v"}' -kv k:v b:-
}

function test_KV_124 () {
    echo '{"a":1}
{"b":true}' | common '{"k":"v","{\"a\"":"1}\n{\"b\":true}"}' -kv k:v -
}

function test_KV_125 () {
    echo '{"a":1}
{"b":true}' | common '{"c":"{\"a\":1}\n{\"b\":true}","k":"v"}' -kv k:v c:-
}

function test_KV_126 () {
    echo '{"a":1}
{"b":true}' | common '{"UnnamedKey1":{"a":1},"UnnamedKey2":{"b":true},"k":"v"}' -kv -line-split k:v -
}

function test_KV_127 () {
    echo '{"a":1}
{"b":true}' | common '{"UnnamedKey1":{"b":true},"c":{"a":1},"k":"v"}' -kv -line-split k:v c:-
}

function test_KV_131 () {
    echo '["a",true]
[false,null]
{"b":true}' | common '{"UnnamedKey1":[false,null],"UnnamedKey2":{"b":true},"c":["a",true],"k":"v"}' -kv -line-split k:v c:-
}

function test_KV_132 () {
    echo '["a",true]
[false,null]
{"b":true}' | common '{"UnnamedKey1":["a",true],"UnnamedKey2":[false,null],"UnnamedKey3":{"b":true},"k":"v"}' -kv -line-split k:v -
}

function test_KV_133 () {
    echo '["a",true]
{"b":null}
{"c":true}' | common '{"UnnamedKey1":{"b":null},"UnnamedKey2":{"c":true},"d":["a",true],"k":"v"}' -kv -line-split k:v d:-
}

function test_KV_134 () {
    echo '["a",true]
{"b":null}
{"c":true}' | common '{"UnnamedKey1":["a",true],"UnnamedKey2":{"b":null},"UnnamedKey3":{"c":true},"k":"v"}' -kv -line-split k:v -
}

function test_KV_135 () {
    echo 'a
["b",true]
{"c":null}' | common '{"UnnamedKey1":["b",true],"UnnamedKey2":{"c":null},"d":"a","k":"v"}' -kv -line-split k:v d:-
}

function test_KV_136 () {
    echo 'a
["a",true]
{"b":null}' | common '{"UnnamedKey1":"a","UnnamedKey2":["a",true],"UnnamedKey3":{"b":null},"k":"v"}' -kv -line-split k:v -
}

function test_KV_137 () {
    echo 'a:e
["b",true]
{"c":null}' | common '{"UnnamedKey1":["b",true],"UnnamedKey2":{"c":null},"a":"e","k":"v"}' -kv -line-split k:v -
}

function test_KV_138 () {
    echo 'a:e
["b",true]
{"c":null}' | common '{"UnnamedKey1":["b",true],"UnnamedKey2":{"c":null},"d":"a:e","k":"v"}' -kv -line-split k:v d:-
}

function test_KV_139 () {
    echo 'a:e
f:["b",true]
{"c":null}' | common '{"UnnamedKey1":{"c":null},"a":"e","f":["b",true],"k":"v"}' -kv -line-split k:v -
}

function test_KV_201 () {
    common '{"UnnamedKey1":"a","k":"v"}' -kv -merge k:v a
}

function test_KV_202 () {
    common '{"a":1,"k":"v"}' -kv -merge k:v a:1
}

function test_KV_203 () {
    common '{"UnnamedKey1":"a\nb","k":"v"}' -kv -merge k:v "a
b"
}

function test_KV_204 () {
    common '{"a":"b\nc","k":"v"}' -kv -merge k:v "a:b
c"
}

function test_KV_205 () {
    common '{"UnnamedKey1":"c","a":"b","k":"v"}' -kv -merge -line-split k:v "a:b
c"
}

function test_KV_211 () {
    common '{"UnnamedKey1":[1,true,"a"],"k":"v"}' -kv -merge k:v '[1, true, "a"]'
}

function test_KV_212 () {
    common '{"UnnamedKey1":[1,true,{"a":2}],"k":"v"}' -kv -merge k:v '[1, true, {"a":2}]'
}

function test_KV_213 () {
    common '{"UnnamedKey1":[1,true,"a"],"k":"v"}' -kv -merge k:v '[1, true,
"a"]'
}

function test_KV_214 () {
    common '{"b":[1,true,"a"],"k":"v"}' -kv -merge k:v 'b:[1, true,
"a"]'
}

function test_KV_215 () {
    common '{"b":"[1, true]\nc:[2, false]","k":"v"}' -kv -merge k:v 'b:[1, true]
c:[2, false]'
}

function test_KV_216 () {
    common '{"b":[1,true],"c":[2,false],"k":"v"}' -kv -merge -line-split k:v 'b:[1, true]
c:[2, false]'
}

function test_KV_211 () {
    common '{"a":1,"k":"v"}' -kv -merge k:v '{"a":1}'
}

function test_KV_212 () {
    common '{"a":1,"k":"v"}' -kv -merge k:v '{"a":
1}'
}

function test_KV_213 () {
    common '{"k":"v","{\"a\"":"1}\n{\"b\":2}"}' -kv -merge k:v '{"a":1}
{"b":2}'
}

function test_KV_214 () {
    common '{"a":1,"b":2,"k":"v"}' -kv -merge -line-split k:v '{"a":1}
{"b":2}'
}

function test_KV_301 () {
    echo 'a
b' | common '{"c":"a\nb","k":"v"}' -kv -merge k:v c:-
}

function test_KV_302 () {
    echo 'a
b' | common '{"UnnamedKey1":"a\nb","k":"v"}' -kv -merge k:v -
}

function test_KV_303 () {
    echo 'a
b' | common '{"UnnamedKey1":"b","c":"a","k":"v"}' -kv -merge -line-split k:v c:-
}

function test_KV_311 () {
    echo '[1,
2]' | common '{"a":[1,2],"k":"v"}' -kv -merge k:v a:-
}

function test_KV_312 () {
    echo '[1,
2]' | common '{"UnnamedKey1":[1,2],"k":"v"}' -kv -merge k:v -
}

function test_KV_313 () {
    echo '[1,2]
[3,true]' | common '{"a":"[1,2]\n[3,true]","k":"v"}' -kv -merge k:v a:-
}

function test_KV_314 () {
    echo '[1,2]
[3,true]' | common '{"UnnamedKey1":"[1,2]\n[3,true]","k":"v"}' -kv -merge k:v -
}

function test_KV_315 () {
    echo '[1,2]
[3,true]' | common '{"UnnamedKey1":[1,2],"UnnamedKey2":[3,true],"k":"v"}' -kv -merge -line-split k:v -
}

function test_KV_321 () {
    echo '{"a":
2}' | common '{"a":2,"k":"v"}' -kv -merge k:v -
}

function test_KV_322 () {
    echo '{"a":1}
{"b":2}' | common '{"k":"v","{\"a\"":"1}\n{\"b\":2}"}' -kv -merge k:v -
}

function test_KV_323 () {
    echo '{"a":1}
{"b":2}' | common '{"a":1,"b":2,"k":"v"}' -kv -merge -line-split k:v -
}

function test_KV_331 () {
    echo 'a
b:c
[2, 3]
{"d":2}' | common '{"UnnamedKey1":"a","UnnamedKey2":[2,3],"b":"c","d":2,"k":"v"}' -kv -merge -line-split k:v -
}




# MAIN
main
