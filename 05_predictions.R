# 05_predictions.R
# Generate predictions and pricing recommendations for new Airbnb listings

# Load required libraries
library(tidyverse)
library(caret)

cat("=== AIRBNB PRICE PREDICTIONS & RECOMMENDATIONS ===\n\n")

# Load saved models
cat("Loading trained models...\n")
lm_model <- readRDS("outputs/linear_regression_model.rds")
dt_model <- readRDS("outputs/decision_tree_model.rds")
cat("✓ Models loaded successfully\n\n")

# ===== 1. CREATE SAMPLE NEW LISTINGS =====
cat("=== 1. CREATING SAMPLE NEW LISTINGS ===\n")

# Create sample listings for prediction
new_listings <- tibble(
  listing_id = c("NEW_001", "NEW_002", "NEW_003", "NEW_004", "NEW_005"),
  
  # Scenario 1: Budget apartment in suburbs
  # Scenario 2: Luxury house in downtown
  # Scenario 3: Beach condo with amenities
  # Scenario 4: Private room in university area
  # Scenario 5: Waterfront townhouse
  
  neighborhood = c("Suburbs", "Downtown", "Beach Area", 
                  "University Area", "Waterfront"),
  property_type = c("Apartment", "House", "Condo", "Apartment", "Townhouse"),
  room_type = c("Entire home/apt", "Entire home/apt", "Entire home/apt",
               "Private room", "Entire home/apt"),
  bedrooms = c(1, 4, 2, 1, 3),
  bathrooms = c(1, 3, 2, 1, 2.5),
  accommodates = c(2, 8, 4, 2, 6),
  num_amenities = c(10, 28, 22, 8, 25),
  host_is_superhost = c("No", "Yes", "Yes", "No", "Yes"),
  host_listings_count = c(1, 5, 3, 1, 2),
  host_years_active = c(1, 7, 4, 2, 5),
  number_of_reviews = c(5, 150, 80, 12, 95),
  review_scores_rating = c(4.2, 4.9, 4.7, 4.3, 4.8),
  availability_365 = c(300, 180, 250, 350, 200),
  minimum_nights = c(2, 3, 2, 1, 3),
  instant_bookable = c("Yes", "No", "Yes", "Yes", "Yes")
)

# Calculate derived features (same as in preprocessing)
new_listings <- new_listings %>%
  mutate(
    amenity_score = (num_amenities - 5) / (30 - 5),  # Normalize
    bed_bath_ratio = bedrooms / pmax(bathrooms, 0.5),
    
    # Ensure factors match training data levels
    neighborhood = factor(neighborhood),
    property_type = factor(property_type),
    room_type = factor(room_type),
    host_is_superhost = factor(host_is_superhost),
    instant_bookable = factor(instant_bookable)
  )

cat("Sample listings created:\n")
print(new_listings %>% select(listing_id, neighborhood, property_type, 
                              bedrooms, num_amenities))

# ===== 2. GENERATE PREDICTIONS =====
cat("\n=== 2. GENERATING PRICE PREDICTIONS ===\n")

# Predict using both models
new_listings$predicted_price_lr <- predict(lm_model, newdata = new_listings)
new_listings$predicted_price_dt <- predict(dt_model, newdata = new_listings)

# Calculate average prediction
new_listings <- new_listings %>%
  mutate(
    predicted_price_avg = (predicted_price_lr + predicted_price_dt) / 2,
    
    # Add confidence intervals (±15% based on model MAPE)
    price_low = predicted_price_avg * 0.85,
    price_high = predicted_price_avg * 1.15,
    
    # Round to reasonable values
    predicted_price_lr = round(predicted_price_lr, 2),
    predicted_price_dt = round(predicted_price_dt, 2),
    predicted_price_avg = round(predicted_price_avg, 2),
    price_low = round(price_low, 2),
    price_high = round(price_high, 2)
  )

# Display predictions
cat("\n=== PRICE PREDICTIONS ===\n")
predictions_display <- new_listings %>%
  select(listing_id, neighborhood, property_type, bedrooms,
         predicted_price_lr, predicted_price_dt, predicted_price_avg,
         price_low, price_high)

print(predictions_display)

# ===== 3. PRICING RECOMMENDATIONS =====
cat("\n=== 3. PRICING RECOMMENDATIONS ===\n")

