package app

import kotlin.system.measureNanoTime

class RegexMeasured (val tag: String, val regex: String) {
    companion object {
        const val T_INIT = "+const"
        const val T_REPLACE = "+replace"
        const val T_FIND = "+find"
        const val T_CONTAINS = "+containsMatchIn"

    }

    var regexObj: Regex? = null

    init {
        val time = measureNanoTime { regexObj = Regex(regex) }
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

    fun containsMatchIn(input: CharSequence): Boolean {
        var res: Boolean? = null
        val time = measureNanoTime {
            res = regexObj!!.containsMatchIn(input)
        }
        Measurements.addMeasurement(tag + T_CONTAINS, time)
        return res!!
    }
}
