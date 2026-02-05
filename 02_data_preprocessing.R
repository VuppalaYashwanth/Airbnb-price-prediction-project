# 02_data_preprocessing.R
# Data cleaning and preprocessing for Airbnb price prediction

# Load required libraries
library(tidyverse)
library(caret)

cat("=== AIRBNB DATA PREPROCESSING ===\n\n")

# Load data
cat("Loading data...\n")
airbnb_data <- read_csv("data/airbnb_data.csv", show_col_types = FALSE)

cat(paste("Original dataset size:", nrow(airbnb_data), "rows,", ncol(airbnb_data), "columns\n\n"))

# ===== 1. DATA INSPECTION =====
cat("=== 1. DATA INSPECTION ===\n")

# Check structure
cat("\nData structure:\n")
str(airbnb_data)

# Summary statistics
cat("\nSummary statistics:\n")
print(summary(airbnb_data))

# Check for missing values
cat("\n=== Missing Values ===\n")
missing_summary <- airbnb_data %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
  mutate(missing_percent = round(missing_count / nrow(airbnb_data) * 100, 2)) %>%
  filter(missing_count > 0)

if(nrow(missing_summary) > 0) {
  print(missing_summary)
} else {
  cat("No missing values found!\n")
}

# ===== 2. HANDLING MISSING VALUES =====
cat("\n=== 2. HANDLING MISSING VALUES ===\n")

airbnb_cleaned <- airbnb_data %>%
  mutate(
    # Impute review scores with median (for listings with no reviews)
    review_scores_rating = ifelse(is.na(review_scores_rating), 
                                 median(review_scores_rating, na.rm = TRUE), 
                                 review_scores_rating),
    
    # Impute host years active with median
    host_years_active = ifelse(is.na(host_years_active),
                              median(host_years_active, na.rm = TRUE),
                              host_years_active)
  )

cat("Missing values handled using median imputation.\n")

# ===== 3. OUTLIER DETECTION AND HANDLING =====
cat("\n=== 3. OUTLIER DETECTION ===\n")

# Function to detect outliers using IQR method
detect_outliers <- function(x) {
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  lower_bound <- Q1 - 1.5 * IQR
  upper_bound <- Q3 + 1.5 * IQR
  return(x < lower_bound | x > upper_bound)
}

# Detect price outliers
price_outliers <- detect_outliers(airbnb_cleaned$price)
cat(paste("Price outliers detected:", sum(price_outliers), "listings\n"))

# Cap outliers instead of removing them (to preserve data)
Q1_price <- quantile(airbnb_cleaned$price, 0.25)
Q3_price <- quantile(airbnb_cleaned$price, 0.75)
IQR_price <- Q3_price - Q1_price
price_lower <- Q1_price - 1.5 * IQR_price
price_upper <- Q3_price + 1.5 * IQR_price

airbnb_cleaned <- airbnb_cleaned %>%
  mutate(price_original = price,
         price = ifelse(price > price_upper, price_upper, price),
         price = ifelse(price < price_lower, price_lower, price))

cat(paste("Price range after capping: $", round(min(airbnb_cleaned$price), 2), 
          " - $", round(max(airbnb_cleaned$price), 2), "\n"))

# ===== 4. FEATURE ENGINEERING =====
cat("\n=== 4. FEATURE ENGINEERING ===\n")

airbnb_cleaned <- airbnb_cleaned %>%
  mutate(
    # Create derived features
    price_per_bedroom = price / pmax(bedrooms, 1),
    price_per_guest = price / pmax(accommodates, 1),
    
    # Amenity score (normalized)
    amenity_score = (num_amenities - min(num_amenities)) / 
                    (max(num_amenities) - min(num_amenities)),
    
    # Review quality indicator
    high_rated = ifelse(review_scores_rating >= 4.5, "Yes", "No"),
    
    # Availability score
    availability_score = availability_365 / 365,
    
    # Host experience
    experienced_host = ifelse(host_years_active >= 3, "Yes", "No"),
    
    # Popular listing (many reviews)
    popular_listing = ifelse(number_of_reviews >= quantile(number_of_reviews, 0.75), 
                            "Yes", "No"),
    
    # Bedroom to bathroom ratio
    bed_bath_ratio = bedrooms / pmax(bathrooms, 0.5),
    
    # Luxury indicator (combination of features)
    luxury_score = (bedrooms >= 3) + 
                   (bathrooms >= 2) + 
                   (num_amenities >= 20) + 
                   (host_is_superhost == "Yes") + 
                   (review_scores_rating >= 4.7)
  )

