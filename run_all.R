# run_all.R
# Master script to run the entire Airbnb price prediction pipeline

# This script runs all analysis steps in sequence:
# 1. Data generation
# 2. Data preprocessing
# 3. Exploratory analysis
# 4. Model training
# 5. Predictions and recommendations

cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║   AIRBNB LISTING PRICE ANALYSIS & PREDICTION PIPELINE     ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n\n")

# Record start time
start_time <- Sys.time()

# Set working directory to project root (if needed)
# setwd("path/to/airbnb-price-prediction")

# Check if required packages are installed
cat("Checking required packages...\n")
required_packages <- c("tidyverse", "ggplot2", "dplyr", "caret", "rpart", 
                      "rpart.plot", "corrplot", "scales", "gridExtra", "Metrics")

missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if(length(missing_packages) > 0) {
  cat("\nMissing packages detected. Installing...\n")
  source("requirements.R")
} else {
  cat("✓ All required packages are installed\n\n")
}

# Create directories if they don't exist
cat("Setting up project structure...\n")
dir.create("data", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)
dir.create("visualizations", showWarnings = FALSE)
cat("✓ Directories ready\n\n")

# ===== STEP 1: DATA GENERATION =====
cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("STEP 1/5: GENERATING SYNTHETIC AIRBNB DATA\n")
cat("═══════════════════════════════════════════════════════════\n")

tryCatch({
  source("scripts/01_data_generation.R")
  cat("\n✓ Step 1 completed successfully\n")
}, error = function(e) {
  cat("\n✗ Error in Step 1:", e$message, "\n")
  stop("Pipeline halted due to error")
})

Sys.sleep(2)  # Brief pause between steps

# ===== STEP 2: DATA PREPROCESSING =====
cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("STEP 2/5: DATA PREPROCESSING\n")
cat("═══════════════════════════════════════════════════════════\n")

tryCatch({
  source("scripts/02_data_preprocessing.R")
  cat("\n✓ Step 2 completed successfully\n")
}, error = function(e) {
  cat("\n✗ Error in Step 2:", e$message, "\n")
  stop("Pipeline halted due to error")
})

Sys.sleep(2)

# ===== STEP 3: EXPLORATORY ANALYSIS =====
cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("STEP 3/5: EXPLORATORY DATA ANALYSIS\n")
cat("═══════════════════════════════════════════════════════════\n")

tryCatch({
  source("scripts/03_exploratory_analysis.R")
  cat("\n✓ Step 3 completed successfully\n")
}, error = function(e) {
  cat("\n✗ Error in Step 3:", e$message, "\n")
  stop("Pipeline halted due to error")
})

Sys.sleep(2)

# ===== STEP 4: MODEL TRAINING =====
cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("STEP 4/5: MODEL TRAINING & EVALUATION\n")
cat("═══════════════════════════════════════════════════════════\n")

tryCatch({
  source("scripts/04_modeling.R")
  cat("\n✓ Step 4 completed successfully\n")
}, error = function(e) {
  cat("\n✗ Error in Step 4:", e$message, "\n")
  stop("Pipeline halted due to error")
})

Sys.sleep(2)

# ===== STEP 5: PREDICTIONS =====
cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("STEP 5/5: GENERATING PREDICTIONS & RECOMMENDATIONS\n")
cat("═══════════════════════════════════════════════════════════\n")

tryCatch({
  source("scripts/05_predictions.R")
  cat("\n✓ Step 5 completed successfully\n")
}, error = function(e) {
  cat("\n✗ Error in Step 5:", e$message, "\n")
  stop("Pipeline halted due to error")
})

# ===== FINAL SUMMARY =====
end_time <- Sys.time()
elapsed_time <- difftime(end_time, start_time, units = "mins")

cat("\n\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║                  PIPELINE COMPLETED! 🎉                    ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n\n")

cat("All steps completed successfully!\n")
cat(paste("Total execution time:", round(elapsed_time, 2), "minutes\n\n"))

cat("Generated Files:\n")
cat("═══════════════\n")
cat("\nData Files (data/):\n")
cat("  • airbnb_data.csv - Original synthetic data\n")
cat("  • airbnb_data_cleaned.csv - Preprocessed data\n")
cat("  • data_dictionary.txt - Variable descriptions\n")

cat("\nModel Files (outputs/):\n")
cat("  • linear_regression_model.rds - Trained LR model\n")
cat("  • decision_tree_model.rds - Trained DT model\n")
cat("  • feature_importance.csv - Feature rankings\n")
cat("  • predictions_sample.csv - Model predictions\n")
cat("  • new_listing_predictions.csv - New listing prices\n")

cat("\nReports (outputs/):\n")
cat("  • preprocessing_summary.txt\n")
cat("  • eda_insights_report.txt\n")
cat("  • model_performance_report.txt\n")
cat("  • pricing_recommendations_report.txt\n")

cat("\nVisualizations (visualizations/):\n")
viz_files <- list.files("visualizations", pattern = "\\.png$")
if(length(viz_files) > 0) {
  for(file in viz_files) {
    cat(paste("  •", file, "\n"))
  }
  cat(paste("\nTotal:", length(viz_files), "visualizations created\n"))
}

cat("\n" %s% rep("═", 60) %s% "\n")
cat("\nNext Steps:\n")
cat("  1. Review visualizations in visualizations/ directory\n")
cat("  2. Check model performance in outputs/model_performance_report.txt\n")
cat("  3. Review pricing insights in outputs/pricing_recommendations_report.txt\n")
cat("  4. Customize new_listings in 05_predictions.R for your own data\n")
cat("  5. Share your results or contribute improvements!\n\n")

cat("Thank you for using the Airbnb Price Prediction Pipeline!\n")
cat("For issues or questions, please refer to README.md\n\n")

# Helper function for string concatenation
`%s%` <- function(x, y) paste0(x, collapse = y)
