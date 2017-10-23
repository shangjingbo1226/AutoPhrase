import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.StringReader;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicInteger;

import org.apache.lucene.analysis.Analyzer;
import org.apache.lucene.analysis.TokenStream;
import org.apache.lucene.analysis.ar.ArabicAnalyzer;
import org.apache.lucene.analysis.cn.smart.SmartChineseAnalyzer;
import org.apache.lucene.analysis.de.GermanAnalyzer;
import org.apache.lucene.analysis.en.EnglishAnalyzer;
import org.apache.lucene.analysis.es.SpanishAnalyzer;
import org.apache.lucene.analysis.fr.FrenchAnalyzer;
import org.apache.lucene.analysis.it.ItalianAnalyzer;
import org.apache.lucene.analysis.ja.JapaneseAnalyzer;
import org.apache.lucene.analysis.ja.JapaneseTokenizer;
import org.apache.lucene.analysis.ja.dict.UserDictionary;
import org.apache.lucene.analysis.ja.tokenattributes.PartOfSpeechAttribute;
import org.apache.lucene.analysis.pt.PortugueseAnalyzer;
import org.apache.lucene.analysis.ru.RussianAnalyzer;
import org.apache.lucene.analysis.standard.StandardTokenizer;
import org.apache.lucene.analysis.tokenattributes.CharTermAttribute;
import org.apache.lucene.analysis.tokenattributes.OffsetAttribute;
import org.apache.lucene.analysis.util.CharArraySet;
import org.apache.lucene.util.AttributeFactory;

import com.cybozu.labs.langdetect.Detector;
import com.cybozu.labs.langdetect.DetectorFactory;
import com.cybozu.labs.langdetect.LangDetectException;

import java.util.Properties;

import org.ansj.domain.Result;
import org.ansj.domain.Term;
import org.ansj.splitWord.analysis.ToAnalysis;

class SpecialTagger {
	public String[] tag(String text) {
		String[] ret = new String[1];
		ret[0] = text;
		return ret;
	}
}

class StandardTagger extends SpecialTagger {
	@Override
	public String[] tag(String text) {
		StandardTokenizer tokenizer = new StandardTokenizer();
		tokenizer.setReader(new StringReader(text));
		CharTermAttribute attr = tokenizer.addAttribute(CharTermAttribute.class);
		ArrayList<String> result = new ArrayList<String>();
		try {
			tokenizer.reset();
			while(tokenizer.incrementToken()) {
			    String term = attr.toString();
			    result.add(term + "/UNKNOWN"); // the first term is the token and the second term is its POS tag
			}
			tokenizer.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return result.toArray(new String[result.size()]);
	}
}

class ChineseTagger extends SpecialTagger{
	ToAnalysis tagger;

	public ChineseTagger() {
		tagger = new ToAnalysis();
	}

	@Override
	public String[] tag(String text) {
		Result result = tagger.parseStr(text);
		String[] ret = new String[result.size()];
		int ptr = 0;
		for (Term term : result.getTerms()) {
			ret[ptr ++] = term.toString();
		}
		return ret;
	}
}

public class Tokenizer {
    private static HashMap<String, String> punctuation_mapping;

    private static AtomicInteger counter;
    private static ConcurrentHashMap<String, Integer> token2id;
    private static String[] distinctTokens = null;

    private static String UNKNOWN_TOKEN = "-1111";
    private static Integer TEXT_SAMPLE_LIMIT = 1000;

    private static int BLOCK_SIZE = 10000;

