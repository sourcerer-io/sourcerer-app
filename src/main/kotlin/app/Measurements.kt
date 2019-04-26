package app

object Measurements {
    private val measureMap: HashMap<String, Long> = hashMapOf()

    fun addMeasurement(key: String, value: Long) {
        if (!measureMap.containsKey(key)) {
            measureMap[key] = 0
        }
        measureMap[key] = measureMap[key]!! + value
    }

    fun showAllMeasurements() {
        Logger.info { "Measurements:" }
        Logger.info { measureMap.keys.joinToString(" ") }
        measureMap.toList().sortedBy { it.second }.forEach {
            Logger.info { "${it.first} -> ${it.second}" }
        }
    }
}
