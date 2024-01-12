name=stroke_order_animator
path=/tmp/$name

rm -rf $path \
&& flutter create $path \
    --project-name=$name \
    --description="Stroke order animations and quizzes for Chinese characters." \
    --org=com.chillchinese \
    --offline \
    --platforms=android \
    --platforms=web \
    --platforms=linux \
&& rm $path/lib/main.dart \
&& rm $path/test/widget_test.dart \
&& rm $path/README.md \
&& rm $path/analysis_options.yaml \
&& rm -r $path/.dart_tool \
&& rm -r $path/.idea \
&& rsync -r $path/** .