    private static String detectLanguage(String textFileName) {
        String language = "";
        try {
            DetectorFactory.clear();
            /*String[] filenames = {"ar","bg","bn","ca","cs","da","de","el","en","es","et","fa","fi","fr","gu","he","hi",
                    "hr","hu","id","it","ja","ko","lt","lv","mk","ml","nl","no","pa","pl","pt","ro","ru","si","sq","sv",
                    "ta","te","th","tl","tr","uk","ur","vi","zh-cn","zh-tw"};*/
            String[] filenames = {"ar", "de", "en", "es", "fr", "it", "ja", "pt", "ru", "zh-cn"};
            ArrayList<String> jsons = new ArrayList<String>();
            for (String filename : filenames) {
                InputStream in = Tokenizer.class.getResourceAsStream("profiles.sm/" + filename);
                BufferedReader reader = new BufferedReader(new InputStreamReader(in, "UTF8"));
                StringBuilder builder = new StringBuilder();
                while (reader.ready()) {
                    builder.append(reader.readLine());
                }
                reader.close();
                jsons.add(builder.toString());
            }
            DetectorFactory.loadProfile(jsons);

            BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(textFileName), "UTF8"));
            StringBuilder builder = new StringBuilder();
            while (reader.ready()) {
                builder.append(reader.readLine());
                if (builder.length() > TEXT_SAMPLE_LIMIT) {
                    break;
                }
            }
            reader.close();
            String text = builder.toString();

            Detector detector = DetectorFactory.create();
            detector.append(text);
            language = detector.detect();
            if (language.equals("zh-cn")) {
                language = "cn";
            }
            /*if (language.equals("zh-tw")) {
                language = "tw";
            }*/
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (LangDetectException e) {
            e.printStackTrace();
        }
        return language.toUpperCase();
    }

    private static void loadPunctuationMapping(String language) {
        String punctuationMappingFileName = null;
        switch (language) {
            case "EN": case "FR": case "DE": case "ES": case "IT": case "PT": case "RU": case "AR":
                {punctuationMappingFileName = "/indo_european_punctuation_mapping.txt"; break;}
            case "CN": case "JA":
                {punctuationMappingFileName = "/cjk_punctuation_mapping.txt"; break;}
            default:
            	{System.err.println("Using default setting for unknown languages..."); punctuationMappingFileName = "/indo_european_punctuation_mapping.txt";}
        }
        punctuation_mapping = new HashMap<String, String>();
        try {
            InputStream in = Tokenizer.class.getResourceAsStream(punctuationMappingFileName);
            BufferedReader reader = new BufferedReader(new InputStreamReader(in, "UTF8"));
            while (reader.ready()) {
                String line = reader.readLine();
                Integer pos = line.indexOf('\t');
                String from = line.substring(0,  pos);
                String to = line.substring(pos + 1, line.length());
                punctuation_mapping.put(from, to);
                punctuation_mapping.put(to, to);
            }
            reader.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return;
    }

    private static void loadTokenMapping(String tokenMappingFileName) {
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(tokenMappingFileName), "UTF8"));
            int maxId = -1;
            while (reader.ready()) {
                String line = reader.readLine();
                Integer pos = line.indexOf('\t');
                String token = line.substring(pos + 1, line.length());
                int id = Integer.parseInt(line.substring(0, pos));
                token2id.put(token, id);
                maxId = Math.max(maxId, id);
            }
            reader.close();
            distinctTokens = new String[maxId + 1];
            for (ConcurrentHashMap.Entry<String, Integer> entry : token2id.entrySet()) {
            	int i = entry.getValue();
            	String token = entry.getKey();
            	distinctTokens[i] = token;
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return;
    }

    private static void saveTokenMapping(String tokenMappingFileName) {
        try {
            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(tokenMappingFileName), "UTF8"));

