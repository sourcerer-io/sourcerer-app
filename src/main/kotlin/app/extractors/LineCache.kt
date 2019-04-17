package app.extractors

class CachingTokenizer {
    val cache = hashMapOf<String, List<String>>()

    fun tokenize(line: String, extractor: ExtractorInterface):
            List<String> {
        if (cache.containsKey(line)) {
            return cache[line]!!
        }
        cache[line] = extractor.tokenize(line)
        return cache[line]!!
    }
}