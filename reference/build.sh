#!/bin/sh

set -e

version="git"
if [ ! -z "$1" ]; then
    version=$1
fi

echo "Building documentation for Cinnamon and Muffin $version"
echo ""

if [ ! -d tmp ]; then
    echo "Creating build directory"
    mkdir -p tmp
fi
cd tmp

if [ -d Cinnamon ]; then
    echo "Updating Cinnamon repo"
    cd Cinnamon
    git checkout -q master
    git pull -q origin master
    git fetch -q --tags
    cd ..
else
    echo "Cloning Cinnamon repo"
    git clone -q https://github.com/linuxmint/Cinnamon
fi

if [ -d muffin ]; then
    echo "Updating muffin repo"
    cd muffin
    git checkout -q master
    git pull -q origin master
    git fetch -q --tags
    cd ..
else
    echo "Cloning muffin repo"
    git clone -q https://github.com/linuxmint/muffin
fi

if [ ! -z "$1" ]; then
    cd Cinnamon
    tag=`git tag | grep "^$1" | tail -1`
    echo "Checking out Cinnamon $tag"
    git checkout -q $tag
    cd ..

    cd muffin
    tag=`git tag | grep "^$1" | tail -1`
    echo "Checking out Muffin $tag"
    git checkout -q $tag
    cd ..
fi

cd Cinnamon
echo "Building Cinnamon"
./autogen.sh --prefix=/usr
make -j4
cd ..

cd muffin
echo "Building muffin"
./autogen.sh --prefix=/usr
make -j4
cd ..

cd ..

echo "Moving output files"
rm -rf $version
mkdir -p $version/muffin/
mkdir -p $version/cinnamon-js/
mkdir -p $version/cinnamon/
mkdir -p $version/st/

mv tmp/Cinnamon/docs/reference/cinnamon/html/* $version/cinnamon/
mv tmp/Cinnamon/docs/reference/cinnamon-js/html/* $version/cinnamon-js/
mv tmp/Cinnamon/docs/reference/st/html/* $version/st/
mv tmp/muffin/doc/reference/html/* $version/muffin/

echo "Fixing links"
cd $version

for dir in cinnamon cinnamon-js st muffin; do
    cd $dir
    gtkdoc-rebase --relative --html-dir . --other-dir ../
    gtkdoc-rebase --online --html-dir . --other-dir /usr/share/gtk-doc/
    sed -i 's%/usr/share/gtk-doc/*html/\([a-zA-Z0-9]*\)/%https://developer.gnome.org/\1/unstable/%g' *.html
    sed -i 's%\.\.//%../%g' *.html
    sed -i 's%href="style.css"%href="/style.css"%' *.html

    sed -i 's%^<!DOCTYPE [^>]*>%<!DOCTYPE html>%' *.html
    sed -i 's%^\s*<body[^>]*>\s*$%<body><div id="header"><img src="/logo.svg" /><div id="links"><a href="/index.html">Home</a><a href="/projects.html">Projects</a><a href="/contributing.html">Contributing</a><a href="/reference/index.html">Documentation</a></div></div>%' *.html

    cd ..
done
rm -f */style.css */index.sgml */*.devhelp2

if [ $version == "git" ]; then
    version="Git"
fi

echo "Creating index.html"
echo '<!DOCTYPE html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta http-equiv="X-UA-Compatible" content="chrome=1">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <link rel="stylesheet" type="text/css" href="/style.css">

    <title>Cinnamon '$version' Documentation</title>
  </head>

  <body>
    <div id="header">
      <img src="/logo.svg" />
      <div id="links">
        <a href="/index.html">Home</a>
        <a href="/projects.html">Projects</a>
        <a href="/contributing.html">Contributing</a>
        <a href="/reference/index.html">Documentation</a>
      </div>
    </div>

    <h1>Cinnamon '$version' Documentation</h1>

    This is the documentation for Cinnamon '$version'.
    <ul>
      <li><a href="cinnamon/index.html">Cinnamon Core</a></li>
      <li><a href="cinnamon-js/index.html">Cinnamon JS</a></li>
      <li><a href="st/index.html">Cinnamon St</a></li>
      <li><a href="muffin/index.html">Muffin</a></li>
    </ul>
  </body>
</html>' > index.html

echo "Success!"
