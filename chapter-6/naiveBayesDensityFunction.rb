  
# 
#  Naive Bayes Classifier chapter 6
#

# _____________________________________________________________________

class Classifier
    def initialize(bucketPrefix, testBucketNumber, dataFormat)
=begin
        a classifier will be built from files with the bucketPrefix
        excluding the file with textBucketNumber. dataFormat is a string that
        describes how to interpret each line of the data files. For example,
        for the iHealth data the format is:
        "attr	attr	attr	attr	class"
=end        
   
        total = 0
        classes = {}
        # counts used for attributes that are not numeric
        counts = {}
        # totals used for attributes that are numereric
        # we will use these to compute the mean and sample standard deviation for
        # each attribute - class pair.
        totals = {}
        numericValues = {}
        
        
        # reading the data in from the file
        
        @format = dataFormat.strip.split("\t")
        # 
        @prior = {}
        @conditional = {}
 
        # for each of the buckets numbered 1 through 10:
        1.upto 10 do |i|
            # if it is not the bucket we should ignore, read in the data
            if i != testBucketNumber
                filename = "%s-%02i" % [bucketPrefix, i]
                f = open(filename)
                lines = f.readlines()
                f.close()
                lines.each do |line|
                    fields = line.strip.split("\t")
                    ignore = []
                    vector = []
                    nums = []
                    category = "" # don't know how Python code works without this
                    0.upto fields.length-1 do |i|
                        if @format[i] == 'num'
                            nums << fields[i].to_f
                        elsif @format[i] == 'attr'
                            vector << fields[i]                           
                        elsif @format[i] == 'comment'
                            ignore << fields[i]
                        elsif @format[i] == 'class'
                            category = fields[i]
                        end
                    end
                    # now process this instance
                    total += 1
                    classes[category] = 0 if not classes.has_key? category
                    counts[category] = {} if not counts.has_key? category
                    totals[category] = {} if not totals.has_key? category
                    numericValues[category] = {} if not numericValues.has_key? category
                    classes[category] += 1
                    # now process each non-numeric attribute of the instance
                    col = 0
                    vector.each do |columnValue|
                        col += 1
                        counts[category][col] = {} if not counts[category].has_key? col
                        counts[category][col][columnValue] = 0 if not counts[category][col].has_key? columnValue
                        counts[category][col][columnValue] += 1
                    end
                    # process numeric attributes
                    col = 0
                    nums.each do |columnValue|
                        col += 1
                        totals[category][col] = 0 if not totals[category].has_key? col
                        #totals[category][col].setdefault(columnValue, 0)
                        totals[category][col] += columnValue
                        numericValues[category][col] = [] if not numericValues[category].has_key? col
                        numericValues[category][col] << columnValue
                    end
                end    
            end
        end
        #
        # ok done counting. now compute probabilities
        #
        # first prior probabilities p(h)
        #
        classes.each do |category, count|
            @prior[category] = count.fdiv(total)
        end
        #
        # now compute conditional probabilities p(h|D)
        #

        counts.each do |category, columns|
              @conditional[category] = {} if not @conditional.has_key? category
              columns.each do |col, valueCounts|
                  @conditional[category][col] = {} if not @conditional[category].has_key? col
                  valueCounts.each do |attrValue, count|
                      @conditional[category][col][attrValue] = count.fdiv(classes[category])
                  end
              end
        end      
        @tmp =  counts               
        #
        # now compute mean and sample standard deviation
        #
        @means = {}
        @totals = totals
        totals.each do |category, columns|
            @means[category] = {} if not @means.has_key? category
            columns.each do |col, cTotal|
                @means[category][col] = cTotal.fdiv(classes[category])
            end
        end
        # standard deviation
        @ssd = {}

        numericValues.each do |category, columns|
            
            @ssd[category] = {} if not @ssd.has_key? category
            columns.each do |col, values|
                sumOfSquareDifferences = 0
                theMean = @means[category][col]
                values.each do |value|
                    sumOfSquareDifferences += (value - theMean)**2
                end
                columns[col] = 0
                @ssd[category][col] = Math.sqrt(sumOfSquareDifferences.fdiv((classes[category] - 1)))
            end
        end
    end
           
    def testBucket(bucketPrefix, bucketNumber)
