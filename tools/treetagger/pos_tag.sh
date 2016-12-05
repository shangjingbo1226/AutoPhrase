export LANGUAGE
bash tools/treetagger/download_parameter_files.sh

rm -f tmp/split_files*

echo -ne "Current step: Splitting files...\033[0K\r"
# Transform the tokenized file into multiple equal-sized files for pos tagging
num_lines=$((`wc -l < $RAW` / $THREAD))
if [ $num_lines -le 0 ] || [ $THREAD -eq 1 ]; then
	cp $RAW tmp/split_files.00000
else
	csplit -s -f "tmp/split_files." -n 5  $RAW $num_lines {$(($THREAD-2))}
fi
for f in tmp/split_files.*
do
    sed -e 's/ /\'$'\n/g' $f > $f.token &
done
wait

echo -ne "Current step: Tagging...\033[0K\r"
export PERL_MM_USE_DEFAULT=1
cd tools/treetagger/
for f in ../../tmp/split_files.*.token
do
    if [ $LANGUAGE == "CN" ]; then
        cmd/tree-tagger-chinese < $f > $f.tagged &
    fi
    if [ $LANGUAGE == "DE" ]; then
        cmd/tree-tagger-german < $f > $f.tagged &
    fi
    if [ $LANGUAGE == "EN" ]; then
        cmd/tree-tagger-english < $f > $f.tagged &
    fi
    if [ $LANGUAGE == "FR" ]; then
        cmd/tree-tagger-french < $f > $f.tagged &
    fi
    if [ $LANGUAGE == "IT" ]; then
        cmd/tree-tagger-italian < $f > $f.tagged &
    fi
    if [ $LANGUAGE == "PT" ]; then
        cmd/tree-tagger-portuguese < $f > $f.tagged &
    fi
    if [ $LANGUAGE == "RU" ]; then
        cmd/tree-tagger-russian < $f > $f.tagged &
    fi
    if [ $LANGUAGE == "ES" ]; then
        cmd/tree-tagger-spanish < $f > $f.tagged &
    fi
done
wait

cd ../../
rm -f ./tmp/pos_tags.txt
echo -ne "Current step: Merging...\033[0K\r"
for f in tmp/split_files.*.tagged
do
    cat $f >> ./tmp/pos_tags.txt
done
echo

rm -f tmp/split_files*
