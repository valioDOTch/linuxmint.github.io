#!/bin/sh

version="git"
if [ ! -z "$1" ]; then
    version=$1
fi

echo "Cleaning up directory"
rm -rf tmp $version

echo "Creating target directories"
mkdir -p $version/muffin/
mkdir -p $version/cinnamon-js/
mkdir -p $version/cinnamon/
mkdir -p $version/st/

echo "Creating temp build directory"
mkdir tmp
cd tmp

echo "Cloning Cinnamon repo"
git clone https://github.com/linuxmint/Cinnamon

echo "Cloning Muffin repo"
git clone https://github.com/linuxmint/muffin

if [ ! -z "$1" ]; then
    cd Cinnamon
    tag=`git tag | grep "^$1" | tail -1`
    git checkout $tag
    cd ..

    cd muffin
    tag=`git tag | grep "^$1" | tail -1`
    git checkout $tag
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
    sed -i 's%/usr/share/gtk-doc//html/\([a-zA-Z0-9]*\)/%https://developer.gnome.org/\1/unstable/%g' *.html
    cd ..
done

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
    <link href='https://fonts.googleapis.com/css?family=Architects+Daughter' rel='stylesheet' type='text/css'>
    <link rel="stylesheet" type="text/css" href="../../stylesheets/stylesheet.css" media="screen">
    <link rel="stylesheet" type="text/css" href="../../stylesheets/github-light.css" media="screen">
    <link rel="stylesheet" type="text/css" href="../../stylesheets/print.css" media="print">

    <!--[if lt IE 9]>
    <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->

    <title>Cinnamon '$version' Documentation</title>
  </head>

  <body>
    <header>
      <div class="inner">
        <h1>Cinnamon '$version' Documentation</h1>
        <h2></h2>
        <a href="https://github.com/linuxmint" class="button"><small>Follow me on</small> GitHub</a>
      </div>
    </header>

    <div id="content-wrapper">
      <div class="inner clearfix">
        <section id="main-content">
          You are looking at the documentation for Cinnamon '$version'.
          <ul>
            <li><a href="cinnamon/">Cinnamon Core</a></li>
            <li><a href="cinnamon-js/">Cinnamon JS</a></li>
            <li><a href="st/">Cinnamon St</a></li>
            <li><a href="muffin/">Muffin</a></li>
          </ul>
        </section>
    </div>
  </body>
</html>' > index.html

echo "Removing tmp dir"
cd ..
rm -rf tmp

echo "Done!"
