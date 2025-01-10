import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

object CoPurchaseAnalysisDF {
  def main(args: Array[String]): Unit = {
    // Check if the required arguments (input and output paths) are provided
    if (args.length < 2) {
      System.err.println("Usage: CoPurchaseAnalysis <input-path> <output-path>")
      System.exit(1)
    }

    // Assign the first and second command-line arguments to inputPath and outputPath
    val inputPath = args(0)
    val outputPath = args(1)

    // Create a SparkSession to enable working with DataFrames
    val spark = SparkSession.builder()
      .appName("CoPurchaseAnalysis") // Set the application name
      .getOrCreate()

    // Read a CSV file from the input path into a DataFrame
    val rawDF = spark.read
      .option("header", "false") // Indicate that the CSV file has no header
      .option("inferSchema", "true") // Automatically infer the schema of the data
      .csv(inputPath) // Load the CSV file from the specified input path
      .toDF("product1", "product2") // Rename the columns for clarity

    // Process co-purchase pairs to calculate their occurrence count
    val coPurchaseCounts = rawDF
      // Create a sorted pair of product1 and product2 to ensure consistent ordering
      .withColumn("pair", array_sort(array(col("product1"), col("product2"))))
      // Group by the sorted pairs and count occurrences
      .groupBy("pair")
      .count()
      // Split the pair back into two separate columns for the final output
      .selectExpr("pair[0] as product1", "pair[1] as product2", "count")

    // Write the resulting co-purchase counts to the specified output path in CSV format
    coPurchaseCounts.write
      .option("header", "true") // Add a header row to the output CSV
      .csv(outputPath)

    // Stop the SparkSession to release resources
    spark.stop()
  }
}
