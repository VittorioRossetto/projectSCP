import org.apache.spark.rdd.RDD
import org.apache.spark.sql.SparkSession

import java.io.PrintWriter

object CoPurchaseAnalysisLocal {
  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder()
      .appName("CoPurchaseAnalysis")
      .master("local[*]") // Use all available cores
      .config("spark.driver.memory", "4g") // Increase driver memory
      .config("spark.executor.memory", "4g") // Increase executor memory
      .config("spark.executor.heartbeatInterval", "2000ms") // Avoid timeouts
      .config("spark.network.timeout", "600s") // Increase network timeout
      .getOrCreate()

    val writer = new PrintWriter("test.csv")

    val rawRDD: RDD[(Int, Int)] = readCSV(spark, "testIn.csv")

    // Process the data
    val coPurchaseCounts = processCoPurchases(rawRDD)

    // Collect the results to the driver and write to the file
    coPurchaseCounts.collect().foreach {
      case ((product1, product2), count) =>
        writer.println(s"$product1,$product2,$count") // Format as CSV without parentheses
    }

    writer.close()

    spark.stop()
  }

  private def readCSV(spark: SparkSession, filePath: String): RDD[(Int, Int)] = {
    // Read the file as an RDD of strings (each line is a string)
    val lines = spark.sparkContext.textFile(filePath)

    // Parse each line to extract the two integer values (orderId and productId)
    lines.map { line =>
      val parts = line.split(",") // Split by comma or other delimiter
      (parts(0).trim.toInt, parts(1).trim.toInt) // Convert to tuple of integers
    }
  }

  private def processCoPurchases(data: RDD[(Int, Int)]): RDD[((Int, Int), Int)] = {
    // Step 1: Group products by order ID
    val groupedProducts = data.groupByKey()

    // Step 2: Generate product pairs within each order
    val productPairs = groupedProducts.flatMap {
      case (_, products) =>
        val productList = products.toSet
        for {
          x <- productList
          y <- productList if x < y
        } yield ((x, y), 1)
    }

    // Step 3: Count occurrences of each product pair
    productPairs.reduceByKey(_ + _)
  }
}
