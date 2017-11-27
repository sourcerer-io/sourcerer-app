// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.extractors

import app.ModelsProtos
import com.google.protobuf.InvalidProtocolBufferException
import java.security.InvalidParameterException

class Classifier {
    var tokens: List<String>
    var libraries: List<String>
    var idf: Map<String, Float>
    var weights: Map<String, Map<String, Float>>
    var biases: Map<String, Float>

    @Throws(InvalidParameterException::class)
    constructor(proto: ModelsProtos.Classifier) {
        tokens = proto.tokensList
        libraries = proto.librariesList
        idf = tokens.zip(proto.idfList).toMap()
        weights = libraries.zip(proto.weightsList.partition(tokens.size)
            .map {it: List<Float> -> tokens.zip(it).toMap()}).toMap()
        biases = libraries.zip(proto.biasesList).toMap()
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(ModelsProtos.Classifier
        .parseFrom(bytes))

    fun evaluate(input: List<String>): List<Double> {
        val inputTokens = input.filter { it in tokens}
        val tokensWithWeight = inputTokens.groupBy { it }
            .map { (token, tokens) -> Pair(token, tokens.size * idf[token]!!) }
            .toMap()
        val norm = Math.sqrt(tokensWithWeight
            .map { (_, tfidf) -> tfidf * tfidf }
            .sum() + 1e-7)
        val output = libraries.map {
            Math.exp(tokensWithWeight
                .map { (token, tfidf) -> tfidf / norm * weights[it]!![token]!! }
                .sum() + biases[it]!!)
        }
        val norm2 = output.sum()
        val probs = output.map { it / norm2 }

        return probs
    }

    fun getCategories(): List<String> {
        return libraries
    }

    private fun <T> List<T>.partition(size: Int): List<List<T>> {
        return this.withIndex()
            .groupBy { it.index / size }
            .map { group -> group.value.map { it.value } }
    }
}
