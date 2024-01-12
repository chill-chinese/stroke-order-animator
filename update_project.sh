name=stroke_order_animator
path=/tmp/$name

rm -rf $path \
&& flutter create $path \
    --project-name=$name \
    --description="Stroke order animations and quizzes for Chinese characters." \
    --org=com.chillchinese \
    --offline \
    --template=package \
&& rm $path/README.md \
&& rm $path/CHANGELOG.md \
&& rm $path/LICENSE \
&& rm $path/lib/stroke_order_animator.dart \
&& rm $path/test/stroke_order_animator_test.dart \
&& rm $path/analysis_options.yaml \
&& rm -r $path/.dart_tool \
&& rm -r $path/.idea \
&& rsync -r $path/** .
