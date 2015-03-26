# divide data into 10 buckets
## import random

def buckets(filename, bucketName, separator, classColumn)
=begin
the original data is in the file named filename
    bucketName is the prefix for all the bucket names
    separator is the character that divides the columns
    (for ex., a tab or comma and classColumn is the column
    that indicates the class"""
=end

    # put the data in 10 buckets
    numberOfBuckets = 10
    data = {}
    # first read in the data and divide by category
    ## with open(filename) as f:
    ##    lines = f.readlines()
    lines = File.readlines(filename)
    ## for line in lines:
    lines.each do |line|
        if separator != '\t'
            ## line = line.replace(separator, '\t')
            line.gsub!(separator, '\t')
        end
        # first get the category
        category = line.split[classColumn]
        ## data.setdefault(category, [])
        data[category] = [] if not data.has_key? category
        ## data[category].append(line)
        data[category] << line
    end
    # initialize the buckets
    buckets = []
    ## for i in range(numberOfBuckets):
    0.upto numberOfBuckets-1 do |i|
        ## buckets.append([])       
        buckets << []
    end
    # now for each category put the data into the buckets
    ## for k in data.keys():
    data.keys.each do |k|
        #randomize order of instances for each class
        data[k].shuffle!
        bNum = 0
        # divide into buckets
        ## for item in data[k]:
        data[k].each do |item|
            buckets[bNum] << item
            bNum = (bNum + 1) % numberOfBuckets
        end
    end

    # write to file
    ## for bNum in range(numberOfBuckets):
    0.upto numberOfBuckets-1 do |bNum|
        f = File.open("%s-%02i" % (bucketName, bNum + 1), 'w')
        ## for item in buckets[bNum]:
        buckets[bNum].each do |item|
            f.write(item)
        end
        f.close
    end
end

# example of how to use this code          
buckets("pimaSmall.txt", 'pimaSmall',',',8)