cat("New features created:\n")
cat("  - price_per_bedroom\n")
cat("  - price_per_guest\n")
cat("  - amenity_score\n")
cat("  - high_rated (Yes/No)\n")
cat("  - availability_score\n")
cat("  - experienced_host (Yes/No)\n")
cat("  - popular_listing (Yes/No)\n")
cat("  - bed_bath_ratio\n")
cat("  - luxury_score\n")

# ===== 5. ENCODE CATEGORICAL VARIABLES =====
cat("\n=== 5. ENCODING CATEGORICAL VARIABLES ===\n")

# Convert character columns to factors
airbnb_cleaned <- airbnb_cleaned %>%
  mutate(across(where(is.character), as.factor))

cat("Categorical variables converted to factors.\n")
cat("\nFactor levels:\n")
cat("  - Neighborhoods:", nlevels(airbnb_cleaned$neighborhood), "levels\n")
cat("  - Property types:", nlevels(airbnb_cleaned$property_type), "levels\n")
cat("  - Room types:", nlevels(airbnb_cleaned$room_type), "levels\n")

# ===== 6. DATA VALIDATION =====
cat("\n=== 6. DATA VALIDATION ===\n")

# Check for any remaining issues
validation_checks <- list(
  no_missing = sum(is.na(airbnb_cleaned)) == 0,
  positive_prices = all(airbnb_cleaned$price > 0),
  valid_bedrooms = all(airbnb_cleaned$bedrooms > 0),
  valid_ratings = all(airbnb_cleaned$review_scores_rating >= 1 & 
                     airbnb_cleaned$review_scores_rating <= 5)
)

cat("Validation checks:\n")
for(check_name in names(validation_checks)) {
  status <- ifelse(validation_checks[[check_name]], "PASS", "FAIL")
  cat(paste("  -", check_name, ":", status, "\n"))
}

# ===== 7. SAVE CLEANED DATA =====
cat("\n=== 7. SAVING PREPROCESSED DATA ===\n")

# Save cleaned dataset
write_csv(airbnb_cleaned, "data/airbnb_data_cleaned.csv")
cat("Cleaned data saved to: data/airbnb_data_cleaned.csv\n")

# Save preprocessing report
preprocessing_summary <- paste(
  "AIRBNB DATA PREPROCESSING SUMMARY",
  "==================================",
  "",
  paste("Date:", Sys.Date()),
  paste("Original dataset:", nrow(airbnb_data), "listings"),
  paste("Cleaned dataset:", nrow(airbnb_cleaned), "listings"),
  paste("Features:", ncol(airbnb_cleaned)),
  "",
  "PREPROCESSING STEPS:",
  "1. Missing value imputation using median",
  "2. Outlier detection and capping using IQR method",
  paste("3. Created", sum(!(names(airbnb_cleaned) %in% names(airbnb_data))), "new features"),
  "4. Encoded categorical variables as factors",
  "5. Validated data quality",
  "",
  "PRICE STATISTICS (After Preprocessing):",
  paste("Mean:", round(mean(airbnb_cleaned$price), 2)),
  paste("Median:", round(median(airbnb_cleaned$price), 2)),
  paste("Std Dev:", round(sd(airbnb_cleaned$price), 2)),
  paste("Range: $", round(min(airbnb_cleaned$price), 2), " - $", 
        round(max(airbnb_cleaned$price), 2)),
  "",
  "READY FOR ANALYSIS AND MODELING",
  sep = "\n"
)

write(preprocessing_summary, "outputs/preprocessing_summary.txt")
cat("Preprocessing summary saved to: outputs/preprocessing_summary.txt\n")

# ===== 8. FINAL SUMMARY =====
cat("\n=== PREPROCESSING COMPLETE ===\n")
cat(paste("Final dataset:", nrow(airbnb_cleaned), "rows,", ncol(airbnb_cleaned), "columns\n"))
cat("\nYou can now proceed with exploratory analysis using 03_exploratory_analysis.R\n")
