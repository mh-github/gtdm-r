#! /usr/bin/env ruby

require 'test/unit'
require "./nearestNeighborClassifier.rb"

class NearestNeighborClassifierUnitTest < Test::Unit::TestCase
    def test_unitTest
        classifier = Classifier.new('athletesTrainingSet.txt')
        br = ['Basketball', [72, 162], ['Brittainey Raven']]
        nl = ['Gymnastics', [61, 76], ['Viktoria Komova']]
        cl = ["Basketball", [74, 190], ['Crystal Langhorne']]
        # first check normalize function
        brNorm = classifier.normalizeVector(br[1])
        nlNorm = classifier.normalizeVector(nl[1])
        clNorm = classifier.normalizeVector(cl[1])
        assert(brNorm == classifier.data[1][1])
        assert(nlNorm == classifier.data[-1][1])
        puts
        print("normalizeVector fn OK\n")
        # check distance
        assert (classifier.manhattan(clNorm, classifier.data[1][1]).round(5) == 1.16823)
        assert(classifier.manhattan(brNorm, classifier.data[1][1]) == 0)
        assert(classifier.manhattan(nlNorm, classifier.data[-1][1]) == 0)
        print("Manhattan distance fn OK\n")
        # Brittainey Raven's nearest neighbor should be herself
        result = classifier.nearestNeighbor(brNorm)
        assert(result[1][2]== br[2])
        # Nastia Liukin's nearest neighbor should be herself
        result = classifier.nearestNeighbor(nlNorm)
        assert(result[1][2]== nl[2])
        # Crystal Langhorne's nearest neighbor is Jennifer Lacy"
        assert(classifier.nearestNeighbor(clNorm)[1][2][0] == "Jennifer Lacy")
        print("Nearest Neighbor fn OK\n")
        # Check if classify correctly identifies sports
        assert(classifier.classify(br[1]) == "Basketball")
        # assert(classifier.classify(cl[1]) == 'Basketball')
        # assert(classifier.classify(nl[1]) == 'Gymnastics')
        print("Classify fn OK\n")
    end
end