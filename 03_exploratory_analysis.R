# 03_exploratory_analysis.R
# Exploratory Data Analysis and Visualization

# Load required libraries
library(tidyverse)
library(ggplot2)
library(corrplot)
library(gridExtra)
library(scales)

cat("=== AIRBNB EXPLORATORY DATA ANALYSIS ===\n\n")

# Load cleaned data
cat("Loading cleaned data...\n")
airbnb_data <- read_csv("data/airbnb_data_cleaned.csv", show_col_types = FALSE)

# Ensure visualizations directory exists
if (!dir.exists("visualizations")) {
  dir.create("visualizations")
}

cat(paste("Analyzing", nrow(airbnb_data), "listings with", ncol(airbnb_data), "features\n\n"))

# Set ggplot theme
theme_set(theme_minimal(base_size = 12))
custom_colors <- c("#E74C3C", "#3498DB", "#2ECC71", "#F39C12", "#9B59B6", "#1ABC9C")

# ===== 1. PRICE DISTRIBUTION ANALYSIS =====
cat("=== 1. PRICE DISTRIBUTION ANALYSIS ===\n")

# Price distribution histogram
p1 <- ggplot(airbnb_data, aes(x = price)) +
  geom_histogram(bins = 50, fill = "#3498DB", color = "white", alpha = 0.8) +
  geom_vline(aes(xintercept = mean(price)), color = "#E74C3C", 
             linetype = "dashed", size = 1) +
  geom_vline(aes(xintercept = median(price)), color = "#2ECC71", 
             linetype = "dashed", size = 1) +
  labs(
    title = "Distribution of Airbnb Listing Prices",
    subtitle = paste("Mean: $", round(mean(airbnb_data$price), 2), 
                    " | Median: $", round(median(airbnb_data$price), 2)),
    x = "Price (USD per night)",
    y = "Number of Listings"
  ) +
  scale_x_continuous(labels = dollar_format()) +
  theme_minimal(base_size = 14)

ggsave("visualizations/01_price_distribution.png", p1, width = 10, height = 6, dpi = 300)
cat("✓ Price distribution plot saved\n")

# Price by property type boxplot
p2 <- ggplot(airbnb_data, aes(x = reorder(property_type, price, median), 
                               y = price, fill = property_type)) +
  geom_boxplot(alpha = 0.8, outlier.alpha = 0.5) +
  coord_flip() +
  scale_fill_manual(values = custom_colors) +
  labs(
    title = "Price Distribution by Property Type",
    subtitle = "Median prices vary significantly across property types",
    x = "Property Type",
    y = "Price (USD per night)"
  ) +
  scale_y_continuous(labels = dollar_format()) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("visualizations/02_price_by_property_type.png", p2, width = 10, height = 6, dpi = 300)
cat("✓ Price by property type plot saved\n")

# ===== 2. LOCATION ANALYSIS =====
cat("\n=== 2. LOCATION ANALYSIS ===\n")

# Calculate median price by neighborhood
neighborhood_stats <- airbnb_data %>%
  group_by(neighborhood) %>%
  summarise(
    median_price = median(price),
    mean_price = mean(price),
    count = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(median_price))

# Price by neighborhood
p3 <- ggplot(neighborhood_stats, aes(x = reorder(neighborhood, median_price), 
                                     y = median_price, fill = neighborhood)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0("$", round(median_price, 0))), 
            hjust = -0.2, size = 3.5) +
  coord_flip() +
  scale_fill_manual(values = rep(custom_colors, length.out = nrow(neighborhood_stats))) +
  labs(
    title = "Median Price by Neighborhood",
    subtitle = "Downtown and Beach areas command premium prices",
    x = "Neighborhood",
    y = "Median Price (USD per night)"
  ) +
  scale_y_continuous(labels = dollar_format(), expand = expansion(mult = c(0, 0.15))) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("visualizations/03_price_by_neighborhood.png", p3, width = 10, height = 7, dpi = 300)
cat("✓ Price by neighborhood plot saved\n")

# ===== 3. CORRELATION ANALYSIS =====
cat("\n=== 3. CORRELATION ANALYSIS ===\n")

# Select numeric variables for correlation
numeric_vars <- airbnb_data %>%
  select(price, bedrooms, bathrooms, accommodates, num_amenities, 
         host_listings_count, host_years_active, number_of_reviews, 
         review_scores_rating, availability_365, minimum_nights,
         price_per_bedroom, amenity_score, bed_bath_ratio) %>%
  na.omit()

