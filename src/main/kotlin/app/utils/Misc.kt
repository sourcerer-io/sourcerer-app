// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Anatoly Kislov (anatoly@sourcerer.io)

package app.utils

// TODO(anatoly): Replace with chunked from new Kotlin version.
// SO #34498368 @ Jayson Minard.
fun <T> Sequence<T>.batch(n: Int): Sequence<List<T>> {
    return BatchingSequence(this, n)
}

class BatchingSequence<T>(val source: Sequence<T>,
                          val batchSize: Int) : Sequence<List<T>> {
    override fun iterator(): Iterator<List<T>> = object :
            AbstractIterator<List<T>>() {
        val iterate = if (batchSize > 0) source.iterator() else
            emptyList<T>().iterator()
        override fun computeNext() {
            if (iterate.hasNext()) setNext(iterate.asSequence()
                    .take(batchSize).toList())
            else done()
        }
    }
}