=begin  Evaluate the classifier with data from the file
        bucketPrefix-bucketNumber
=end
        
        filename = "%s-%02i" % [bucketPrefix, bucketNumber]
        f = open(filename)
        lines = f.readlines()
        totals = {}
        f.close()
        loc = 1
        lines.each do |line|
            loc += 1
            data = line.strip.split("\t")
            vector = []
            numV = []
            classInColumn = -1
            0.upto @format.length-1 do |i|
                  if @format[i] == 'num'
                      numV << data[i].to_f
                  elsif @format[i] == 'attr'
                      vector << data[i]
                  elsif @format[i] == 'class'
                      classInColumn = i
                  end
            end
            theRealClass = data[classInColumn]
            classifiedAs = classify(vector, numV)
            totals[theRealClass] = {} if not totals.has_key? theRealClass
            totals[theRealClass][classifiedAs] = 0 if not totals[theRealClass].has_key? classifiedAs
            totals[theRealClass][classifiedAs] += 1
        end
        return totals
    end
end
    
    def classify(itemVector, numVector)
        # Return class we think item Vector is in
        results = []
        sqrt2pi = Math.sqrt(2 * Math::PI)
        @prior.each do |category, prior|
            prob = prior
            col = 1
            itemVector.each do |attrValue|
                if not @conditional[category][col].has_key? attrValue
                    # we did not find any instances of this attribute value
                    # occurring with this category so prob = 0
                    prob = 0
                else
                    prob = prob * @conditional[category][col][attrValue]
                end
                col += 1
            end
            col = 1
            numVector.each do |x|
                mean = @means[category][col]
                ssd = @ssd[category][col]
                ePart = Math::E ** (-(x - mean)**2/(2*ssd**2))
                prob = prob * ((1.0 / (sqrt2pi*ssd)) * ePart)
                col += 1
            end
            results << [prob, category]
        end
        # return the category with the highest probability
        return results.max[1]
    end
 
def tenfold(bucketPrefix, dataFormat)
    results = {}
    1.upto 10 do |i|
        c = Classifier.new(bucketPrefix, i, dataFormat)
        t = c.testBucket(bucketPrefix, i)
        t.each do |key, value|
            results[key] = {} if not results.has_key? key
            value.each do |ckey, cvalue|
                results[key][ckey] = 0 if not results[key].has_key? ckey
                results[key][ckey] += cvalue
            end
        end
    end
                
    # now print results
    categories = results.keys
    categories.sort!
    print(   "\n            Classified as: \n")
    header =    "             "
    subheader = "               +"
    categories.each do |category|
        header += "% 10s   " % category
        subheader += "-------+"
    end
    print header + "\n"
    print subheader + "\n"
    total = 0.0
    correct = 0.0
    categories.each do |category|
        row = " %10s    |" % category 
        categories.each do |c2|
            if results[category].has_key? c2
                count = results[category][c2]
            else
                count = 0
            end
            row += " %5i |" % count
            total += count
            if c2 == category
                correct += count
            end
        end
        print row + "\n"
    end
    print subheader + "\n"
    print("\n%5.3f percent correct\n" %((correct * 100) / total))
    print("total of %i instances\n" % total)
end


def pdf(mean, ssd, x)
=begin 
   Probability Density Function  computing P(x|y)
   input is the mean, sample standard deviation for all the items in y,
   and x.
=end
   ePart = Math::E ** (-(x-mean)**2/(2*ssd**2))
   puts ePart.to_s
   return (1.0 / (Math.sqrt(2*Math::PI)*ssd)) * ePart
end

#tenfold("house-votes/hv", "class\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr")
#c = Classifier("house-votes/hv", 0,
#                       "class\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr")
tenfold("pimaSmall/pimaSmall",  "num	num	num	num	num	num	num	num	class")
tenfold("pima/pima",  "num	num	num	num	num	num	num	num	class")

#c = Classifier("iHealth/i", 10,
#                       "attr\tattr\tattr\tattr\tclass")
#print(c.classify([], [3, 78, 50, 32, 88, 31.0, 0.248, 26]))

#c = Classifier("house-votes-filtered/hv", 5, "class\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr\tattr")
#t = c.testBucket("house-votes-filtered/hv", 5)
#print(t)
