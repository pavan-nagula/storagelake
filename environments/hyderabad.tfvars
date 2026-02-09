# ---------------------------------------------------------------------------------------------
# General variables
# ---------------------------------------------------------------------------------------------

environment  = "qa"
business     = "hyd-datalake"
project_name = "compute"
name         = "hyd-datalake"

# ---------------------------------------------------------------------------------------------
# Application account specific variables
# ---------------------------------------------------------------------------------------------
application_account_id = "333333333333"
application_vpc_cidrs  = ["10.42.224.0/19", "100.64.0.0/16"]
# ---------------------------------------------------------------------------------------------
# S3 bucket specific variables
# ---------------------------------------------------------------------------------------------

application_source_roles_with_s3_access = [
  "compute-hyderabad-qa-cap-firehose-role",        #CAP Firehose role
  "compute-hyderabad-qa-umbapps-firehose-role",    #PUB Firehose role
  "qa-datalake-hyderabad-ogg-ec2-role-ap-south-1" #EC2 GoldenGate role
]

enable_s3_tables = true

# ---------------------------------------------------------------------------------------------
# VPC Configuration
# ---------------------------------------------------------------------------------------------

vpc_us_east_1 = {
  ### Module Controls
  create_vpc                       = true
  create_internet_gateway          = true
  create_nat_gateway               = true
  create_vpc_endpoints             = true
  create_egress_network_firewall   = false
  create_eks_control_plane_subnets = false
  create_vpc_lattice               = false

  ### Basic VPC Configuration
  vpc_type               = "base"
  ipam_pool_name         = "internal-pool-non-routable"
  ipv4_netmask_length    = 20
  nat_gateway_deployment = "one_per_az"
  vpc_endpoints          = ["s3", "ec2", "rds", "cloudtrail", "logs", "sns", "ssm", "ec2messages", "kms", "ssmmessages"]

  base_subnet_cidrs = {
    public       = { "newbits" = 4, "netnum" = 0 }
    private      = { "newbits" = 4, "netnum" = 3 }
    aws_services = { "newbits" = 4, "netnum" = 6 }
  }

  ### Availability Zones
  availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

  ### Optional configurations
  enable_flow_logs         = false
  flow_logs_retention_days = 30

  ### Transit Gateway Configuration
  attach_to_transit_gateway                 = true
  transit_gateway_route_table_to_attach     = "nonprod_vpc"
  transit_gateway_route_tables_to_propagate = ["regional", "shared_services", "internal", "ods", "nonprod_firewall"]
  tgw_subnet_names                          = ["private", "aws_services"]
  tgw_destination_cidrs                     = ["10.0.0.0/8", "172.16.0.0/12"]

  ### Private Hosted Zone Configuration
  connect_to_phz = false
}

# ---------------------------------------------------------------------------------------------
# VPC Flow Logs IAM Configuration
# ---------------------------------------------------------------------------------------------

vpc_flow_logs_iam = {
  create_role           = true
  create_policy         = true
  trusted_role_services = ["vpc-flow-logs.amazonaws.com"]
}

# ---------------------------------------------------------------------------------------------
# RDS Aurora Serverless PostgreSQL Configuration
# ---------------------------------------------------------------------------------------------
aurora_serverless_cluster = {
  create               = true
  database_name        = "streaming"
  name                 = "streaming"
  engine_version       = "17.5"
  enable_http_endpoint = true
  instances = {
    1 = {}
  }
  serverlessv2_scaling_configuration = {
    min_capacity = 0.5
    max_capacity = 64
  }
}

# ------------------------------------------------------------------------------------
# Bastion Host Configuration
# ------------------------------------------------------------------------------------
bastion_host_config = {
  deploy_bastion = true
  instance_type  = "t3.medium"
  name           = "bastion-host"
}

# ---------------------------------------------------------------------------------------------
# Glue Jobs Configuration
# ---------------------------------------------------------------------------------------------

