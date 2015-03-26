$LOAD_PATH << '..'
require "MH_util"

class BayesText
include MH_util

    def initialize(trainingdir, stopwordlist)
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
            print '    ' + category + "\n"
            (@prob[category], @totals[category]) = train(trainingdir, category)
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
        puts "Computing probabilities:"
        @categories.each do |category|
            print '    ' + category + "\n"
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
        print "DONE TRAINING\n\n\n"
    end               

    def train(trainingdir, category)
        #counts word occurrences for a particular category
        currentdir = trainingdir + category
        files = []
        Dir.foreach(currentdir) {|x| files << x if x != "." && x != ".."}
        counts = {}
        total = 0
        files.each do |file|
            #print(currentdir + '/' + file)
            f = File.open(currentdir + "/" + file, "r:iso8859-1")
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
                #print(token)
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

    def testCategory(directory, category)
        files = []
        Dir.foreach(directory) {|x| files << x if x != "." && x != ".."}
        total = 0
        correct = 0
        files.each do |file|
            total += 1
            result = classify(directory + file)
            if result == category
                correct += 1
            end
        end
        return correct, total
    end

    def test(testdir)
=begin
        Test all files in the test directory--that directory is
        organized into subdirectories--each subdir is a classification
        category
=end
        #filter out files that are not directories
        categories = []
        Dir.foreach(testdir) do |x|
            categories << x if (x != "." && x != ".." && File.directory?(testdir+x))
        end
        correct = 0
        total = 0
        categories.each do |category|
            print "."
            (catCorrect, catTotal) = testCategory(testdir + category + "/", category)
            correct += catCorrect
            total += catTotal
        end
        print "\n\nAccuracy is  %f%%  (%i test instances)\n" % [(correct.to_f / total) * 100, total]
    end
end
            
# change these to match your directory structure
baseDirectory = "20news-bydate/"
trainingDir = baseDirectory + "20news-bydate-train/"
testDir = baseDirectory + "20news-bydate-test/"


stoplistfile = "stopwords0.txt"
print("Reg stoplist 0 \n")
bT = BayesText.new(trainingDir, baseDirectory + "stopwords0.txt")
print("Running Test ...\n")
bT.test(testDir)

print("\n\nReg stoplist 25 \n")
bT = BayesText.new(trainingDir, baseDirectory + "stopwords25.txt")
print("Running Test ...\n")
bT.test(testDir)

print("\n\nReg stoplist 174 \n")
bT = BayesText.new(trainingDir, baseDirectory + "stopwords174.txt")
print("Running Test ...")
bT.test(testDir)