# Calculate correlation matrix
cor_matrix <- cor(numeric_vars)

# Correlation heatmap
png("visualizations/04_correlation_matrix.png", width = 12, height = 10, 
    units = "in", res = 300)
corrplot(cor_matrix, method = "color", type = "upper", 
         tl.col = "black", tl.srt = 45,
         addCoef.col = "black", number.cex = 0.7,
         col = colorRampPalette(c("#E74C3C", "white", "#3498DB"))(200),
         title = "Correlation Matrix of Numeric Features",
         mar = c(0, 0, 2, 0))
dev.off()
cat("✓ Correlation matrix saved\n")

# Top correlations with price
price_correlations <- cor_matrix[, "price"] %>%
  sort(decreasing = TRUE) %>%
  as.data.frame() %>%
  rownames_to_column("variable") %>%
  rename(correlation = ".") %>%
  filter(variable != "price")

cat("\nTop correlations with price:\n")
print(head(price_correlations, 5))

# ===== 4. ROOM TYPE ANALYSIS =====
cat("\n=== 4. ROOM TYPE ANALYSIS ===\n")

room_type_stats <- airbnb_data %>%
  group_by(room_type) %>%
  summarise(
    avg_price = mean(price),
    median_price = median(price),
    count = n(),
    pct = n() / nrow(airbnb_data) * 100,
    .groups = "drop"
  )

# Room type distribution and price
p4 <- ggplot(airbnb_data, aes(x = room_type, y = price, fill = room_type)) +
  geom_violin(alpha = 0.6, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.alpha = 0.3) +
  scale_fill_manual(values = custom_colors[1:3]) +
  labs(
    title = "Price Distribution by Room Type",
    subtitle = "Entire homes command significantly higher prices",
    x = "Room Type",
    y = "Price (USD per night)"
  ) +
  scale_y_continuous(labels = dollar_format()) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("visualizations/05_price_by_room_type.png", p4, width = 10, height = 6, dpi = 300)
cat("✓ Price by room type plot saved\n")

# ===== 5. AMENITIES IMPACT =====
cat("\n=== 5. AMENITIES IMPACT ANALYSIS ===\n")

# Scatter plot: amenities vs price
p5 <- ggplot(airbnb_data, aes(x = num_amenities, y = price)) +
  geom_point(alpha = 0.3, color = "#3498DB", size = 2) +
  geom_smooth(method = "lm", color = "#E74C3C", size = 1.5, se = TRUE) +
  labs(
    title = "Relationship Between Amenities and Price",
    subtitle = paste("Correlation:", round(cor(airbnb_data$num_amenities, 
                                               airbnb_data$price), 3)),
    x = "Number of Amenities",
    y = "Price (USD per night)"
  ) +
  scale_y_continuous(labels = dollar_format()) +
  theme_minimal(base_size = 14)

ggsave("visualizations/06_amenities_vs_price.png", p5, width = 10, height = 6, dpi = 300)
cat("✓ Amenities vs price plot saved\n")

# ===== 6. HOST ANALYSIS =====
cat("\n=== 6. HOST ANALYSIS ===\n")

# Superhost comparison
superhost_comparison <- airbnb_data %>%
  group_by(host_is_superhost) %>%
  summarise(
    avg_price = mean(price),
    median_price = median(price),
    avg_rating = mean(review_scores_rating, na.rm = TRUE),
    count = n(),
    .groups = "drop"
  )

p6 <- ggplot(airbnb_data, aes(x = host_is_superhost, y = price, 
                               fill = host_is_superhost)) +
  geom_boxplot(alpha = 0.8, outlier.alpha = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 4, 
               fill = "white", color = "black") +
  scale_fill_manual(values = c("No" = "#95A5A6", "Yes" = "#F39C12")) +
  labs(
    title = "Price Comparison: Superhosts vs Regular Hosts",
    subtitle = "Superhosts typically charge premium prices",
    x = "Superhost Status",
    y = "Price (USD per night)",
    fill = "Superhost"
  ) +
  scale_y_continuous(labels = dollar_format()) +
  theme_minimal(base_size = 14)

ggsave("visualizations/07_superhost_comparison.png", p6, width = 10, height = 6, dpi = 300)
cat("✓ Superhost comparison plot saved\n")

