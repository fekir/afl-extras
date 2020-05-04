#!/bin/sh

#   Copyright 2019 Federico Kircheis
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


uniq_files(){
  for f in $1; do :; # $1=sequence
    printf '%s\n' "$f" >"$2/$f"; # $2 = dir
  done
}

compare_num_files(){
  nfiles=$(find "$2" -mindepth 1 -printf "." | wc -c);
  if [ "$nfiles" -ne "$1" ]; then :;
    printf '%s\n' "$3"
    exit 1;
  fi
}

test_copy_simple(){
  TDIR="$1"; shift;
  AFL_COLLECT="$1"; shift;
  mkdir "$TDIR" "$TDIR/a";

  cfiles=10;
  sequence="$(seq -f %02.f 0 "$((cfiles-1))")"
  uniq_files "$sequence" "$TDIR/a"
  "$AFL_COLLECT" --input "$TDIR/a" --output "$TDIR/b";

  compare_num_files $cfiles "$TDIR/b" "test_copy_simple failed, number of files do not match, check \"$TDIR/a\" and \"$TDIR/b\"."
  for f in $sequence; do :;
    if ! diff "$TDIR/a/$f" "$TDIR/b/$f"; then :;
       printf 'test_copy_simple: "%s" differs from "%s".\n' "$TDIR/a/$f" "$TDIR/b/$f";
      exit 1;
    fi
  done
}

test_copy_simple_dup(){
  TDIR="$1"; shift;
  AFL_COLLECT="$1"; shift;
  mkdir "$TDIR" "$TDIR/a";

  cfiles=10;
  sequence="$(seq -f %02.f 0 "$((cfiles-1))")"
  uniq_files "$sequence" "$TDIR/a"
  printf '%s\n' "00" >"$TDIR/a/0"
  "$AFL_COLLECT" --input "$TDIR/a" --output "$TDIR/b";

  compare_num_files $cfiles "$TDIR/b" "test_copy_simple_dup failed, number of files do not match, check \"$TDIR/a\" and \"$TDIR/b\"."
  for f in $sequence; do :;
    if [ "$f" = "00" ] && [ ! -f "$TDIR/b/$f" ]; then
      f="0"; # it's either 0, or 00
    fi;
    if ! diff "$TDIR/a/$f" "$TDIR/b/$f"; then :;
       printf 'test_copy_simple_dup: "%s" differs from "%s".\n' "$TDIR/a/$f" "$TDIR/b/$f";
      exit 1;
    fi
  done
}

test_copy_self(){
  TDIR="$1"; shift;
  AFL_COLLECT="$1"; shift;
  mkdir "$TDIR" "$TDIR/a";

  cfiles=10;
  sequence="$(seq -f %02.f 0 "$((cfiles-1))")"
  uniq_files "$sequence" "$TDIR/a"
  "$AFL_COLLECT" --input "$TDIR/a" --output "$TDIR/a" --operation mv;

  compare_num_files $cfiles "$TDIR/a" "test_copy_self failed, number of files do not match, check \"$TDIR/a\"."
  for f in $sequence; do :;
    if [ "$(cat "$TDIR/a/$f")" != "$f" ]; then :;
       printf 'test_copy_self: "%s" differs from "%s".\n' "$TDIR/a/$f" "$f";
      exit 1;
    fi
  done
}
test_copy_self_dup(){
  TDIR="$1"; shift;
  AFL_COLLECT="$1"; shift;
  mkdir "$TDIR" "$TDIR/a";

  cfiles=10;
  sequence="$(seq -f %02.f 0 "$((cfiles-1))")"
  uniq_files "$sequence" "$TDIR/a"
  printf '%s\n' "00" >"$TDIR/a/0"
  "$AFL_COLLECT" --input "$TDIR/a" --output "$TDIR/a" --operation mv;

  compare_num_files $cfiles "$TDIR/a" "test_copy_self_dup failed, number of files do not match, check \"$TDIR/a\"."
  for s in $sequence; do :;
    val="$s"
    f="$TDIR/a/$s";
    if [ "$s" = "00" ] && [ ! -f "$f" ]; then
      f="$TDIR/a/0"; # it's either 0, or 00
    fi;
    if [ "$(cat "$f")" != "$val" ]; then :;
       printf 'test_copy_self: "%s" differs from "%s".\n' "$f" "$val";
      exit 1;
    fi
  done
}

test_copy_simple_twice_eq(){
  TDIR="$1"; shift;
  AFL_COLLECT="$1"; shift;
  mkdir "$TDIR" "$TDIR/a.1" "$TDIR/a.2";

  cfiles=10;
  sequence="$(seq -f %02.f 0 "$((cfiles-1))")"
  uniq_files "$sequence" "$TDIR/a.1"
  uniq_files "$sequence" "$TDIR/a.2"
  # FIXME: check with new version
  "$AFL_COLLECT" --input "$TDIR/a.1" --output "$TDIR/b";

  compare_num_files $cfiles "$TDIR/b" "test_copy_simple failed, number of files do not match, check \"$TDIR/a.1\", \"$TDIR/a.2\" and \"$TDIR/b\".\\n"
  for f in $sequence; do :;
    if ! diff "$TDIR/a.1/$f" "$TDIR/b/$f"; then :; # a.1 or a.2, it's the same
      printf 'test_copy_simple: "%s" differs from "%s".\n' "$TDIR/a/$f" "$TDIR/b/$f";
      exit 1;
    fi
  done
}

test_copy_simple_twice_ne(){
  TDIR="$1"; shift;
  AFL_COLLECT="$1"; shift;
  mkdir "$TDIR" "$TDIR/a.1" "$TDIR/a.2";

  cfiles=10;
  sequence="$(seq -f %02.f 0 "$((cfiles-1))")"
  uniq_files "$sequence" "$TDIR/a.1"
  for f in $sequence; do :;
    printf '%s\n' "$((cfiles-${f#0}))" >"$TDIR/a.2/$f";
  done
  # FIXME: check with new version
  "$AFL_COLLECT" --input "$TDIR/a.1" --input "$TDIR/a.2" --output "$TDIR/b";

  compare_num_files $cfiles "$TDIR/b" "test_copy_simple_twice_ne failed, number of files do not match, check \"$TDIR/a.1\", \"$TDIR/a.2\" and \"$TDIR/b\".\\n"
  dup="$(find "$TDIR/b" -type f -exec cat {} \; | sort | uniq -c | sort | tail -1 | cut -d ' ' -f7)"; #should check content..., and assumes no more than one newlines in any file
  if [ "$dup" -ne 1 ]; then :;
    printf 'test_copy_simple_twice_ne: No files found, or some duplicates\n';
    exit 1;
  fi
}

main(){
 TMPDIR=${XDG_RUNTIME_DIR:-${TMPDIR:-${TMP:-${TEMP:-/tmp}}}};
 WDIR="$(mktemp -p "$TMPDIR" -d test-collect.XXXXXX.d)";
 COLLECT="./collect-data"

 test_copy_simple "$WDIR/test_copy_simple" "$COLLECT";
 test_copy_self "$WDIR/test_copy_self" "$COLLECT";
 test_copy_simple_dup "$WDIR/test_copy_simple_dup" "$COLLECT";
 test_copy_self_dup "$WDIR/test_copy_self_dup" "$COLLECT";
 test_copy_simple_twice_eq "$WDIR/test_copy_simple_twice_eq" "$COLLECT";
 test_copy_simple_twice_ne "$WDIR/test_copy_simple_twice_ne" "$COLLECT";

 # test for afl directories..., mv, mv-delete
 rm -rf "$WDIR";
}

main "$@"
