// Copyright 2017 Sourcerer Inc. All Rights Reserved.
// Author: Alexander Surkov (alex@sourcerer.io)

package app.utils

import kotlin.system.*

object Metrics {
    override fun toString(): String {
      var str: String = ""

      var total: Long = 0
      for ((_, item) in timing.items) {
        total += item.time
      }

      str += timing.toStringHelper(total)

      for ((tag, value) in numerical) {
        str += "$tag: $value\n"
      }

      return str
    }

    fun <T> recordTime(tag: String, block: () -> T) : T {
      val parentItem = timingStack.get(timingStack.lastIndex)
      var item = parentItem.items.getOrPut(tag, { TimingData() })

      timingStack.add(item)

      val start = System.currentTimeMillis()
      val result = block()
      item.time += System.currentTimeMillis() - start

      timingStack.subList(timingStack.lastIndex, timingStack.lastIndex + 1).clear()

      return result
    }

    fun recordMetric(tag: String, metric: Long)
    {
        var v = numerical.getOrDefault(tag, 0)
        numerical.put(tag, v + metric);
    }

    class TimingData {
        var time: Long = 0
        var items = mutableMapOf<String, TimingData>()

        fun toStringHelper(total: Long, offset: String = ""): String {
          var str = ""
          for ((tag, item) in items) {
            str += "$offset$tag: ${item.time} ms, ${item.time * 100 / total}%\n"
            str += item.toStringHelper(total, "$offset  ")
          }
          return str
        }
    }

    private val timing = TimingData()
    private val timingStack = mutableListOf<TimingData>(timing)
    private var nestedTiming: Boolean = true

    private val numerical = mutableMapOf<String, Long>()
}

/**
 * Records a block's execution time in milliseconds and assigns it a tag in
 * calls hierarchy.
 */
fun <T> recordTime(tag: String, block: () -> T) : T {
    return Metrics.recordTime(tag, block)
}

/**
 * Records a numeric metric of given tag.
 */
fun recordMetric(tag: String, metric: Long)
{
    return Metrics.recordMetric(tag, metric)
}