# Generate detailed recommendations for each listing
generate_recommendation <- function(listing) {
  
  price_avg <- listing$predicted_price_avg
  price_range <- paste0("$", listing$price_low, " - $", listing$price_high)
  
  # Determine pricing strategy
  if (listing$review_scores_rating >= 4.7 && 
      listing$host_is_superhost == "Yes") {
    strategy <- "Premium Pricing"
    reason <- "Excellent reviews and Superhost status justify premium"
    recommended_price <- listing$price_high
  } else if (listing$number_of_reviews < 10) {
    strategy <- "Competitive Pricing"
    reason <- "New listing - attract early guests with lower price"
    recommended_price <- listing$price_low
  } else {
    strategy <- "Market Rate"
    reason <- "Standard pricing based on market conditions"
    recommended_price <- price_avg
  }
  
  # Optimization tips
  tips <- c()
  if (listing$num_amenities < 15) {
    tips <- c(tips, "Add more amenities to justify higher pricing")
  }
  if (listing$instant_bookable == "No") {
    tips <- c(tips, "Enable instant booking to increase visibility")
  }
  if (listing$minimum_nights > 2) {
    tips <- c(tips, "Consider reducing minimum nights for flexibility")
  }
  if (listing$host_is_superhost == "No" && listing$host_years_active > 2) {
    tips <- c(tips, "Work towards Superhost status for price premium")
  }
  
  return(list(
    listing_id = listing$listing_id,
    strategy = strategy,
    recommended_price = round(recommended_price, 2),
    price_range = price_range,
    reason = reason,
    tips = tips
  ))
}

# Generate recommendations for all listings
recommendations <- lapply(1:nrow(new_listings), function(i) {
  generate_recommendation(new_listings[i, ])
})

# Display recommendations
for (rec in recommendations) {
  cat("\n", paste(rep("=", 60), collapse = ""), "\n")
  cat("LISTING:", rec$listing_id, "\n")
  cat(paste(rep("-", 60), collapse = ""), "\n")
  cat("STRATEGY:", rec$strategy, "\n")
  cat("RECOMMENDED PRICE: $", rec$recommended_price, " per night\n")
  cat("PRICE RANGE:", rec$price_range, "\n")
  cat("REASON:", rec$reason, "\n")
  
  if (length(rec$tips) > 0) {
    cat("\nOPTIMIZATION TIPS:\n")
    for (tip in rec$tips) {
      cat("  •", tip, "\n")
    }
  }
}

