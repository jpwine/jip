// -*- tab-width: 4 -*-

package main

import (
	"os"
	"fmt"
	"encoding/json"
	"flag"
	"bufio"
	"slices"
	"strings"
	"strconv"

	//"github.com/jpwine/jip"
)


func readStdin () string {
	var value string
	s := bufio.NewScanner(os.Stdin)
	for s.Scan() {
		if len(value) > 0 {
			value += "\n"
		}
		value += s.Text()
	}
	if s.Err() != nil {
		// non-EOF error.
		//log.Fatal(s.Err())
	}
	return strings.TrimSuffix(value, "\n")
}

func tidyStrings (args []string, kvMode bool, lineSplit bool) []string {
	var strs1, strs2 []string
	for _, str := range(args) {
		if str == "-" {
			strs1 = append(strs1, readStdin())
			continue
		}
		if kvMode && !json.Valid([]byte(str)) {
			k, v := separateKeyValue(str)
			if v == "-" {
				strs1 = append(strs1, k+":"+readStdin())
				continue
			}
		}
		strs1 = append(strs1, str)
	}
	for _, str := range(strs1) {
		if json.Valid([]byte(str)) {
			strs2 = append(strs2, str)
			continue
		}
		if lineSplit {
			for _, s := range(strings.Split(strings.TrimSuffix(str,"\n"),"\n")) {
				strs2 = append(strs2, s)
			}
			continue
		}
		strs2 = append(strs2, str)
	}
	return strs2
}

func separateKeyValue(s string) (string, string) {
	// k/v 分離
	var key, val string
	if !strings.Contains(s, ":") {
		// 「:」が含まれない場合 input => "", input
		key = ""
		val = s
	} else {
		// 「:」が含まれる場合 input => k, v
		kv := strings.SplitN(s, ":", 2)
		key = kv[0]
		val = kv[1]
	}
	return key, val
}

func formatValue(s string) interface{} {
	if s == "true" || s == "false" {
		res, _ := strconv.ParseBool(s)
		return res
	} else if numValue, isNumeric := getNumeric(s); isNumeric {
		return numValue
	} else if s == "null" {
		return nil
	} else {
		return s
	}
}

func getNumeric(s string) (interface{}, bool) {
	if v, err := strconv.Atoi(s); err == nil {
		return v, true
	}
	if v, err := strconv.ParseFloat(s, 64); err == nil {
		return v, true
	}

	return nil, false
}

func main() {
	// フラグ
	flag.Usage = func() {
		usageTxt := `Usage of jip
   ./jip [options] arg1 arg2 arg3 => [ "arg1", "arg2", "arg3" ]

   [options]
   -kv     Enable Key-Value mode
      $0 -kv k1:v1 v2 '{"k3":"v3"}' => { "k1":"v1", "UnnamedKey1":"v2", "UnnamedKey2":{"k3":"v3"} }

   -line-split  Evaluate each line as one argument
      $0 -line-split "v1-1\nv1-2" v2 => [ "v1-1", "v1-2", "v2" ]
      $0 -line-split -kv "k1:v1-1\nv1-2" k2:v2 => { "k1":"v1-1", "UnnamedKey1":"v1-2", "k2":"v2" }

   -merge  Merge objects if mode and type are the same
      $0 -merge '["v1", "v2"]' "v3" => [ "v1", "v2", "v3" ]
      $0 -merge -kv k1:v1 '{"k2":"v2"}' => { "k1":"v1", "k2":"v2" }

   -        Read lines from stdin
      echo 'some\nlines' | $0 - arg1 => [ "some\nlines", "arg1" ]
      echo 'some\nlines' | $0 -kv k1:- k2:v2 => { "k1":"some\nlines", "k2":"v2" }
      echo 'k1:v1' | $0 -kv - => { "k1":"v1" }
      echo '{"k1":"v1"}' | $0 -kv - => { "k1":"v1" }
`
		fmt.Fprintf(os.Stderr, "%s\n", usageTxt)
	}
	kvMode := flag.Bool("kv", false, "Enable key-value mode")
	lineSplit := flag.Bool("line-split", false, "Enable line-split mode")
	mergeObjects := flag.Bool("merge", false, "Enable merge mode")
	printVersion := flag.Bool("version", false, "Print version")
	flag.Parse()
	args := flag.Args()

	// 引数チェック
	if *printVersion {
		println( "0.2.2" )
		os.Exit(0)
	}
	if len(args) == 0 {
		flag.Usage()
		os.Exit(1)
	}

	objs_kv := make(map[string]interface{})
	objs_list := []interface{}{}

	for _, str := range(tidyStrings(args, *kvMode, *lineSplit)) {
		jsonKvObj := make(map[string]interface{})
		jsonListObj := []interface{}{}
		if str == "" {
			if *kvMode && len(objs_kv) == 0 {
				continue
			} else if !*kvMode && len(objs_list) == 0 {
				continue
			}
		}
		if kvJsonErr := json.Unmarshal([]byte(str), &jsonKvObj); kvJsonErr == nil {
			if *kvMode && *mergeObjects {
				for key := range(jsonKvObj) {
					objs_kv[key] = jsonKvObj[key]
				}
			} else if *kvMode {
				for count:=1; true; count++ {
					key := "UnnamedKey"+strconv.Itoa(count)
					if _, exist := objs_kv[key]; exist {
						continue
					}
					objs_kv[key] = jsonKvObj
					break
				}
			} else if !*kvMode {
				objs_list = append(objs_list, jsonKvObj)
			}
		} else if listJsonErr := json.Unmarshal([]byte(str), &jsonListObj); listJsonErr == nil {
			if *kvMode {
				for count:=1; true; count++ {
					key := "UnnamedKey"+strconv.Itoa(count)
					if _, exist := objs_kv[key]; exist {
						continue
					}
					objs_kv[key] = jsonListObj
					break
				}
			} else if !*kvMode && *mergeObjects {
				objs_list = slices.Concat(objs_list, jsonListObj)
			} else if !*kvMode {
				objs_list = append(objs_list, jsonListObj)
			}
		} else if *kvMode {
			key, val := separateKeyValue(str)
			if key == "" {
				for count:=1; true; count++ {
					key = "UnnamedKey"+strconv.Itoa(count)
					if _, exist := objs_kv[key]; !exist {
						break
					}
				}
			}
			if kvJsonErr := json.Unmarshal([]byte(val), &jsonKvObj); kvJsonErr == nil {
				objs_kv[key] = jsonKvObj
			} else if listJsonErr := json.Unmarshal([]byte(val), &jsonListObj); listJsonErr == nil {
				objs_kv[key] = jsonListObj
			} else {
				objs_kv[key] = formatValue(val)
			}
		} else {
			objs_list = append(objs_list, formatValue(str))
		}
	}
	var output []byte
	var err error
	if *kvMode {
		output, err = json.Marshal(objs_kv)
	} else {
		output, err = json.Marshal(objs_list)
	}
	if err != nil {
		fmt.Println("Error creating JSON:", err)
		os.Exit(1)
	}
	fmt.Println(string(output))
}