# ===== 7. REVIEWS AND RATINGS =====
cat("\n=== 7. REVIEWS AND RATINGS ANALYSIS ===\n")

# Rating vs price
p7 <- ggplot(airbnb_data, aes(x = review_scores_rating, y = price)) +
  geom_point(alpha = 0.3, color = "#9B59B6", size = 2) +
  geom_smooth(method = "loess", color = "#E74C3C", size = 1.5, se = TRUE) +
  labs(
    title = "Relationship Between Review Ratings and Price",
    subtitle = "Higher-rated properties tend to have higher prices",
    x = "Review Score Rating (1-5)",
    y = "Price (USD per night)"
  ) +
  scale_y_continuous(labels = dollar_format()) +
  theme_minimal(base_size = 14)

ggsave("visualizations/08_ratings_vs_price.png", p7, width = 10, height = 6, dpi = 300)
cat("✓ Ratings vs price plot saved\n")

# ===== 8. BEDROOM AND CAPACITY ANALYSIS =====
cat("\n=== 8. BEDROOM AND CAPACITY ANALYSIS ===\n")

# Price by bedrooms
bedroom_stats <- airbnb_data %>%
  group_by(bedrooms) %>%
  summarise(
    avg_price = mean(price),
    median_price = median(price),
    count = n(),
    .groups = "drop"
  )

p8 <- ggplot(bedroom_stats, aes(x = factor(bedrooms), y = avg_price, 
                                 fill = factor(bedrooms))) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0("$", round(avg_price, 0))), 
            vjust = -0.5, size = 4) +
  scale_fill_manual(values = rep(custom_colors, length.out = nrow(bedroom_stats))) +
  labs(
    title = "Average Price by Number of Bedrooms",
    subtitle = "Price increases with property size",
    x = "Number of Bedrooms",
    y = "Average Price (USD per night)"
  ) +
  scale_y_continuous(labels = dollar_format(), expand = expansion(mult = c(0, 0.15))) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("visualizations/09_price_by_bedrooms.png", p8, width = 10, height = 6, dpi = 300)
cat("✓ Price by bedrooms plot saved\n")

# ===== 9. MULTI-PANEL COMPARISON =====
cat("\n=== 9. CREATING COMPREHENSIVE COMPARISON PLOT ===\n")

# Create a 2x2 grid of key insights
p_grid1 <- ggplot(airbnb_data, aes(x = bedrooms, y = price)) +
  geom_jitter(alpha = 0.3, color = "#3498DB") +
  geom_smooth(method = "lm", color = "#E74C3C") +
  labs(title = "Bedrooms vs Price", x = "Bedrooms", y = "Price") +
  scale_y_continuous(labels = dollar_format()) +
  theme_minimal()

p_grid2 <- ggplot(airbnb_data, aes(x = room_type, fill = room_type)) +
  geom_bar(alpha = 0.8) +
  scale_fill_manual(values = custom_colors[1:3]) +
  labs(title = "Room Type Distribution", x = "", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))

p_grid3 <- ggplot(airbnb_data, aes(x = num_amenities, y = price)) +
  geom_point(alpha = 0.3, color = "#9B59B6") +
  geom_smooth(method = "lm", color = "#E74C3C") +
  labs(title = "Amenities vs Price", x = "Amenities", y = "Price") +
  scale_y_continuous(labels = dollar_format()) +
  theme_minimal()

