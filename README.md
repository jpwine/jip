# jip: Strings to JSON converter

`jip` is an open-source command-line utility designed to streamline handling JSON data. With its simple yet powerful functionality, jip makes it easy to convert input strings into JSON, process JSON data, and merge JSON objects seamlessly.

## Key Features

* **Input to JSON Conversion**: Converts arguments or stdin strings into properly formatted JSON objects.

* **JSON Passthrough**: Identifies valid JSON input and ensures it is not double-encoded, preserving its structure.

* **JSON Merging**: Combines multiple JSON objects into one, simplifying data aggregation tasks.

## Usage Examples

note: The sample JSON output contains line breaks and indentations, but these are just examples; jip does not format them.

### Basic Usage

list mode

```shell
jip "hello"
# ["hello"]
```

key-value mode

```shell
jip -kv "hello:world"
# {"hello":"world"}
```

```shell
jip -kv "hello:world" "こんにちは 世界"
# {"hello":"world","UnnamedKey1":"こんにちは 世界"}
```

read stdin

```shell
echo "hello" | jip -
# ["hello"]
```

line-split

```shell
echo "hello
world" | jip -line-split -
# ["hello","world"]
```

### Handle Valid JSON Without Alteration

```shell
jip '["hello","world"]' '{"hello":"world"}' "こんにちは 世界"
# [
     ["hello","world"],
     {"hello":"world"},
     "こんにちは 世界"
]
```

```shell
jip -kv 'key1:["hello","world"]' 'key2:{"hello":"world"}' '{"こんにちは":"世界"}'
# {
     "key1":["hello","world"],
     "key2":{"hello":"world"},
     "UnnamedKey1":{"こんにちは":"世界"}
}
```

```shell
echo '["hello",
"world"]' | jip - '{"hello":"world"}' "こんにちは 世界"
# [
     ["hello","world"],
     {"hello":"world"},
     "こんにちは 世界"
]
```

```shell
# Input not treated as JSON
echo '["hello","world"]
["hello","world"]' | jip -
# ["[\"hello\",\"world\"]\n[\"hello\",\"world\"]"]
```

### Merge Multiple Inputs

```shell
jip -merge '["hello","world"]' '["こんにちわ","世界"]'
# ["hello","world","こんにちわ","世界"]
```

```shell
jip -merge -kv '{"hello":"world"}' '{"こんにちわ":"世界"}'
# {
     "hello":"world",
     "こんにちわ":"世界"
}
```

## Build

just your os

```shell
make build
```

cross-compile

```shell
GOOS=linux GOARCH=arm64 make build
```