            for (ConcurrentHashMap.Entry<String, Integer> entry : token2id.entrySet()) {
            	int i = entry.getValue();
            	String token = entry.getKey();
                writer.write(String.valueOf(i));
                writer.write('\t');
                writer.write(token);
                writer.newLine();
            }
            writer.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return;
    }

    private static SpecialTagger getSuitableTagger(String language, String mode) throws IOException {
        switch (language) {
            case "CN": {return new ChineseTagger();}
        }
        System.err.println("Using default setting for unknown languages...");
        return new StandardTagger();
    }

    private static boolean hasSuitableAnalyzer(String language) throws IOException {
        switch (language) {
            case "EN": case "FR": case "DE": case "ES": case "IT": case "PT": case "RU": case "JA": case "AR": {return true;}
            default: {return false;}
        }
    }

    private static Analyzer getSuitableAnalyzer(String language, String mode) throws IOException {
        CharArraySet empty = new CharArraySet(0, true);
        Analyzer analyzer = null;
        switch (language) {
            case "EN": {analyzer = new EnglishAnalyzer(empty); break;}
            case "FR": {analyzer = new FrenchAnalyzer(empty); break;}
            case "DE": {analyzer = new GermanAnalyzer(empty); break;}
            case "ES": {analyzer = new SpanishAnalyzer(empty); break;}
            case "IT": {analyzer = new ItalianAnalyzer(empty); break;}
            case "PT": {analyzer = new PortugueseAnalyzer(empty); break;}
            case "RU": {analyzer = new RussianAnalyzer(empty); break;}
            case "CN": {analyzer = new SmartChineseAnalyzer(empty); break;}
            case "JA": {UserDictionary temp = UserDictionary.open(new StringReader(""));
                        analyzer = new JapaneseAnalyzer(temp, JapaneseTokenizer.Mode.NORMAL, empty, new HashSet<String>()); break;}
            case "AR": {analyzer = new ArabicAnalyzer(empty); break;}
            default: {System.err.println("[ERROR] unknown language: " + language + "!!!");}
        }
        return analyzer;
    }

    private static ArrayList<ArrayList<String>> lineToTokens(SpecialTagger tagger, String line, String mode) throws IOException {
        ArrayList<ArrayList<String>> arr = new ArrayList<ArrayList<String>>();
        ArrayList<String> tokens = new ArrayList<String>();
        ArrayList<String> tags = new ArrayList<String>();

        String[] results = tagger.tag(line);
        for (String taggedToken : results) {
        	String[] parts = taggedToken.split("/");
        	if (parts.length == 2) {
        		tokens.add(parts[0]);
        		tags.add(parts[1]);
        	} else if (parts.length > 0) {
        		if (parts[0].length() == 1 && Character.isWhitespace(parts[0].charAt(0))) {
        			continue;
        		}
        		tokens.add(parts[0]);
        		tags.add("UNKNOWN");
        	}

        }
        arr.add(tokens);
        arr.add(tags);
        return arr;
    }

    /**
     * Use the given text analyzer to parse one line of text into a list of tokens.
     * @param analyzer The given analyzer of the particular language of the text
     */
    private static ArrayList<ArrayList<String>> lineToTokens(Analyzer analyzer, String line, String mode) throws IOException {
        ArrayList<ArrayList<String>> arr = new ArrayList<ArrayList<String>>(2);
        ArrayList<String> tokens = new ArrayList<String>();
        ArrayList<String> tags = new ArrayList<String>();

        TokenStream lineinput = analyzer.tokenStream("test", line);
        OffsetAttribute offsetAttribute = lineinput.getAttribute(OffsetAttribute.class);
        PartOfSpeechAttribute posAttribute = lineinput.getAttribute(PartOfSpeechAttribute.class);
        lineinput.reset();
        int lastOffset = 0;
        while (lineinput.incrementToken()) {
            int startOffset = offsetAttribute.startOffset();
            int endOffset = offsetAttribute.endOffset();
            // assumption here is the length of any punctuation is 1
            for (int i = lastOffset; i < startOffset; ++ i) {
                if (!Character.isWhitespace(line.charAt(i))) {
                    tokens.add("" + line.charAt(i));
                    if (posAttribute != null) {
                        tags.add("SENT");
                    }
                }
            }
            String token = line.substring(startOffset, endOffset);
            for (int i = 0; i < token.length(); ++ i) {
                if (Character.isWhitespace(token.charAt(i))) {
                    System.err.println("[Warning] White Space in tokens!!!  " + token);
                }
            }
            tokens.add(token);
            lastOffset = endOffset;
            if (posAttribute != null) {
                tags.add(posAttribute.getPartOfSpeech());
            }
        }
        // dealing with the tail
        for (int i = lastOffset; i < line.length(); ++ i) {
            if (!Character.isWhitespace(line.charAt(i))) {
                tokens.add("" + line.charAt(i));
                if (posAttribute != null) {
                    tags.add("SENT");
                }
            }
        }
        lineinput.close();
        arr.add(tokens);
        arr.add(tags);
        return arr;
    }

    private static int isNumeric(String str) {
        try {
            double d = Double.parseDouble(str);
        } catch(NumberFormatException nfe) {
            return 0;
        }
        return 1;
    }

    private static class Output {
    	public ArrayList<ArrayList<String>> tokenPairs;
    	public String mainOutput, caseOutput, rawOutput, tagOutput;
    }

    static int threads;
    static ConcurrentHashMap<String, Analyzer> analyzers = new ConcurrentHashMap<String, Analyzer>();
    static ConcurrentHashMap<String, SpecialTagger> taggers = new ConcurrentHashMap<String, SpecialTagger>();
    static ExecutorService service;

    private static SpecialTagger getTagger(String threadName, String language, String mode) {
    	if (!taggers.containsKey(threadName)) {
    		try {
    			// System.err.println("[DEBUG] " + threadName);
    			taggers.put(threadName, getSuitableTagger(language, mode));
			} catch (IOException e) {
				e.printStackTrace();
			}
    	}
    	return taggers.get(threadName);
    }

    private static Analyzer getAnalyzer(String threadName, String language, String mode) {
    	if (!analyzers.containsKey(threadName)) {
    		try {
				analyzers.put(threadName, getSuitableAnalyzer(language, mode));
			} catch (IOException e) {
				e.printStackTrace();
			}
    	}
    	return analyzers.get(threadName);
    }

    private static void batchMode(ArrayList<String> lines, ArrayList<String> prefixs, BufferedWriter writer, BufferedWriter case_writer, BufferedWriter raw_writer, BufferedWriter tag_writer, String mode, String language, String case_sen) throws IOException {
        ArrayList<Future<Output>> futures = new ArrayList<Future<Output>>();
        for (final String line : lines) {
            Callable<Output> callable = new Callable<Output>() {
                public Output call() throws Exception {
                	Output output = new Output();
                	ArrayList<ArrayList<String>> token_pairs;
                	if (!hasSuitableAnalyzer(language)) {
                		SpecialTagger tagger = getTagger(Thread.currentThread().getName(), language, mode);
                		token_pairs = lineToTokens(tagger, line, mode);
                	} else {
                		Analyzer analyzer = getAnalyzer(Thread.currentThread().getName(), language, mode);
                		token_pairs = lineToTokens(analyzer, line, mode);
                	}

                    ArrayList<String> tokens = token_pairs.get(0);
                    ArrayList<String> tags = token_pairs.get(1);
                    if (mode.equals("train") || mode.equals("test") || mode.equals("direct_test")) {
                        if (tag_writer != null) {
                            StringBuilder buffer_token = new StringBuilder();
                            for (int i = 0; i < tags.size(); ++ i) {
                                if (i > 0) { buffer_token.append(' '); }
                                buffer_token.append(tags.get(i));
                            }
                            output.tagOutput = buffer_token.toString();
                        }
                        if (tag_writer == null || mode.equals("test") || mode.equals("direct_test")) { // we always need raw tokens under the test mode
                            StringBuilder buffer_token = new StringBuilder();
                            for (int i = 0; i < tokens.size(); ++ i) {
                                if (i > 0) { buffer_token.append(' '); }
                                String token = tokens.get(i);
                                if (punctuation_mapping.containsKey(token)) {
                                    buffer_token.append(punctuation_mapping.get(token));
                                }
                                else {
                                    buffer_token.append(token);
                                }
                            }
                            output.rawOutput = buffer_token.toString();
                        }
                    }
                    if (mode.equals("train") && case_sen.equals("Y")) {
                        StringBuilder buffer_token = new StringBuilder();
                        for (int i = 0; i < tokens.size(); ++ i) {
                            if (i > 0) { buffer_token.append(' '); }
                            String token = tokens.get(i);
                            if (punctuation_mapping.containsKey(token)) {
                                buffer_token.append(punctuation_mapping.get(token));
                            } else {
                                if (!token2id.containsKey(token)) {
                                    token2id.put(token, counter.incrementAndGet());
                                }
                                buffer_token.append(String.valueOf(token2id.get(token)));
                            }
                        }
                        output.mainOutput = buffer_token.toString();
                    } else if (mode.equals("train") && case_sen.equals("N")) {
                        StringBuilder buffer_token = new StringBuilder();
                        StringBuilder buffer_case = new StringBuilder();
                        for (int i = 0; i < tokens.size(); ++ i) {
                            if (i > 0) { buffer_token.append(' '); }
                            String token = tokens.get(i);

                            int first_upper = Character.isUpperCase(token.charAt(0)) ? 1 : 0;
                            int all_upper = 1;
                            int all_digit = isNumeric(token);
                            for (int j = 0; j < token.length(); ++ j) {
                                if (!Character.isUpperCase(token.charAt(j))) {
                                    all_upper = 0;
                                    break;
                                }
                            }

                            String lower_token = token.toLowerCase();
                            if (punctuation_mapping.containsKey(lower_token)) {
                                buffer_token.append(punctuation_mapping.get(lower_token));
                                buffer_case.append('3');
                            } else {
                                if (!token2id.containsKey(lower_token)) {
                                    token2id.put(lower_token, counter.incrementAndGet());
                                }
                                buffer_token.append(String.valueOf(token2id.get(lower_token)));
                                buffer_case.append(((Integer)((all_digit << 2) ^ (all_upper << 1) ^ first_upper)).toString());
                            }
                        }
                        output.mainOutput = buffer_token.toString();
                        output.caseOutput = buffer_case.toString();
                    } else if (mode.equals("test") || mode.equals("direct_test")) {
                        StringBuilder buffer_token = new StringBuilder();
                        for (int i = 0; i < tokens.size(); ++ i) {
                            if (i > 0) { buffer_token.append(' '); }
                            String token = tokens.get(i);
                            if (case_sen.equals("N")) {
                                token = token.toLowerCase();
                            }
                            if (punctuation_mapping.containsKey(token)) {
                                buffer_token.append(punctuation_mapping.get(token));
                            } else {
                                if (!token2id.containsKey(token)) {
                                    buffer_token.append(UNKNOWN_TOKEN);
                                } else {
                                    buffer_token.append(String.valueOf(token2id.get(token)));
                                }
                            }
                        }
                        output.mainOutput = buffer_token.toString();
                    }
                    else if (mode.equals("translate")) {
                        StringBuilder buffer_token = new StringBuilder();
                        for (int i = 0; i < tokens.size(); ++ i) {
                            if (i > 0) { buffer_token.append(' '); }
                            String token = tokens.get(i);
                            int size = distinctTokens.length;
                            if (token.matches("[0-9]+") && Integer.parseInt(token) < size) {
                                buffer_token.append(distinctTokens[Integer.parseInt(token)]);
                            } else {
                                buffer_token.append(token);
                            }
                        }
                        output.mainOutput = buffer_token.toString();
                    }
                    return output;
                }
            };
            futures.add(service.submit(callable));
        }

        ArrayList<Output> outputs = new ArrayList<Output>();
        for (Future<Output> future : futures) {
            try {
				outputs.add(future.get());
			} catch (InterruptedException e) {
				e.printStackTrace();
			} catch (ExecutionException e) {
				e.printStackTrace();
			}
        }

        if (writer != null) {
        	int i = 0;
        	for (Output output : outputs) {
        		writer.write(prefixs.get(i) + output.mainOutput);
        		writer.newLine();
        		++ i;
        	}
        }

    	if (tag_writer != null) {
    		for (Output output : outputs) {
                tag_writer.write(output.tagOutput);
                tag_writer.newLine();
            }
    	}
    	if (raw_writer != null) {
    		for (Output output : outputs) {
                raw_writer.write(output.rawOutput);
                raw_writer.newLine();
            }
    	}
    	if (case_writer != null) {
    		for (Output output : outputs) {
                case_writer.write(output.caseOutput);
                case_writer.newLine();
            }
        }
    }

    static LinkedList<String> tokenBuffer = new LinkedList<String>();
    static LinkedList<String> tokenIDBuffer = new LinkedList<String>();

    private static String nextTokenID(BufferedReader tokenizedReader) throws IOException {
    	while (tokenIDBuffer.size() == 0) {
    		String[] tokens = tokenizedReader.readLine().split(" ");
    		for (String token : tokens) {
    			tokenIDBuffer.add(token.trim());
    		}
    	}
    	return tokenIDBuffer.removeFirst();
    }

    private static String nextToken(BufferedReader tokenizedReader) throws IOException {
    	while (tokenBuffer.size() == 0) {
    		String[] tokens = tokenizedReader.readLine().split(" ");
    		for (String token : tokens) {
    			tokenBuffer.add(token.trim());
    		}
    	}
    	return tokenBuffer.removeFirst();
    }


    private static void mappingBackText(String rawFileName, String targetFileName, String segmentedFileName, String tokenizedRawFileName, String tokenizedIDFileName) throws IOException {
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(rawFileName), "UTF8"));
            BufferedReader segmentedReader = new BufferedReader(new InputStreamReader(new FileInputStream(segmentedFileName), "UTF8"));
            BufferedReader tokenizedRawReader = new BufferedReader(new InputStreamReader(new FileInputStream(tokenizedRawFileName), "UTF8"));
            BufferedReader tokenizedIDReader = new BufferedReader(new InputStreamReader(new FileInputStream(tokenizedIDFileName), "UTF8"));
            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(targetFileName), "UTF8"));

            String buffer = "";
            boolean isPhrase = false;
            while (segmentedReader.ready()) {
                String line = segmentedReader.readLine();
                String[] parts = line.split(" ");
                for (int i = 0; i < parts.length; ++ i) {
                    if (parts[i].equals("<phrase>")) {
                        isPhrase = true;
                    } else if (parts[i].equals("</phrase>")) {
                        if (!isPhrase) {
                    	   writer.write("</phrase>");
                        } else {
                            isPhrase = false;
                        }
                    } else {
                        boolean found = false;
                        int loadCount = 0;
                        //System.err.println("targetTokenID = " + parts[i]);
                        while (!found) {
                            String token = nextToken(tokenizedRawReader);
                            String tokenID = nextTokenID(tokenizedIDReader);

                            if (punctuation_mapping.containsKey(token)) {
                                // skip it
                                continue;
                            }

                            //System.err.println("tokenID = " + tokenID);
                            ++ loadCount;
                            if (loadCount > 100) {
                                System.err.println("[Fatal Error] Load Limit Exceeded! You may want to modify the load limit in the Tokenizer.java");
                                writer.close();
                                System.exit(-1);
                            }
                            
                            while (buffer.indexOf(token) < 0) {
				                for (int seek = 0; seek < token.length() && reader.ready(); ++ seek) {
                                    char newChar = (char)reader.read();
                                    buffer += newChar;
                                }
                                // String newLine = reader.readLine();
                                // if (!newLine.trim().isEmpty()) {
                                //     buffer += newLine + '\n';
                                //     ++ lineInReader;
                                // }
                                if (buffer.indexOf(token) == -1 && buffer.length() > 10000) {
                                    System.err.println("buffer = \n" + buffer);
                                    System.err.println("token = " + token);
                                    System.err.println("[Fatal Error] Buffer Limit Exceeded! You may want to modify the buffer limit in the Tokenizer.java");
                                    writer.close();
                                    System.exit(-1);
                                }
                            }
                            int ptr = buffer.indexOf(token);
                            writer.write(buffer.substring(0, ptr));
                            buffer = buffer.substring(ptr, buffer.length());

                            if (tokenID.equals(parts[i])) {
                                found = true;
                                if (isPhrase) {
                                    isPhrase = false;
                                    writer.write("<phrase>");
                                }
                            }
                                
                            String matched = buffer.substring(0, token.length());
                            if (!matched.equals(token)) {
                                System.err.println("[Fatal Error] Match Failed!");
                                writer.close();
                                System.exit(-1);
                            }
                            writer.write(matched);
                            buffer = buffer.substring(token.length(), buffer.length());
                        }
                    }
                }
            }

            while (reader.ready()) {
                char newChar = (char)reader.read();
                buffer += newChar;
            }
            writer.write(buffer);

            reader.close();
            tokenizedRawReader.close();
            tokenizedIDReader.close();
            segmentedReader.close();
            writer.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void tokenizeText(String rawFileName, String targetFileName, String language, String mode, String case_sen) throws IOException {
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(rawFileName), "UTF8"));
            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(targetFileName), "UTF8"));

            BufferedWriter case_writer = null;
            BufferedWriter raw_writer = null;
            BufferedWriter tag_writer = null;
            if (mode.equals("train")) {
                String newTargetFileFolder = "";
                String[] parts = targetFileName.split("/");
                for (int j = 0; j < parts.length - 1; j++) {
                    newTargetFileFolder += parts[j];
                    newTargetFileFolder += "/";
                }
                if (case_sen.equals("N")) {
                    case_writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(newTargetFileFolder + "case_" + parts[parts.length - 1]), "UTF8"));
                }
                if (language.equals("JA") || language.equals("CN") || !hasSuitableAnalyzer(language)) {
                    tag_writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(newTargetFileFolder + "pos_tags_" + parts[parts.length - 1]), "UTF8"));
                } else {
                    raw_writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(newTargetFileFolder + "raw_" + parts[parts.length - 1]), "UTF8"));
                }
                BufferedWriter language_writer = null;
                language_writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(newTargetFileFolder + "language.txt"), "UTF8"));
                language_writer.write(language);
                language_writer.close();
            } else if (mode.equals("test") || mode.equals("direct_test")) {
                String newTargetFileFolder = "";
                String[] parts = targetFileName.split("/");
                for (int j = 0; j < parts.length - 1; j++) {
                    newTargetFileFolder += parts[j];
                    newTargetFileFolder += "/";
                }
                if (language.equals("JA") || language.equals("CN")) {
                    tag_writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(newTargetFileFolder + "pos_tags_" + parts[parts.length - 1]), "UTF8"));
                } else {
                    raw_writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(newTargetFileFolder + "raw_" + parts[parts.length - 1]), "UTF8"));
                }
            }

            ArrayList<String> lines = new ArrayList<String>();
            ArrayList<String> prefixs = new ArrayList<String>();
            while (reader.ready()) {
                String line = reader.readLine();
                String prefix = "";
                if (mode.equals("translate") || mode.equals("test")) {
                    String[] parts = line.split("\t");
                    for (int j = 0; j < parts.length - 1; j++) {
                    	prefix += parts[j] + "\t";
                    }
                    line = parts[parts.length - 1];
                }
                prefixs.add(prefix);
                lines.add(line);

                if (lines.size() == BLOCK_SIZE) {
                	batchMode(lines, prefixs, writer, case_writer, raw_writer, tag_writer, mode, language, case_sen);
                	lines.clear();
                	prefixs.clear();
                }
            }

            // dealing with the tail
            if (lines.size() > 0) {
            	batchMode(lines, prefixs, writer, case_writer, raw_writer, tag_writer, mode, language, case_sen);
            }

            reader.close();
            writer.close();
            if (mode.equals("train") || mode.equals("test") || mode.equals("direct_test")) {
                if (case_writer != null) {
                	case_writer.close();
                }
                if (tag_writer != null) {
                    tag_writer.close();
                } else {
                    raw_writer.close();
                }
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return;
    }

    public static void main(String args[]) throws IOException {
    	long startTime = System.currentTimeMillis();
        // java -jar tokenizer.jar
        // -m train     -l EN -c Y -i en_train.txt     -o tokenized_en_train.txt -t token_mapping.txt
        // -m test      -l EN -c Y -i en_test.txt      -o tokenized_en_test.txt  -t token_mapping.txt
        // -m translate -l EN      -i en_tokenized.txt -o raw_en_tokenized.txt   -t token_mapping.txt
        String mode = "";
        String language = "";
        String case_sen = "";
        String rawFileName = "";
        String targetFileName = "";
        String tokenMappingFileName = "";
        String segmentedFileName = "";
        String tokenizedRawFileName = "";
        String tokenizedIDFileName = "";
        threads = Runtime.getRuntime().availableProcessors();
        for (int i = 0; i + 1 < args.length; ++ i) {
            switch (args[i]) {
                case "-m": {mode = args[i + 1]; break;}
                case "-l": {language = args[i + 1]; break;}
                case "-c": {case_sen = args[i + 1]; break;}
                case "-i": {rawFileName = args[i + 1]; break;}
                case "-o": {targetFileName = args[i + 1]; break;}
                case "-segmented": {segmentedFileName = args[i + 1]; break;}
                case "-tokenized_raw": {tokenizedRawFileName = args[i + 1]; break;}
                case "-tokenized_id": {tokenizedIDFileName = args[i + 1]; break;}
                case "-t": {tokenMappingFileName = args[i + 1]; break;}
                case "-thread": {threads = Math.min(threads, Integer.parseInt(args[i + 1])); break;}
            }
        }
        if (language.equals("")) {
            language = detectLanguage(mode.equals("translate") ? tokenMappingFileName : rawFileName);
        }
        /*if (language.equals("CN") || language.equals("JA") || language.equals("AR")) {
            case_sen = "Y";
        }*/
        if (mode.equals("segmentation")) {
        	if (rawFileName.isEmpty() || targetFileName.isEmpty() || tokenizedRawFileName.isEmpty() || tokenizedIDFileName.isEmpty() || segmentedFileName.isEmpty()) {
        		System.err.println("[ERROR] Incorrect arguments!!!");
                System.err.println("[ERROR] Typical arguments:");
                System.err.println("java -jar tokenizer.jar -m segmentation -i raw.txt -segmented tokenized_segmented.txt -tokenized_raw raw_tokenized.txt -tokenized_id tokenized.txt -o output.txt -t token_mapping.txt");
                return;
        	}
        } else if (mode.isEmpty() || case_sen.isEmpty() || rawFileName.isEmpty() || targetFileName.isEmpty() || tokenMappingFileName.isEmpty()) {
            System.err.println("[ERROR] Incorrect arguments!!!");
            System.err.println("[ERROR] Typical arguments:");
            System.err.println("java -jar tokenizer.jar -m train     -l EN -c Y -i en_train.txt     -o tokenized_en_train.txt -t token_mapping.txt");
            System.err.println("java -jar tokenizer.jar -m test      -l EN -c Y -i en_test.txt      -o tokenized_en_test.txt  -t token_mapping.txt");
            System.err.println("java -jar tokenizer.jar -m translate -l EN -c Y -i en_tokenized.txt -o raw_en_tokenized.txt   -t token_mapping.txt");
            return;
        }

    	counter = new AtomicInteger(-1);
    	// System.err.println("# of threads = " + threads);
    	service = Executors.newFixedThreadPool(threads);

        loadPunctuationMapping(language);
        token2id = new ConcurrentHashMap<String, Integer>();
        if (mode.equals("train")) {
            tokenizeText(rawFileName, targetFileName, language, mode, case_sen);
            saveTokenMapping(tokenMappingFileName);
        } else if (mode.equals("test") || mode.equals("translate") || mode.equals("direct_test")) {
            loadTokenMapping(tokenMappingFileName);
            tokenizeText(rawFileName, targetFileName, language, mode, case_sen);
        } else if (mode.equals("segmentation")) {
            mappingBackText(rawFileName, targetFileName, segmentedFileName, tokenizedRawFileName, tokenizedIDFileName);

        }
        // System.out.println("Task Completed!");

        service.shutdown();

        long endTime   = System.currentTimeMillis();
        long totalTime = endTime - startTime;
        // System.out.println("Total time = " + totalTime);
    }
}