p_grid4 <- ggplot(airbnb_data, aes(x = host_is_superhost, fill = host_is_superhost)) +
  geom_bar(alpha = 0.8) +
  scale_fill_manual(values = c("#95A5A6", "#F39C12")) +
  labs(title = "Superhost Distribution", x = "", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none")

p_combined <- grid.arrange(p_grid1, p_grid2, p_grid3, p_grid4, ncol = 2,
                          top = "Key Market Insights - Airbnb Pricing Factors")

ggsave("visualizations/10_comprehensive_analysis.png", p_combined, 
       width = 14, height = 10, dpi = 300)
cat("✓ Comprehensive analysis plot saved\n")

# ===== 10. GENERATE INSIGHTS REPORT =====
cat("\n=== 10. GENERATING INSIGHTS REPORT ===\n")

insights_report <- paste(
  "AIRBNB PRICE ANALYSIS - KEY INSIGHTS",
  "=====================================",
  "",
  paste("Analysis Date:", Sys.Date()),
  paste("Total Listings Analyzed:", nrow(airbnb_data)),
  "",
  "PRICE STATISTICS:",
  paste("  Average Price: $", round(mean(airbnb_data$price), 2)),
  paste("  Median Price: $", round(median(airbnb_data$price), 2)),
  paste("  Price Range: $", round(min(airbnb_data$price), 2), " - $", 
        round(max(airbnb_data$price), 2)),
  "",
  "TOP INSIGHTS:",
  "",
  "1. LOCATION IMPACT:",
  paste("   - Highest prices in:", neighborhood_stats$neighborhood[1],
        "($", round(neighborhood_stats$median_price[1], 2), "median)"),
  paste("   - Lowest prices in:", tail(neighborhood_stats$neighborhood, 1),
        "($", round(tail(neighborhood_stats$median_price, 1), 2), "median)"),
  paste("   - Price variance across neighborhoods:",
        round((max(neighborhood_stats$median_price) - min(neighborhood_stats$median_price)) / 
              min(neighborhood_stats$median_price) * 100, 1), "%"),
  "",
  "2. PROPERTY CHARACTERISTICS:",
  paste("   - Strong correlation between bedrooms and price (r =",
        round(cor(airbnb_data$bedrooms, airbnb_data$price), 3), ")"),
  paste("   - Amenities impact: r =", 
        round(cor(airbnb_data$num_amenities, airbnb_data$price), 3)),
  paste("   - Room type: Entire homes are", 
        round(mean(airbnb_data$price[airbnb_data$room_type == "Entire home/apt"]) /
              mean(airbnb_data$price[airbnb_data$room_type == "Private room"]), 2),
        "x more expensive than private rooms"),
  "",
  "3. HOST FACTORS:",
  paste("   - Superhost premium:",
        round((superhost_comparison$avg_price[superhost_comparison$host_is_superhost == "Yes"] /
               superhost_comparison$avg_price[superhost_comparison$host_is_superhost == "No"] - 1) * 100, 1),
        "% higher average price"),
  paste("   - Superhosts represent", 
        round(sum(airbnb_data$host_is_superhost == "Yes") / nrow(airbnb_data) * 100, 1),
        "% of listings"),
  "",
  "4. REVIEW IMPACT:",
  paste("   - Correlation between ratings and price: r =",
        round(cor(airbnb_data$review_scores_rating, airbnb_data$price, 
                  use = "complete.obs"), 3)),
  paste("   - Average rating across all listings:",
        round(mean(airbnb_data$review_scores_rating, na.rm = TRUE), 2), "/ 5.0"),
  "",
  "5. KEY PRICE DRIVERS (in order of importance):",
  paste("   1.", price_correlations$variable[1], 
        "(r =", round(price_correlations$correlation[1], 3), ")"),
  paste("   2.", price_correlations$variable[2],
        "(r =", round(price_correlations$correlation[2], 3), ")"),
  paste("   3.", price_correlations$variable[3],
        "(r =", round(price_correlations$correlation[3], 3), ")"),
  "",
  "VISUALIZATIONS GENERATED:",
  "  ✓ 01_price_distribution.png",
  "  ✓ 02_price_by_property_type.png",
  "  ✓ 03_price_by_neighborhood.png",
  "  ✓ 04_correlation_matrix.png",
  "  ✓ 05_price_by_room_type.png",
  "  ✓ 06_amenities_vs_price.png",
  "  ✓ 07_superhost_comparison.png",
  "  ✓ 08_ratings_vs_price.png",
  "  ✓ 09_price_by_bedrooms.png",
  "  ✓ 10_comprehensive_analysis.png",
  "",
  "All visualizations saved in: visualizations/",
  "",
  "NEXT STEPS:",
  "Run 04_modeling.R to build predictive models",
  sep = "\n"
)

write(insights_report, "outputs/eda_insights_report.txt")
cat("\n✓ Insights report saved to: outputs/eda_insights_report.txt\n")

# ===== SUMMARY =====
cat("\n=== EXPLORATORY ANALYSIS COMPLETE ===\n")
cat("✓ 10 visualizations created and saved\n")
cat("✓ Statistical insights generated\n")
cat("✓ Ready for modeling phase\n\n")
cat("All plots are in: visualizations/\n")
cat("Next step: Run 04_modeling.R for predictive modeling\n")
