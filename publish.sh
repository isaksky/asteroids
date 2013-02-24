#http://dl.dropbox.com/u/39905199/box.html
echo "Publishing /out"
rsync -av out/ ~/Dropbox/Public/out/
echo "Publishing /libs"
rsync -av libs/ ~/Dropbox/Public/libs/
echo "Publishing /css"
rsync -av css/ ~/Dropbox/Public/css/
echo "Publishing *.html"
rsync -tv *.html ~/Dropbox/Public/
