package BasedProcessFunctions

import org.apache.flink.api.common.state.ValueState
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.functions.co.KeyedCoProcessFunction
import org.apache.flink.util.Collector

/**
  * @since 2020/03/15
  *        A based class extends [[KeyedCoProcessFunction]] in Flink.  On the top of [[KeyedCoProcessFunction]], the
  *        new based class implements a simple sliding-window control function and timing schema.  As AJU only allows
  *        one type of input stream, the [[KeyedCoProcessFunction]] only need to use one [[process()]] function to
  *        process two streams.
  * @tparam K type of the key.
  * @tparam I type of the input streams.
  * @tparam O type of the output streams.
  * @param windowLength @suspend the length of a sliding window.
  * @param slidingSize  @suspend the time gap between two enumerations.
  * @param name         the relation name that the CoProcessFunction will deal with.
  * @param testMemory   @suspend whether to perform GC before output the memory data.  Default is set as ``false``
  */
abstract class BasedCoProcessFunction[K, I, O](windowLength: Long,
                                               slidingSize: Long,
                                               name: String,
                                               testMemory: Boolean = false) extends KeyedCoProcessFunction[K, I, I, O] {
  /**
    * @deprecated
    */
  val Tor = 1e-6
  /**
    * Used for more informative output.
    */
  val prefix = "Co Process Function"
  /**
    * The create time of the [[KeyedCoProcessFunction]].
    */
  var startTime: Long = 2528951114776L
  /**
    * The total process time of the [[KeyedCoProcessFunction]].
    */
  var duration: Long = 0L
  /**
    * A value state to store the current maximum timestamp.
    */
  var CurrentMaximumTimeStamp: ValueState[Long] = _
  /**
    * A value state to store the latest expire timestamp.
    */
  var LatestExpireEle: ValueState[Long] = _
  /**
    * The next output timestamp.
    */
  var NextOutput: ValueState[Long] = _
  /**
    * @deprecated
    */
  var CurrentOutput: Long = _
  /**
    * The total process time of enumeration.
    */
  var OutputAccur: Long = 0L
  /**
    * The total process time to store the stream into current process function state.
    */
  var StoreAccur: Long = 0L
  /**
    * @deprecated
    */
  var LatestExpired: Long = 0L
  /**
    * @deprecated
    */
  var count = 0

  /**
    * A function to initial the state as Flink required.
    */
  def initstate(): Unit

  /**
    * @deprecated
    * A function to enumerate the current join result.
    * @param out the output collector.
    */
  def enumeration(out: Collector[O]): Unit

  /**
    * A function to deal with expired elements.
    *
    * @param ctx the current keyed context
    */
  def expire(ctx: KeyedCoProcessFunction[K, I, I, O]#Context): Unit

  /**
    * A function to process new input element.
    *
    * @param value_raw the raw value of current insert element
    * @param ctx       the current keyed context
    * @param out       the output collector, to collect the output stream.
    */
  def process(value_raw: I, ctx: KeyedCoProcessFunction[K, I, I, O]#Context, out: Collector[O]): Unit

  /**
    * @deprecated
    * A function to store the elements in current time window into the state, for expired.
    * @param value the raw value of current insert element
    * @param ctx   the current keyed context
    */
  def storeStream(value: I, ctx: KeyedCoProcessFunction[K, I, I, O]#Context): Unit

  /**
    * @deprecated
    * A function to test whether the new element is already processed or the new element is legal for process.
    * @param value the raw value of current insert element
    * @param ctx   the current keyed context
    * @return a boolean value whether the new element need to be processed.
    */
  def testExists(value: I, ctx: KeyedCoProcessFunction[K, I, I, O]#Context): Boolean

  override def open(parameters: Configuration): Unit = {
    initstate()

    /**
      * if the [[testMemory]] is set to be true, then perform GC and output the memory usage before receive the first
      * element.
      */
    if (testMemory) {
      Runtime.getRuntime.runFinalization()
      Runtime.getRuntime.gc()
      Thread.sleep(30000)
      System.out.println(s"Process Function $name : Memory usage ${(Runtime.getRuntime.totalMemory() - Runtime.getRuntime.freeMemory()) / (1024 * 1024)}, EnumerationTime $OutputAccur, StorageTime $StoreAccur")
    }

  }

  //  def debug(value : I, ctx : KeyedCoProcessFunction[K,I,I,O]#Context) : Unit = {}

  override def processElement1(value: I, ctx: KeyedCoProcessFunction[K, I, I, O]#Context, out: Collector[O]): Unit = {
    val s = System.currentTimeMillis()
    if (startTime > System.currentTimeMillis()) startTime = System.currentTimeMillis()

    processBuffer(value, ctx, out)
    process(value, ctx, out)
    duration += System.currentTimeMillis() - s

  }

  /**
    * A function to process the buffer elements.  Aims to deal with out-of-ordered element.
    * Default set to empty.
    *
    * @param value the raw value of current insert element
    * @param ctx   the current keyed context
    * @param out   the output collector, to collect the output stream.
    */
  def processBuffer(value: I, ctx: KeyedCoProcessFunction[K, I, I, O]#Context, out: Collector[O]): Unit = {}

  override def processElement2(value: I, ctx: KeyedCoProcessFunction[K, I, I, O]#Context, out: Collector[O]): Unit = {
    val s = System.currentTimeMillis()
    if (startTime > System.currentTimeMillis()) startTime = System.currentTimeMillis()

    processBuffer(value, ctx, out)
    process(value, ctx, out)
    duration += System.currentTimeMillis() - s
  }

  override def close(): Unit = {
    val endTime = System.currentTimeMillis()
    println(s"$prefix $name Parallelism ${getRuntimeContext.getIndexOfThisSubtask} StartTime $startTime EndTime $endTime Difference ${endTime - startTime} AccumulateTime $duration EnumerationTime $OutputAccur, StorageTime $StoreAccur")
  }
}
