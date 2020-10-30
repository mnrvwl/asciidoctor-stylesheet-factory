#!/bin/sh

STYLESHEET_NAME=asciidoctor

[ -z $1 ] || STYLESHEET_NAME=$1

bundle exec compass compile -s compact
LINES=$(wc -l stylesheets/$STYLESHEET_NAME.css | cut -d" " -f1)
echo '/* Asciidoctor default stylesheet | MIT License | https://asciidoctor.org */' > $STYLESHEET_NAME.css
sed -e 's/ *\/\*\+!\? [^*]\+\($\| \*\/\)//g' \
    -e 's/^\/\*\* .* \*\/$//' \
    -e '/^\(*\/\|\) *$/d' \
    -e 's/^@media only/@media/' \
    -e '/\.antialiased {/d' \
    -e '/^body { margin: 0;/d' \
    -e 's/^body { background:[^}]*/&tab-size: 4; -moz-osx-font-smoothing: grayscale; -webkit-font-smoothing: antialiased;/' \
    -e '/^body { -moz-osx-font-smoothing:/d' \
    -e 's/direction: ltr;//' \
    -e 's/, \(summary\|canvas\)//' \
    -e '/^script /d' \
    -e '/object, svg { display: inline-block;/d' \
    -e 's/img { display: inline-block;/img, object, svg { display: inline-block;/' \
    -e 's/table thead, table tfoot {\(.*\) font-weight: bold;\(.*\)}/table thead, table tfoot {\1\2}/' \
    -e 's/, table tr:nth-of-type(even)//' \
    -e '/^p\.lead {/d' \
    -e '/^ul\.no-bullet, ol\.no-bullet { margin-left: 1.5em; }$/d' \
    -e '/^ul\.no-bullet { list-style: none; }$/d' \
    -e '/\(meta\.\|\.vcard\|\.vevent\|#map_canvas\|"search"\|\[hidden\]\)/d' \
    stylesheets/$STYLESHEET_NAME.css \
    | grep -v 'font-awesome' >> $STYLESHEET_NAME.css

# see https://www.npmjs.org/package/cssshrink (using 0.0.5)
# must run first: npm install cssshrink
./node_modules/.bin/cssshrink $STYLESHEET_NAME.css \
| sed -e '1i\
/* Uncomment @import statement to use as custom stylesheet */\
/*@import "https://fonts.googleapis.com/css?family=Open+Sans:300,300italic,400,400italic,600,600italic%7CNoto+Serif:400,400italic,700,700italic%7CDroid+Sans+Mono:400,700";*/' \
  -e '1i\
/* Asciidoctor default stylesheet | MIT License | https://asciidoctor.org */' \
  -e 's/\(Open Sans\|DejaVu Sans\|Noto Serif\|DejaVu Serif\|Droid Sans Mono\|DejaVu Sans Mono\|Ubuntu Mono\|Liberation Mono\|Varela Round\)/"\1"/g' \
  -e 's/background:transparent/background:none/g' \
  -e 's/background-color:\([^};]\+\)/background:\1/g' \
  -e 's/border:none/border:0/g' \
  # changing to font-weight:bold allows us to map the font weight 600 as bold
  -e 's/font-weight:700/font-weight:bold/g' \
  # use double colon for before/after pseudo-elements (see https://www.w3.org/TR/selectors/#pseudo-element-syntax)
  -e 's/\([^:]\):\(before\|after\)/\1::\2/g' \
  # drop the fourth value if it matches the second
  -e 's/\([a-z-]\+\):\([0-9.empx-]\+\) \([0-9.empx-]\+\) \([0-9.empx-]\+\) \3/\1:\2 \3 \4/g' \
  | ruby -e 'puts STDIN.read.gsub(/}(?!})/, %(}\n)).chomp' - > $STYLESHEET_NAME.min.css