glue_jobs = {
  "initial-load-ingestion" = {
    enabled           = true
    job_name          = "initial-load-ingestion"
    script_local_path = "../jobs/batch/compute-hyd-initial-load-ingestion-qa.py"
    job_description   = "Initial Load Ingestion Job for Datalake"
    glue_version      = "5.0"

    default_arguments = {
      "--enable-glue-datacatalog" = "true"
      "--S3_TABLES_CATALOG"       = "s3tablescatalog/compute-hyd-datalake-staging-qa"
      "--job-bookmark-option"     = "job-bookmark-disable"
      "--TABLES_TO_PROCESS"       = "cap_main_journal_entry_type"
      "--TempDir"                 = "s3://aws-glue-assets-111111111111-ap-south-1/temporary/"
      "--extra-jars"              = "s3://aws-glue-assets-111111111111-ap-south-1/jars/s3-tables-catalog-for-iceberg-runtime-0.1.8.jar"
      "--SOURCE_S3_PATH"          = "s3://compute-hyd-datalake-qa-raw-ap-south-1/full_load/CAP/"
      "--enable-metrics"          = "true"
      "--spark-event-logs-path"   = "s3://aws-glue-assets-111111111111-ap-south-1/sparkHistoryLogs/"
      "--enable-job-insights"     = "false"
      "--TARGET_DATABASE"         = "staging_qa"
      "--conf"                    = "spark.rpc.message.maxSize=2g"
      "--job-language"            = "python"
      "--enable-auto-scaling"     = "true"
    }

    timeout           = 480
    max_retries       = 0
    worker_type       = "G.1X"
    number_of_workers = 4

    command = {
      name            = "glueetl"
      script_location = "s3://aws-glue-assets-111111111111-ap-south-1/scripts/compute-hyd-initial-load-ingestion-qa.py"
      python_version  = "3"
    }

    execution_property = {
      max_concurrent_runs = 1
    }
  }
  "tap-history-streaming" = {
    enabled           = true
    job_name          = "tap-history-streaming"
    script_local_path = "../jobs/streaming/compute-hyd-tap-history-streaming-qa.py"
    job_description   = ""
    glue_version      = "5.0"

    default_arguments = {
      "--enable-glue-datacatalog"      = "true"
      "--KINESIS_ROLE_ARN"             = "arn:aws:iam::333333333333:role/compute-service-role/datalake-hardened-ogg-ec2-role-ap-south-1"
      "--WINDOW_SIZE"                  = "20"
      "--job-bookmark-option"          = "job-bookmark-disable"
      "--NAMESPACE"                    = "staging_qa"
      "--TempDir"                      = "s3://aws-glue-assets-111111111111-ap-south-1/temporary/"
      "--extra-jars"                   = "s3://aws-glue-assets-111111111111-ap-south-1/jars/s3-tables-catalog-for-iceberg-runtime-0.1.8.jar"
      "--DYNAMODB_REGION"              = "ap-south-1"
      "--enable-metrics"               = "true"
      "--DYNAMODB_TABLE_NAME"          = "compute-hyd-datalake-qa-dl-tap-history-table"
      "--spark-event-logs-path"        = "s3://aws-glue-assets-111111111111-ap-south-1/sparkHistoryLogs/"
      "--enable-job-insights"          = "false"
      "--enable-observability-metrics" = "false"
      "--conf"                         = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.warehouse=s3://compute-hyderabad-qa-staging-s3/ --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.defaultCatalog=glue_catalog --conf spark.sql.adaptive.enabled=true --conf spark.sql.adaptive.coalescePartitions.enabled=true --conf spark.sql.adaptive.skewJoin.enabled=true --conf spark.sql.adaptive.localShuffleReader.enabled=true"
      "--CHECKPOINT_LOCATION"          = "s3://aws-glue-assets-111111111111-ap-south-1/streaming/tap_dev/checkpoints"
      "--job-language"                 = "python"
      "--enable-auto-scaling"          = "true"
      "--KINESIS_STREAM_ARN"           = "arn:aws:kinesis:ap-south-1:333333333333:stream/hyd-qa-cap-to-hyd-datalake"
    }

    timeout           = 480
    max_retries       = 0
    worker_type       = "G.1X"
    number_of_workers = 4

    command = {
      name            = "gluestreaming"
      script_location = "s3://aws-glue-assets-111111111111-ap-south-1/scripts/compute-hyd-tap-history-streaming-qa.py"
      python_version  = "3"
    }

    execution_property = {
      max_concurrent_runs = 1
    }
  }
  "balance-history-streaming" = {
    enabled           = true
    job_name          = "balance-history-streaming"
    script_local_path = "../jobs/streaming/compute-hyd-balance-history-streaming.py"
    job_description   = ""
    glue_version      = "5.0"

    default_arguments = {
      "--enable-glue-datacatalog"      = "true"
      "--KINESIS_ROLE_ARN"             = "arn:aws:iam::333333333333:role/compute-service-role/datalake-hardened-ogg-ec2-role-ap-south-1"
      "--WINDOW_SIZE"                  = "20"
      "--job-bookmark-option"          = "job-bookmark-disable"
      "--NAMESPACE"                    = "staging_qa"
      "--TempDir"                      = "s3://aws-glue-assets-111111111111-ap-south-1/temporary/"
      "--extra-jars"                   = "s3://aws-glue-assets-111111111111-ap-south-1/jars/s3-tables-catalog-for-iceberg-runtime-0.1.8.jar"
      "--DYNAMODB_REGION"              = "ap-south-1"
      "--enable-metrics"               = "true"
      "--DYNAMODB_TABLE_NAME"          = "compute-hyd-datalake-qa-dl-balance-history-table"
      "--spark-event-logs-path"        = "s3://aws-glue-assets-111111111111-ap-south-1/sparkHistoryLogs/"
      "--enable-job-insights"          = "false"
      "--enable-observability-metrics" = "false"
      "--conf"                         = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.warehouse=s3://compute-hyderabad-qa-staging-s3/ --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.defaultCatalog=glue_catalog --conf spark.sql.adaptive.enabled=true --conf spark.sql.adaptive.coalescePartitions.enabled=true --conf spark.sql.adaptive.skewJoin.enabled=true --conf spark.sql.adaptive.localShuffleReader.enabled=true"
      "--CHECKPOINT_LOCATION"          = "s3://aws-glue-assets-111111111111-ap-south-1/streaming/job1/checkpoints"
      "--job-language"                 = "python"
      "--enable-auto-scaling"          = "true"
      "--KINESIS_STREAM_ARN"           = "arn:aws:kinesis:ap-south-1:333333333333:stream/hyd-qa-cap-to-hyd-datalake"
    }

    timeout           = 480
    max_retries       = 0
    worker_type       = "G.1X"
    number_of_workers = 4

    command = {
      name            = "gluestreaming"
      script_location = "s3://aws-glue-assets-111111111111-ap-south-1/scripts/compute-hyd-balance-history-streaming-qa.py"
      python_version  = "3"
    }

    execution_property = {
      max_concurrent_runs = 1
    }
  }
  "cdc-streaming" = {
    enabled           = true
    job_name          = "cdc-streaming"
    script_local_path = "../jobs/streaming/compute-hyd-cdc-streaming.py"
    job_description   = ""
    glue_version      = "5.0"

    default_arguments = {
      "--ENV"                          = "qa"
      "--enable-glue-datacatalog"      = "true"
      "--KINESIS_ROLE_ARN"             = "arn:aws:iam::333333333333:role/compute-service-role/datalake-hardened-ogg-ec2-role-ap-south-1"
      "--WINDOW_SIZE"                  = "20"
      "--job-bookmark-option"          = "job-bookmark-disable"
      "--NAMESPACE"                    = "staging_qa"
      "--TempDir"                      = "s3://aws-glue-assets-111111111111-ap-south-1/temporary/"
      "--extra-jars"                   = "s3://aws-glue-assets-111111111111-ap-south-1/jars/s3-tables-catalog-for-iceberg-runtime-0.1.8.jar"
      "--DYNAMODB_REGION"              = "ap-south-1"
      "--enable-metrics"               = "true"
      "--DYNAMODB_TABLE_NAME"          = "compute-hyd-trip-api-backend"
      "--spark-event-logs-path"        = "s3://aws-glue-assets-111111111111-ap-south-1/sparkHistoryLogs/"
      "--enable-job-insights"          = "false"
      "--enable-observability-metrics" = "false"
      "--conf"                         = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.warehouse=s3://compute-hyderabad-qa-staging-s3/ --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.defaultCatalog=glue_catalog --conf spark.sql.adaptive.enabled=true --conf spark.sql.adaptive.coalescePartitions.enabled=true --conf spark.sql.adaptive.skewJoin.enabled=true --conf spark.sql.adaptive.localShuffleReader.enabled=true"
      "--CHECKPOINT_LOCATION"          = "s3://aws-glue-assets-111111111111-ap-south-1/streaming/job1/checkpoints"
      "--job-language"                 = "python"
      "--enable-auto-scaling"          = "true"
      "--KINESIS_STREAM_ARN"           = "arn:aws:kinesis:ap-south-1:333333333333:stream/hyd-qa-cap-to-hyd-datalake"
    }

    timeout           = 480
    max_retries       = 0
    worker_type       = "G.1X"
    number_of_workers = 4

    command = {
      name            = "gluestreaming"
      script_location = "s3://aws-glue-assets-111111111111-ap-south-1/scripts/compute-hyd-cdc-streaming-qa.py"
      python_version  = "3"
    }

    execution_property = {
      max_concurrent_runs = 1
    }
  }
  "compress-json-to-gzip" = {
    enabled           = true
    job_name          = "compress-json-to-gzip"
    script_local_path = "../jobs/batch/compute_ny_compress_json_to_gzip.py"
    job_description   = ""
    glue_version      = "5.0"

    default_arguments = {
      "--enable-metrics"               = "true"
      "--enable-spark-ui"              = "true"
      "--spark-event-logs-path"        = "s3://aws-glue-assets-111111111111-ap-south-1/sparkHistoryLogs/"
      "--enable-job-insights"          = "true"
      "--SOURCE_PREFIX"                = "s3://compute-hyd-datalake-raw-qa/full_load/CAP/cap_MAIN/JOURNAL_ENTRY_TYPE/"
      "--enable-observability-metrics" = "true"
      "--enable-glue-datacatalog"      = "true"
      "--job-bookmark-option"          = "job-bookmark-disable"
      "--job-language"                 = "python"
      "--TempDir"                      = "s3://aws-glue-assets-111111111111-ap-south-1/temporary/"
      "--JOB_NAME"                     = "compute-hyd-compress-json-to-gzip"
    }

    timeout           = 480
    max_retries       = 0
    worker_type       = "G.1X"
    number_of_workers = 2

    command = {
      name            = "glueetl"
      script_location = "s3://aws-glue-assets-111111111111-ap-south-1/scripts/compute-hyd-compress-json-to-gzip.py"
      python_version  = "3"
    }

    execution_property = {
      max_concurrent_runs = 2
    }
  }
  "hardcoded-dimension-tables" = {
    enabled           = true
    job_name          = "hardcoded-dimension-tables"
    script_local_path = "../jobs/batch/compute-hyd-hardcoded-dimension-tables.py"
    job_description   = ""
    glue_version      = "5.0"

    default_arguments = {
      "--SQL_BUCKET"                   = "aws-glue-assets-111111111111-ap-south-1"
      "--DATABASE"                     = "staging_qa"
      "--enable-glue-datacatalog"      = "true"
      "--job-bookmark-option"          = "job-bookmark-disable"
      "--MODE"                         = "s3"
      "--TempDir"                      = "s3://aws-glue-assets-111111111111-ap-south-1/temporary/"
      "--OUTPUT"                       = "s3://aws-glue-assets-111111111111-ap-south-1/athena-results/"
      "--enable-metrics"               = "true"
      "--enable-spark-ui"              = "true"
      "--spark-event-logs-path"        = "s3://aws-glue-assets-111111111111-ap-south-1/sparkHistoryLogs/"
      "--RUN_ALL"                      = "true"
      "--enable-job-insights"          = "true"
      "--enable-observability-metrics" = "true"
      "--SQL_PREFIX"                   = "sql/"
      "--SQL_FILES"                    = "test_table1.sql"
      "--job-language"                 = "python"
      "--CATALOG"                      = "s3tablescatalog/compute-hyd-datalake-staging-qa"
      "--JOB_NAME"                     = "compute-hyd-hardcoded-dimension-tables"
    }

    timeout           = 480
    max_retries       = 0
    worker_type       = "G.1X"
    number_of_workers = 2

    command = {
      name            = "glueetl"
      script_location = "s3://aws-glue-assets-111111111111-ap-south-1/scripts/compute-hyd-hardcoded-dimension-tables.py"
      python_version  = "3"
    }

    execution_property = {
      max_concurrent_runs = 1
    }
  }
  "verify-if-there-is-data-in-s3table" = {
    enabled           = true
    job_name          = "verify-if-there-is-data-in-s3table"
    script_local_path = "../jobs/batch/compute_ny_verify_if_there_is_data_in_s3table.py"
    job_description   = ""
    glue_version      = "5.0"

    default_arguments = {
      "--OUTPUT"                       = "s3://aws-glue-assets-111111111111-ap-south-1/athena-results/"
      "--enable-metrics"               = "true"
      "--enable-spark-ui"              = "true"
      "--spark-event-logs-path"        = "s3://aws-glue-assets-111111111111-ap-south-1/sparkHistoryLogs/"
      "--enable-job-insights"          = "true"
      "--DATABASE"                     = "staging_qa"
      "--enable-observability-metrics" = "true"
      "--enable-glue-datacatalog"      = "true"
      "--job-bookmark-option"          = "job-bookmark-disable"
      "--job-language"                 = "python"
      "--TempDir"                      = "s3://aws-glue-assets-111111111111-ap-south-1/temporary/"
      "--CATALOG"                      = "s3tablescatalog/compute-hyd-datalake-staging-qa"
    }

    timeout           = 30
    max_retries       = 0
    worker_type       = "G.1X"
    number_of_workers = 2

    command = {
      name            = "glueetl"
      script_location = "s3://aws-glue-assets-111111111111-ap-south-1/scripts/compute-hyd-verify-if-there-is-data-in-s3table.py"
      python_version  = "3"
    }

    execution_property = {
      max_concurrent_runs = 1
    }
  }
}
