# Requirements.R
# Install required R packages for Airbnb Price Prediction Project

# List of required packages
required_packages <- c(
  "tidyverse",      # Data manipulation and visualization
  "ggplot2",        # Advanced plotting
  "dplyr",          # Data manipulation
  "caret",          # Machine learning
  "randomForest",   # Random Forest algorithm
  "rpart",          # Decision trees
  "rpart.plot",     # Decision tree visualization
  "corrplot",       # Correlation plots
  "scales",         # Scale functions for visualization
  "gridExtra",      # Arrange multiple plots
  "readr",          # Read CSV files
  "tibble",         # Modern data frames
  "Metrics"         # Model evaluation metrics
)

# Function to check and install packages
install_if_missing <- function(packages) {
  for (package in packages) {
    if (!require(package, character.only = TRUE)) {
      cat(paste("Installing package:", package, "\n"))
      install.packages(package, dependencies = TRUE)
      library(package, character.only = TRUE)
    } else {
      cat(paste("Package", package, "already installed.\n"))
    }
  }
}

# Install missing packages
cat("Checking and installing required packages...\n")
install_if_missing(required_packages)

cat("\n=== Package Installation Complete ===\n")
cat("All required packages are now installed and loaded.\n")
cat("You can proceed with running the analysis scripts.\n")

# Print session info for reproducibility
cat("\n=== Session Info ===\n")
print(sessionInfo())
