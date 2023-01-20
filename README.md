# Simple chatbot example using MATLAB
[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=toshiakit/simple_chatbot) 

It seems everyone is talking about ChatGPT these days thanks to its impressive capabilities to mimic human speech. It is obviously a very sophisticated AI, but it is based on the language model that predicts the next words based on the preceding words.
N-gram language models are very simple and you can code it very easily in MATLAB with Text Analytics Toolbox. Here is an example of a bot that generates random Shakespeare-like sentences. (this is based on [my old blog post](https://blogs.mathworks.com/loren/2015/09/09/text-mining-shakespeare-with-matlab/)).
## Import data
Let's start by importing [Romeo and Juliet](http://www.gutenberg.org/files/1513/1513-h/1513-h.htm) from Gutenberg Project.
```
rawtxt = webread('http://www.gutenberg.org/files/1513/1513-h/1513-h.htm');
tree = htmlTree(rawtxt);
```
## Preprocess text
We only want to include actual lines characters speak, not stage directions, etc.
```
subtree = findElement(tree,'p:not(.scenedesc):not(.right):not(.letter)');
romeo = extractHTMLText(subtree);
```
We also don't want empty rows and the prologue.
```
romeo(romeo == '') = [];
romeo(1:5) = [];
```
Each line start with the name of the character, followed by . and return character. We can use this pattern to split the names from the actual lines.
```
pat = "\." + newline;
cstr = regexp(romeo,pat,'split','once');
```
This creates a cell array because not all rows can be split using the pattern, because some lines run multiple rows. Let's create a new string array and extract content of the cell array into it.
```
dialog = strings(size(cstr,1),2);
is2 = cellfun(@length,cstr) == 2;
dialog(is2,:) = vertcat(cstr{is2});
dialog(~is2,2) = vertcat(cstr{~is2});
dialog = replace(dialog,newline, " ");
dialog = eraseBetween(dialog,'[',']','Boundaries','inclusive');
```
## N-grams
An n-gram is a sequence of words that appear together in a sentence. Commonly word tokens are used, and they are unigrams. You can also use a pair of words, and that's a bigram. Trigrams use three words, etc.
Therefore, the next step is to tokenize the lines, which are in the second column of dialog.
```
doc = tokenizedDocument(dialog(:,2));
doc = lower(doc);
doc(doclength(doc) < 3) = [];
```
We also need to add sentence markers <s> and </s> to indicate the start and the end of sentences.
```
doc = docfun(@(x) ['<s>' x '</s>'], doc);
```
## Language models
Language models are used to predict a sequence of words in a sentence based on chained conditional probabilities. These probabilities are estimated by mining a collection of text known as a corpus and 'Romeo and Juliet' is our corpus. Language models are made up of such word sequence probabilities.
Let's start by generating a bag of N-grams, which contains both the list of words and their frequencies.
```
bag1 = bagOfWords(doc);
bag2 = bagOfNgrams(doc);
bag3 = bagOfNgrams(doc,'NgramLengths',3);
```
We can then use the frequencies to calculate the probabilities.
Here is a bigram example of how you would compute conditional probability of "art" following "thou".

$p(art|thou) = \frac{count(thou+art)}{count(thou)}$

Here is an example for trigrams that computes conditional probability of "romeo" following "thou art".

$p(romeo|thou+art) = \frac{count(thou+art+romeo)}{count(thou+art)}$

Let's create a bigram language model Mdl2, which is a matrix whose rows corresponds to the first words in the bigram and the columns the second. using dictionary data type introduced in R2022b. 
```
Vocab1 = bag1.Vocabulary;
Vocab2 = bag2.Ngrams;
Mdl2 = dictionary;
for ii = 1:size(Vocab2,1)
    tokens = Vocab2(ii,:);
    isPrev = Vocab1 == tokens(1);
    Mdl2(join(tokens)) = sum(bag2.Counts(:,ii))/sum(bag1.Counts(:,isPrev)); 
end
```
You can check the words that follow 'thou' sorted by probability.
```
T = entries(Mdl2);
myKeys = split(T.Key);
thou_entries = T(myKeys(:,1) == 'thou',:);
thou_entries = sortrows(thou_entries,"Value","descend");
```
Let's also create a trigram language model Mdl3
```
Vocab3 = bag3.Ngrams;
Mdl3 = dictionary;
for ii = 1:size(Vocab3,1)
    tokens = Vocab3(ii,:);
    isPrev = all(Vocab2 == tokens(1:2),2);
    Mdl3(join(tokens)) = sum(bag3.Counts(:,ii))/sum(bag2.Counts(:,isPrev));
end
```
You can also check the words that follow 'thou shalt' sorted by probability.
```
T = entries(Mdl3);
myKeys = split(T.Key);
thou_shalt_entries = T(join(myKeys(:,1:2)) == "thou shalt",:);
thou_shalt_entries = sortrows(thou_shalt_entries,"Value","descend");
```
## Predict next word
We can then use nextWord function to generate text.
```
outtext = "<s>";
outtext = [outtext nextWord(Mdl2,outtext)];
while outtext(end) ~= "</s>"
    outtext = [outtext nextWord(Mdl3,outtext(end-1:end))];
    if outtext(end) == "."
        break
    end
end
strtrim(replace(join(outtext),{'<s>','</s>'},''))
```
## Generate text
We can turn this into a function textGen as well.
```
outtext = textGen(Mdl2,Mdl3,firstWord='romeo')
```
