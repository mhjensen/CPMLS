#!/bin/sh
set -x

function system {
  "$@"
  if [ $? -ne 0 ]; then
    echo "make.sh: unsuccessful command $@"
    echo "abort!"
    exit 1
  fi
}

if [ $# -eq 0 ]; then
name=Masterprogram
else
name=$1
fi
rm -f *.tar.gz

opt="--encoding=utf-8"
opt=

rm -f *.aux




html=${name}-reveal
system doconce format html $name --pygments_html_style=perldoc --keep_pygments_html_bg --html_links_in_new_window --html_output=$html $opt
system doconce slides_html $html reveal --html_slide_theme=beige

# Plain HTML documentsls

html=${name}-solarized
system doconce format html $name --html_style=solarized3

html=${name}-plain
system doconce format html $name --pygments_html_style=default --html_style=bloodish --html_links_in_new_window --html_output=$html $opt
system doconce split_html $html.html
# Remove top navigation in all parts
doconce subst -s '<!-- begin top navigation.+?end top navigation -->' '' ${name}-plain.html ._${name}*.html

# One big HTML file with space between the slides
html=${name}-1
system doconce format html $name --html_style=bloodish --html_links_in_new_window --html_output=$html $opt
# Add space between splits
system doconce split_html $html.html --method=space8


# Ordinary plain LaTeX document
rm -f *.aux  # important after beamer
system doconce format pdflatex $name --minted_latex_style=trac --latex_admon=paragraph --latex_code_style=pyg $opt
doconce replace 'section{' 'section*{' $name.tex
pdflatex -shell-escape $name
mv -f $name.pdf ${name}-minted.pdf
cp $name.tex ${name}-plain-minted.tex

# IPython notebook
#system doconce format ipynb $name $opt

# Publish
dest=../../pub
if [ ! -d $dest/$name ]; then
mkdir $dest/$name
mkdir $dest/$name/pdf
mkdir $dest/$name/html
mkdir $dest/$name/ipynb
fi
cp ${name}*.pdf $dest/$name/pdf
cp -r ${name}*.html ._${name}*.html reveal.js $dest/$name/html

# Figures: cannot just copy link, need to physically copy the files
if [ -d fig-${name} ]; then
if [ ! -d $dest/$name/html/fig-$name ]; then
mkdir $dest/$name/html/fig-$name
fi
cp -r fig-${name}/* $dest/$name/html/fig-$name
fi

cp ${name}.ipynb $dest/$name/ipynb
ipynb_tarfile=ipynb-${name}-src.tar.gz
if [ ! -f ${ipynb_tarfile} ]; then
cat > README.txt <<EOF
This IPython notebook ${name}.ipynb does not require any additional
programs.
EOF
tar czf ${ipynb_tarfile} README.txt
fi
cp ${ipynb_tarfile} $dest/$name/ipynb

