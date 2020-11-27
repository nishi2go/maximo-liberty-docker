#!/bin/sh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CHECK_DIR=.
GEN_PKG_LIST=0
SHOW_HELP=0
CHECK=0
DEEP_CHECK=0
PACKAGE_LIST=/packages.list

while [ $# -gt 0 ]; do
  key="$1"
    case "$key" in
      -c | --check )
        CHECK=1
        ;;
      -C | --deepcheck )
        CHECK=1
        DEEP_CHECK=1
        ;;
      -h | --help )
        SHOW_HELP=1
        ;;
      -g )
        GEN_PKG_LIST=1
        ;;
      -v | --verbose )
        QUIET=""
        ;;
      * )
        CHECK_DIR="$1"
    esac
    shift
done

if [ $SHOW_HELP -eq 1 ]; then
  cat <<EOF
Usage: check.sh [OPTIONS] [DIR]

-c | --check            Check required packages
-C | --deepcheck        Check and compare checksum of required packages
-v | --verbose          Output verbosity in docker build
-h | --help             Show this help text
EOF
  exit 1
fi

cd `dirname "$0"`

if [ $GEN_PKG_LIST -eq 1 ]; then
  rm $PACKAGE_LIST.out
fi

if [ $CHECK -eq 1 ]; then
  echo "Start to check packages"
  if [ ! -d "$CHECK_DIR" ]; then
    echo "The specified directory could not access"
    exit 9
  fi

  while IFS=, read -r file md5sum; do
   echo -n -e "Check $file exists...\t"
   if [ ! -f "$CHECK_DIR/$file" ]; then
     echo " Not found."
     exit 9
   fi

   if [ $DEEP_CHECK -eq 1 ]; then
     res=`md5sum $CHECK_DIR/$file`
     if [ $GEN_PKG_LIST -eq 1 ]; then
       echo "$file,$res" >> $PACKAGE_LIST.out
     elif [ "$md5sum" == "$res" ]; then
       echo " MD5 does not match."
       exit 9
     fi
   fi

   echo " Found."
  done < $PACKAGE_LIST
fi

echo "Done"
