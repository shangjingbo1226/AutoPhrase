arguments:
-m mode (train: Given the training text as input, generate its tokenized text as well as the token mapping file;
         test: Given the testing text as well as the token mapping file as input, generate its tokenized text;
		 translate: Given the tokenized text as well as the token mapping file as input, translate the text into its original language)
-l language (If this argument is left blank, we will automatically detect the language.
             EN: English; FR: French; DE: German; ES: Spanish; IT: Italian; PT: Portuguese; RU: Russian; AR: Arabic; CN: Chinese; JA: Japanese)
-c case_sensitive (This argument is not feasible for AR, CN and JA because they are not case sensitive (treated as 'Y').
                   Y: distinguish between uppercase and lowercase;
				   N: cast all characters into lowercase and output one additional file containing bit vectors showing if each original word is
				   first_character_uppercase and all_character_uppercase [punctuations are considered as uppercase as well])
-i input file name
-o output file name
-t dictionary file name

sample commands:
java -jar tokenizer.jar -m train -l CN -i cn_train.txt -o tokenized_cn_train.txt -t token_mapping.txt
java -jar tokenizer.jar -m test -l CN -i cn_test.txt -o tokenized_cn_test.txt -t token_mapping.txt
java -jar tokenizer.jar -m translate -l CN -i cn_tokenized.txt -o raw_cn_tokenized.txt -t token_mapping.txt

java -jar tokenizer.jar -m train -l EN -c N -i en_train.txt -o tokenized_en_train.txt -t token_mapping.txt
java -jar tokenizer.jar -m test -l EN -c N -i en_test.txt -o tokenized_en_test.txt -t token_mapping.txt
java -jar tokenizer.jar -m translate -l EN -c N -i en_tokenized.txt -o raw_en_tokenized.txt -t token_mapping.txt