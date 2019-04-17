package app

object Measurements {
    private val measureMap: MutableMap<Int, Long> = mutableMapOf()

    fun addMeasurement(code: Int, value: Long) {
        if (!measureMap.containsKey(code)) {
            measureMap[code] = 0
        }
        measureMap[code] = measureMap[code]!! + value
    }

    fun showMeasurements(codeDescs: Map<Int, String>) {
        codeDescs.forEach { code, name ->
            Logger.info { "$code $name -> ${measureMap[code]}"}
        }
    }
}
