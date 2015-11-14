$LOAD_PATH << '..'
require "MH_util"

class BayesText
include MH_util

    def initialize(trainingdir, stopwordlist, ignoreBucket)
=begin    
        This class implements a naive Bayes approach to text
        classification
        trainingdir is the training data. Each subdirectory of
        trainingdir is titled with the name of the classification
        category -- those subdirectories in turn contain the text
        files for that category.
        The stopwordlist is a list of words (one per line) will be
        removed before any counting takes place.
=end
        @vocabulary = {}
        @prob = {}
        @totals = {}
        @stopwords = {}

        open(stopwordlist).each do |line|
            @stopwords[line.strip] = 1
        end

        #filter out files that are not directories
        @categories = []
        Dir.foreach(trainingdir) do |x|
            @categories << x if (x != "." && x != ".." && File.directory?(trainingdir+x))
        end

        puts "Counting ..."
        @categories.each do |category|
            (@prob[category], @totals[category]) = train(trainingdir, category, ignoreBucket)
        end

        # I am going to eliminate any word in the vocabulary
        # that doesn't occur at least 3 times
        toDelete = []
        @vocabulary.keys.each do |word|
            if @vocabulary[word] < 3
                # mark word for deletion
                # can't delete now because you can't delete
                # from a list you are currently iterating over
                toDelete << word
            end
        end
        
        # now delete
        toDelete.each do |word|
            @vocabulary.delete(word)
        end
        
        # now compute probabilities
        vocabLength = @vocabulary.length

        @categories.each do |category|
            denominator = @totals[category] + vocabLength
            @vocabulary.keys.each do |word|
                if @prob[category].has_key? word
                    count = @prob[category][word]
                else
                    count = 1
                end
                @prob[category][word] = (count + 1).fdiv(denominator)
            end
        end
        #print ("DONE TRAINING\n\n")
    end

    def train(trainingdir, category, bucketNumberToIgnore)
        # counts word occurrences for a particular category
        ignore = "%i" % bucketNumberToIgnore
        currentdir = trainingdir + category
        directories = []
        Dir.foreach(currentdir) {|x| directories << x if x != "." && x != ".."}
        counts = {}
        total = 0
        
        directories.each do |directory|
            if directory != ignore
                currentBucket = trainingdir + category + "/" + directory
                files = []
                Dir.foreach(currentBucket) {|x| files << x if x != "." && x != ".."}
                files.each do |file|
                    f = File.open(currentBucket + "/" + file, "r:iso8859-1")
                    f.each_line do |line|
                        tokens = line.split
                        tokens.each do |token|
                            # get rid of punctuation and lowercase token
                            token = my_strip(token, '\'".,?:-')
                            token = token.downcase
                            if token != "" and not @stopwords.has_key? token
                                @vocabulary[token] = 0 if not @vocabulary.has_key? token
                                @vocabulary[token] += 1
                                counts[token] = 0 if not counts.has_key? token
                                counts[token] += 1
                                total += 1
                            end
                        end
                    end
                    f.close()
                end
            end
        end
        return counts, total
    end
                    
                    
    def classify(filename)
        results = {}
        @categories.each do |category|
            results[category] = 0
        end
        
        f = File.open(filename, "r:iso8859-1")
        f.each_line do |line|
            tokens = line.split
            tokens.each do |token|
                token = my_strip(token, '\'".,?:-')
                token = token.downcase
                if @vocabulary.has_key? token
                    @categories.each do |category|
                        if @prob[category][token] == 0
                            print "%s %s\n" % [category, token]
                        end
                        results[category] += Math.log(@prob[category][token])
                    end
                end
            end
        end
        f.close()
        
        results = results.to_a
        results.sort_by! {|element| -element[1]}
        # for debugging I can change this to give me the entire list
        return results[0][0]
    end
    
    def testCategory(direc, category, bucketNumber)
        results = {}
        directory = direc + ("%i/" % bucketNumber)
        #print("Testing " + directory)
        files = []
        Dir.foreach(directory) {|x| files << x if x != "." && x != ".."}
        total = 0
        correct = 0
        files.each do |file|
            total += 1
            result = classify(directory + file)
            results[result] = 0 if not results.has_key? result
            results[result] += 1
        end
        return results
    end

    def test(testdir, bucketNumber)
=begin
        Test all files in the test directory--that directory is
        organized into subdirectories--each subdir is a classification
        category
=end
        results = {}
        #filter out files that are not directories
        categories = []
        Dir.foreach(testdir) do |x|
            categories << x if (x != "." && x != ".." && File.directory?(testdir+x))
        end
        correct = 0
        total = 0
        categories.each do |category|
            results[category] = testCategory(testdir + category + '/', category, bucketNumber)
        end
        return results
    end
end

def tenfold(dataPrefix, stoplist)
    results = {}
    categories = []
    0.upto 9 do |i|
        bT = BayesText.new(dataPrefix, stoplist, i)
        r = bT.test(@theDir, i)
        r.each do |key, value|
            results[key] = {} if not results.has_key? key
            value.each do |ckey, cvalue|
                results[key][ckey] = 0 if not results[key].has_key? ckey
                results[key][ckey] += cvalue
                categories = results.keys
            end
        end
    end
    categories.sort!
    print(   "\n       Classified as: \n")
    header =    "          "
    subheader = "        +"
    categories.each do |category|
        header += "% 2s   " % category
        subheader += "-----+"
    end
    puts header
    puts subheader
    total = 0.0
    correct = 0.0
    categories.each do |category|
        row = " %s    |" % category 
        categories.each do |c2|
            if results[category].has_key? c2
                count = results[category][c2]
            else
                count = 0
            end
            row += " %3i |" % count
            total += count
            if c2 == category
                correct += count
            end
        end
        puts row
    end
        
    puts subheader
    print "\n%5.3f percent correct\n" % ((correct * 100) / total)
    print "total of %i instances\n" % total
end

# change these to match your directory structure
prefixPath = "review_polarity_buckets/"
@theDir = prefixPath + "txt_sentoken/"
stoplistfile = prefixPath + "stopwords25.txt"
tenfold(@theDir, stoplistfile)
