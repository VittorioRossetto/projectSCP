
# CoPurchaseAnalysis

This project implements a Co-Purchase Analysis using Apache Spark. It processes a dataset of product orders to calculate the number of times pairs of products appear together in the same order. The results can be used to identify product affinities and build recommendation systems.

## Features
- **Scala and Spark Integration**: Leverages Apache Spark for distributed data processing.
- **Local Testing**: Designed to run in local mode using `SparkSession`.
- **Flexible Data Input**: Allows for testing with in-memory datasets for quick iterations.

---

## Requirements

- **Java**: JDK 8, 11, or 17 (Java 8 is recommended for compatibility with Spark).
- **Scala**: 2.12.x (tested with 2.12.17).
- **Apache Spark**: 3.3.x (tested with 3.3.1).
- **SBT**: 1.8.x or later.
- **IntelliJ IDEA** (optional): For development and debugging.
- **Python** 3.12.x (optional): For dataset generation

---

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/VittorioRossetto/projectSCP
cd projectscp
```

### 2. Install Dependencies
Ensure SBT is installed. Then, fetch the dependencies:
```bash
sbt update
```

### 3. Configure Java
Ensure `JAVA_HOME` points to a compatible Java version (8, 11, or 17):
```bash
java -version
```

If you're using Java 17, add JVM options to `build.sbt` to avoid module issues:
```scala
javaOptions ++= Seq(
  "--add-exports", "java.base/sun.nio.ch=ALL-UNNAMED",
  "--add-opens", "java.base/sun.nio.ch=ALL-UNNAMED"
)
```
---
## Dataset Generation

To generate small and medium datasets from the original dataset, run the `generate_datasets.py` script. Ensure you have the original dataset file (`order_products.csv`) in the same directory as the script. You can download it here: [order_products.csv](https://liveunibo-my.sharepoint.com/:u:/g/personal/giuseppe_depalma2_unibo_it/EVi5ZjiIP_lCveGkwidpEMkBbS7s6cagNizxqMl95odubA?e=gNfxna).

### Steps to Generate Datasets

1. Install the required Python packages:
    ```bash
    pip install pandas
    ```

2. Run the dataset generation script:
    ```bash
    python generate_datasets.py
    ```

This will create two new files: `order_products_small.csv` and `order_products_medium.csv` with 10,000 and 100,000 rows respectively.

---

## How to Run

---
Please note: only CoPurchaseAnalysisLocal.scala is meant to be ran locally. to run the other ones you'll have to use Dataproc.

---

### Run Locally with SBT
To execute the program in local mode:
```bash
sbt run
```
### Running on IntelliJ IDEA

#### Import the Project:
1. Open IntelliJ IDEA.
2. Select `File > New > Project from Existing Sources`.
3. Choose the folder containing the project and select `Import from SBT`.

#### Ensure Dependencies Are Loaded:
IntelliJ will automatically download dependencies. If not, go to the SBT tab (on the right sidebar) and click the `Reload All Projects` button.

#### Add Spark Configuration:
1. Go to `Run > Edit Configurations`.
2. Click the `+` icon and select `Application`.
3. Set the following fields:
    - **Main class**: `Main` You can only chose `CoPurchaseAnalysisLocal.scala` to run locally
    - **Program arguments**: Leave empty.
    - **VM options**: Add the following if using Java 17:
      ```text
      --add-exports java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED
      ```

#### Run the Project:
Click the `Run` button or use `Shift + F10`.

#### Debugging:
Set breakpoints in the code. Start the program in Debug mode (`Shift + F9`).

### Using Google Cloud Dataproc
If you wanna use preexisting bucket, you can assign values the following way:
```bash
REGION="europe-west8"
CLUSTER_NAME="cpacluster"
JAR_PATHS=("gs://copurchasebucket/copurchaseanalysis_v1.0.jar" "gs://copurchasebucket/copurchaseanalysis_v1_1.jar" "gs://copurchasebucket/copurchaseanalysis_v1_2.jar") # Either one 
INPUT_FILES=("gs://copurchasebucket/order_products_small.csv" "gs://copurchasebucket/order_products_medium.csv" "gs://copurchasebucket/order_products.csv") #Either one
OUTPUT_BUCKET="gs://copurchasebucket"
RESULT_FILE="test_results.csv"
```


#### Prerequisites
- A Google Cloud Platform (GCP) account.
- Install the gcloud CLI and authenticate:
  ```bash
  gcloud auth login
  ```

#### 1. Create a Dataproc Cluster
```bash
gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --num-workers=2 \
    --master-boot-disk-size=200 \
    --worker-boot-disk-size=100 \
    --worker-machine-type=n2-standard-2 \
    --master-machine-type=n2-standard-2
```

#### 2. Upload the JAR and Dataset to Cloud Storage
Package your project into a JAR:
```bash
sbt package
```
The JAR will be located in `target/scala-2.12/`.

Upload the JAR and dataset to a GCS bucket:
```bash
gsutil cp target/scala-2.12/<copurchase-analysis RDD version>.jar gs://$OUTPUT_BUCKET/
gsutil cp target/scala-2.12/<copurchase-analysis dataframe version>.jar gs://$OUTPUT_BUCKET/
gsutil cp target/scala-2.12/<copurchase-analysis RDD reduce version>.jar gs://$OUTPUT_BUCKET/
gsutil cp order_products.csv gs://$OUTPUT_BUCKET/
gsutil cp order_products_small.csv gs://$OUTPUT_BUCKET/
gsutil cp order_products_medium.csv gs://$OUTPUT_BUCKET/
```

#### 3. Submit the Spark Job
Run the Spark job on the Dataproc cluster:
```bash
gcloud dataproc jobs submit spark \
                --cluster=$CLUSTER_NAME \
                --region=$REGION \
                --jar=$jar_path \
                -- "$input_file" "$output_path"
```

#### 4. Retrieve Results
Download the results from the GCS bucket:
```bash
gsutil cp gs://$OUTPUT_BUCKET/output/* ./output/
```

#### 5. Delete the Cluster (Optional)
Delete the cluster to avoid unnecessary charges:
```bash
gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION --quiet
```
### Using `test_dataproc.sh`

You can also use the provided `test_dataproc.sh` script to automate the process of running the Spark job on Google Cloud Dataproc.

#### 1. Make the Script Executable
```bash
chmod +x test_dataproc.sh
```

#### 2. Run the Script
```bash
./test_dataproc.sh
```

This script will handle creating the Dataproc cluster,  submitting the job, and retrieving the results. Ensure you have configured the script with your specific paths. Otherwise use the default ones. Results of the tests will be written in test_results.csv.

---

## Example Output
Given the dataset:
```text
1,12
1,14
2,8
2,12
2,14
3,8
3,12
3,14
3,16
```
The program will output:
```text
8,12,2
8,14,2
8,16,1
12,14,3
12,16,1
14,16,1
```

---

## Troubleshooting

### Missing `winutils.exe` (Windows)
Download `winutils.exe` from [Winutils GitHub](https://github.com/steveloughran/winutils) and set `HADOOP_HOME`:
```bash
set HADOOP_HOME=C:\path\to\winutils
```

---

## Contributors
- [Vittorio Rossetto](https://github.com/VittorioRossetto)



