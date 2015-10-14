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
name=outline
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

# LaTeX Beamer slides
beamertheme=red_plain
system doconce format pdflatex $name --latex_title_layout=beamer --latex_table_format=footnotesize --latex_code_style=pyg $opt
system doconce slides_beamer $name --beamer_slide_theme=$beamertheme
system pdflatex -shell-escape ${name}
cp $name.pdf ${name}-beamer.pdf
cp $name.tex ${name}-beamer.tex

# Handouts
system doconce format pdflatex $name --latex_title_layout=beamer --latex_table_format=footnotesize  --latex_code_style=pyg $opt
# Add special packages
doconce subst "% Add user's preamble" "\g<1>\n\\usepackage{simplewick}" $name.tex
system doconce slides_beamer $name --beamer_slide_theme=red_shadow --handout
system pdflatex -shell-escape $name
pdflatex -shell-escape $name
pdfnup --nup 2x3 --frame true --delta "1cm 1cm" --scale 0.9 --outfile ${name}-beamer-handouts2x3.pdf ${name}.pdf
rm -f ${name}.pdf

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


doconce format html index --html_style=bootstrap --html_links_in_new_window --html_bootstrap_jumbotron=off
cp index.html $dest