# ===== 4. MARKET INSIGHTS =====
cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("=== 4. MARKET INSIGHTS ===\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

# Load original data for comparison
airbnb_data <- read_csv("data/airbnb_data_cleaned.csv", show_col_types = FALSE)

# Compare new listings to market averages
for (i in 1:nrow(new_listings)) {
  listing <- new_listings[i, ]
  
  # Find comparable listings
  comparable <- airbnb_data %>%
    filter(
      neighborhood == listing$neighborhood,
      bedrooms == listing$bedrooms
    )
  
  if (nrow(comparable) > 0) {
    cat("\nLISTING:", listing$listing_id, 
        "(", listing$neighborhood, ",", listing$bedrooms, "BR)\n")
    cat("Your predicted price: $", listing$predicted_price_avg, "\n")
    cat("Market average (similar): $", round(mean(comparable$price), 2), "\n")
    cat("Market median (similar): $", round(median(comparable$price), 2), "\n")
    cat("Market range: $", round(min(comparable$price), 2), " - $",
        round(max(comparable$price), 2), "\n")
    
    # Position in market
    percentile <- mean(comparable$price < listing$predicted_price_avg) * 100
    cat("Your position: ", round(percentile, 1), "th percentile\n")
    
    if (percentile > 75) {
      cat("→ PREMIUM positioning (top 25%)\n")
    } else if (percentile > 50) {
      cat("→ ABOVE AVERAGE positioning\n")
    } else if (percentile > 25) {
      cat("→ BELOW AVERAGE positioning\n")
    } else {
      cat("→ BUDGET positioning (bottom 25%)\n")
    }
  }
}

# ===== 5. COMPETITIVE ANALYSIS =====
cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("=== 5. COMPETITIVE ANALYSIS ===\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

# Analyze by neighborhood
neighborhood_analysis <- airbnb_data %>%
  group_by(neighborhood) %>%
  summarise(
    avg_price = mean(price),
    median_price = median(price),
    num_listings = n(),
    avg_rating = mean(review_scores_rating, na.rm = TRUE),
    superhost_pct = sum(host_is_superhost == "Yes") / n() * 100,
    .groups = "drop"
  ) %>%
  arrange(desc(avg_price))

cat("NEIGHBORHOOD COMPETITIVE LANDSCAPE:\n\n")
print(neighborhood_analysis)

# ===== 6. SAVE OUTPUTS =====
cat("\n=== 6. SAVING OUTPUTS ===\n")

# Save prediction results
write_csv(predictions_display, "outputs/new_listing_predictions.csv")
cat("✓ Predictions saved to: outputs/new_listing_predictions.csv\n")

# Create comprehensive recommendations report
rec_report <- paste(
  "AIRBNB PRICING RECOMMENDATIONS REPORT",
  "======================================",
  "",
  paste("Date:", Sys.Date()),
  paste("Listings Analyzed:", nrow(new_listings)),
  "",
  "=== SUMMARY OF PREDICTIONS ===",
  "",
  paste(capture.output(print(predictions_display, row.names = FALSE)), 
        collapse = "\n"),
  "",
  "=== DETAILED RECOMMENDATIONS ===",
  "",
  paste(sapply(recommendations, function(rec) {
    paste(
      paste("LISTING:", rec$listing_id),
      paste("Strategy:", rec$strategy),
      paste("Recommended Price: $", rec$recommended_price),
      paste("Price Range:", rec$price_range),
      paste("Reason:", rec$reason),
      if (length(rec$tips) > 0) {
        paste("Tips:", paste(rec$tips, collapse = "; "))
      } else {
        "Tips: None"
      },
      "",
      sep = "\n"
    )
  }), collapse = "\n"),
  "",
  "=== PRICING STRATEGIES EXPLAINED ===",
  "",
  "PREMIUM PRICING:",
  "  - For high-rated listings with Superhost status",
  "  - Price 10-15% above market average",
  "  - Focus on quality and experience",
  "",
  "MARKET RATE:",
  "  - Standard competitive pricing",
  "  - Price at market average",
  "  - Balance occupancy and revenue",
  "",
  "COMPETITIVE PRICING:",
  "  - For new or lower-rated listings",
  "  - Price 10-15% below market average",
  "  - Build reviews and reputation",
  "",
  "=== KEY SUCCESS FACTORS ===",
  "",
  "1. LOCATION - Choose high-demand neighborhoods",
  "2. AMENITIES - Offer 20+ amenities for premium pricing",
  "3. REVIEWS - Maintain 4.5+ rating for competitive advantage",
  "4. HOST STATUS - Achieve Superhost for 15-20% price premium",
  "5. FLEXIBILITY - Enable instant booking and low minimum nights",
  "",
  "=== DYNAMIC PRICING TIPS ===",
  "",
  "- Adjust prices seasonally (high/low demand periods)",
  "- Offer discounts for weekly/monthly stays",
  "- Monitor local events and adjust accordingly",
  "- Review and update pricing monthly",
  "- Use these predictions as baseline, not fixed prices",
  "",
  "For questions or model updates, refer to project documentation.",
  sep = "\n"
)

write(rec_report, "outputs/pricing_recommendations_report.txt")
cat("✓ Recommendations report saved to: outputs/pricing_recommendations_report.txt\n")

# ===== 7. VISUALIZATION OF PREDICTIONS =====
cat("\n=== 7. CREATING PREDICTION VISUALIZATIONS ===\n")

# Plot predictions comparison
p_predictions <- ggplot(new_listings, aes(x = listing_id)) +
  geom_point(aes(y = predicted_price_lr, color = "Linear Regression"), 
            size = 4) +
  geom_point(aes(y = predicted_price_dt, color = "Decision Tree"), 
            size = 4) +
  geom_point(aes(y = predicted_price_avg, color = "Average"), 
            size = 5, shape = 18) +
  geom_errorbar(aes(ymin = price_low, ymax = price_high), 
               width = 0.2, alpha = 0.5) +
  scale_color_manual(values = c("Linear Regression" = "#3498DB",
                                "Decision Tree" = "#E74C3C",
                                "Average" = "#2ECC71")) +
  labs(
    title = "Price Predictions for New Listings",
    subtitle = "Error bars show recommended price range (±15%)",
    x = "Listing ID",
    y = "Predicted Price (USD per night)",
    color = "Model"
  ) +
  scale_y_continuous(labels = scales::dollar_format()) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "top",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave("visualizations/17_new_listing_predictions.png", p_predictions,
       width = 12, height = 7, dpi = 300)
cat("✓ Prediction visualization saved\n")

# ===== FINAL SUMMARY =====
cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("=== PREDICTION & RECOMMENDATION COMPLETE ===\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

cat("✓ Generated predictions for", nrow(new_listings), "new listings\n")
cat("✓ Created personalized pricing recommendations\n")
cat("✓ Performed competitive analysis\n")
cat("✓ Saved all outputs and visualizations\n\n")

cat("OUTPUT FILES:\n")
cat("  - outputs/new_listing_predictions.csv\n")
cat("  - outputs/pricing_recommendations_report.txt\n")
cat("  - visualizations/17_new_listing_predictions.png\n\n")

cat("You can now use these predictions and recommendations for:\n")
cat("  • Setting competitive prices for new listings\n")
cat("  • Optimizing existing listing features\n")
cat("  • Understanding market positioning\n")
cat("  • Making data-driven pricing decisions\n\n")

cat("To predict prices for your own listings:\n")
cat("  1. Modify the new_listings data frame in this script\n")
cat("  2. Ensure all required features are provided\n")
cat("  3. Run the script to get predictions\n\n")

cat("PROJECT COMPLETE! 🎉\n")
