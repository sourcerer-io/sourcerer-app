package app

import kotlin.system.measureNanoTime

operator fun CharSequence.contains(regex: RegexMeasured): Boolean = regex.containsMatchIn(this)
fun CharSequence.split(regex: RegexMeasured, limit: Int = 0): List<String> = regex.split(this, limit)

class RegexMeasured (val tag: String, val regex: String,
                     val options: Set<RegexOption>) {
    companion object {
        const val T_INIT = "+init"
        const val T_REPLACE = "+replace"
        const val T_FIND = "+find"
        const val T_CONTAINS = "+containsMatchIn"
        const val T_SPLIT = "+split"
    }

    constructor(tag: String, regex: String, option: RegexOption) :
        this(tag, regex, setOf(option))
    constructor(tag: String, regex: String) : this(tag, regex, setOf())

    var regexObj: Regex? = null

    init {
        val time = measureNanoTime {
            regexObj = Regex(regex, options)
        }
        Measurements.addMeasurement(tag + T_INIT, time)
    }

    fun replace(input: CharSequence, replacement: String): String {
        var res:String? = null
        val time = measureNanoTime {
            res = regexObj!!.replace(input, replacement)
        }
        Measurements.addMeasurement(tag + T_REPLACE, time)
        return res!!
    }

    fun find(input: CharSequence, startIndex: Int = 0): MatchResult? {
        var res: MatchResult? = null
        val time = measureNanoTime {
            res = regexObj!!.find(input, startIndex)
        }
        Measurements.addMeasurement(tag + T_FIND, time)
        return res!!
    }

    fun findAll(input: CharSequence, startIndex: Int = 0): Sequence<MatchResult> {
        var res: Sequence<MatchResult>? = null
        val time = measureNanoTime {
            res = regexObj!!.findAll(input, startIndex)
        }
        Measurements.addMeasurement(tag + T_FIND, time)
        return res!!
    }

    fun split(input: CharSequence, limit: Int = 0): List<String> {
        var res: List<String>? = null
        val time = measureNanoTime {
            res = regexObj!!.split(input, limit)
        }
        Measurements.addMeasurement(tag + T_SPLIT, time)
        return res!!
    }

    fun containsMatchIn(input: CharSequence): Boolean {
        var res: Boolean? = null
        val time = measureNanoTime {
            res = regexObj!!.containsMatchIn(input)
        }
        Measurements.addMeasurement(tag + T_CONTAINS, time)
        return res!!
    }
}
