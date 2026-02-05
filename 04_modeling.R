# 04_modeling.R
# Predictive modeling for Airbnb price prediction

# Load required libraries
library(tidyverse)
library(caret)
library(rpart)
library(rpart.plot)
library(Metrics)

cat("=== AIRBNB PRICE PREDICTION MODELING ===\n\n")

# Set seed for reproducibility
set.seed(123)

# Load cleaned data
cat("Loading cleaned data...\n")
airbnb_data <- read_csv("data/airbnb_data_cleaned.csv", show_col_types = FALSE)

cat(paste("Dataset size:", nrow(airbnb_data), "listings\n\n"))

# ===== 1. PREPARE DATA FOR MODELING =====
cat("=== 1. DATA PREPARATION ===\n")

# Select features for modeling
model_features <- c(
  # Target variable
  "price",
  
  # Location
  "neighborhood",
  
  # Property characteristics
  "property_type", "room_type", "bedrooms", "bathrooms", "accommodates",
  
  # Amenities
  "num_amenities", "amenity_score",
  
  # Host features
  "host_is_superhost", "host_listings_count", "host_years_active",
  
  # Reviews
  "number_of_reviews", "review_scores_rating",
  
  # Availability
  "availability_365", "minimum_nights",
  
  # Additional features
  "instant_bookable", "bed_bath_ratio"
)

# Create modeling dataset
model_data <- airbnb_data %>%
  select(all_of(model_features)) %>%
  na.omit()

cat(paste("Modeling dataset:", nrow(model_data), "listings after removing NA\n"))
cat(paste("Features used:", length(model_features) - 1, "\n\n"))

# ===== 2. SPLIT DATA =====
cat("=== 2. TRAIN-TEST SPLIT ===\n")

# Create 80-20 train-test split
train_index <- createDataPartition(model_data$price, p = 0.8, list = FALSE)
train_data <- model_data[train_index, ]
test_data <- model_data[-train_index, ]

cat(paste("Training set:", nrow(train_data), "listings\n"))
cat(paste("Test set:", nrow(test_data), "listings\n\n"))

# ===== 3. LINEAR REGRESSION MODEL =====
cat("=== 3. LINEAR REGRESSION MODEL ===\n")

# Train linear regression model
cat("Training Linear Regression model...\n")

lm_model <- lm(price ~ ., data = train_data)

# Model summary
cat("\nLinear Regression Summary:\n")
print(summary(lm_model))

# Get predictions on test set
lm_predictions <- predict(lm_model, newdata = test_data)

# Calculate metrics
lm_rmse <- rmse(test_data$price, lm_predictions)
lm_mae <- mae(test_data$price, lm_predictions)
lm_r2 <- cor(test_data$price, lm_predictions)^2
lm_mape <- mean(abs((test_data$price - lm_predictions) / test_data$price)) * 100

cat("\nLinear Regression Performance:\n")
cat(paste("  RMSE: $", round(lm_rmse, 2), "\n"))
cat(paste("  MAE: $", round(lm_mae, 2), "\n"))
cat(paste("  R²: ", round(lm_r2, 4), "\n"))
cat(paste("  MAPE: ", round(lm_mape, 2), "%\n"))

# Feature importance from linear regression (coefficient magnitudes)
lm_coef <- as.data.frame(coef(lm_model)) %>%
  rownames_to_column("feature") %>%
  rename(coefficient = "coef(lm_model)") %>%
  filter(feature != "(Intercept)") %>%
  mutate(abs_coefficient = abs(coefficient)) %>%
  arrange(desc(abs_coefficient))

# ===== 4. DECISION TREE MODEL =====
cat("\n=== 4. DECISION TREE MODEL ===\n")

# Train decision tree model
cat("Training Decision Tree model...\n")

# Use rpart for decision tree
dt_model <- rpart(
  price ~ .,
  data = train_data,
  method = "anova",
  control = rpart.control(
    minsplit = 20,
    minbucket = 10,
    cp = 0.001,
    maxdepth = 10
  )
)

# Prune the tree using cross-validation
cat("Pruning decision tree using cross-validation...\n")
best_cp <- dt_model$cptable[which.min(dt_model$cptable[, "xerror"]), "CP"]
dt_model_pruned <- prune(dt_model, cp = best_cp)

# Plot decision tree
png("visualizations/11_decision_tree.png", width = 14, height = 10, 
    units = "in", res = 300)
rpart.plot(dt_model_pruned, 
          type = 4, 
          extra = 101,
          under = TRUE,
          faclen = 0,
          cex = 0.8,
          main = "Decision Tree for Airbnb Price Prediction",
          box.palette = "RdYlGn")
dev.off()
cat("✓ Decision tree plot saved\n")

# Get predictions on test set
dt_predictions <- predict(dt_model_pruned, newdata = test_data)

# Calculate metrics
dt_rmse <- rmse(test_data$price, dt_predictions)
dt_mae <- mae(test_data$price, dt_predictions)
dt_r2 <- cor(test_data$price, dt_predictions)^2
dt_mape <- mean(abs((test_data$price - dt_predictions) / test_data$price)) * 100

cat("\nDecision Tree Performance:\n")
cat(paste("  RMSE: $", round(dt_rmse, 2), "\n"))
cat(paste("  MAE: $", round(dt_mae, 2), "\n"))
cat(paste("  R²: ", round(dt_r2, 4), "\n"))
cat(paste("  MAPE: ", round(dt_mape, 2), "%\n"))

# Feature importance from decision tree
dt_importance <- as.data.frame(dt_model_pruned$variable.importance) %>%
  rownames_to_column("feature") %>%
  rename(importance = "dt_model_pruned$variable.importance") %>%
  arrange(desc(importance))

# ===== 5. MODEL COMPARISON =====
cat("\n=== 5. MODEL COMPARISON ===\n")

# Create comparison dataframe
model_comparison <- data.frame(
  Model = c("Linear Regression", "Decision Tree"),
  RMSE = c(lm_rmse, dt_rmse),
  MAE = c(lm_mae, dt_mae),
  R_squared = c(lm_r2, dt_r2),
  MAPE = c(lm_mape, dt_mape)
)

cat("\nModel Performance Comparison:\n")
print(model_comparison)

# Visualize model comparison
comparison_long <- model_comparison %>%
  pivot_longer(cols = c(RMSE, MAE, R_squared, MAPE), 
              names_to = "Metric", values_to = "Value")

# Create separate plots for different scales
p_rmse_mae <- ggplot(comparison_long %>% filter(Metric %in% c("RMSE", "MAE")),
                     aes(x = Model, y = Value, fill = Model)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(Value, 2)), vjust = -0.5) +
  facet_wrap(~Metric, scales = "free_y") +
  scale_fill_manual(values = c("#3498DB", "#E74C3C")) +
  labs(title = "Model Comparison: Error Metrics (Lower is Better)",
       subtitle = "RMSE and MAE in USD",
       y = "Value") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("visualizations/12_model_comparison_errors.png", p_rmse_mae, 
       width = 10, height = 6, dpi = 300)

p_r2_mape <- ggplot(comparison_long %>% filter(Metric %in% c("R_squared", "MAPE")),
                    aes(x = Model, y = Value, fill = Model)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(Value, 2)), vjust = -0.5) +
  facet_wrap(~Metric, scales = "free_y") +
  scale_fill_manual(values = c("#3498DB", "#E74C3C")) +
  labs(title = "Model Comparison: Performance Metrics",
       subtitle = "R² (Higher is Better) and MAPE % (Lower is Better)",
       y = "Value") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("visualizations/13_model_comparison_performance.png", p_r2_mape, 
       width = 10, height = 6, dpi = 300)

cat("✓ Model comparison plots saved\n")

# ===== 6. PREDICTION vs ACTUAL PLOTS =====
cat("\n=== 6. PREDICTION VISUALIZATION ===\n")

# Combine predictions
predictions_df <- data.frame(
  Actual = test_data$price,
  Linear_Regression = lm_predictions,
  Decision_Tree = dt_predictions
) %>%
  mutate(
    LR_Error = Actual - Linear_Regression,
    DT_Error = Actual - Decision_Tree
  )

# Scatter plot: Predicted vs Actual for both models
p_pred_actual <- ggplot(predictions_df) +
  geom_point(aes(x = Actual, y = Linear_Regression, color = "Linear Regression"), 
             alpha = 0.5, size = 2) +
  geom_point(aes(x = Actual, y = Decision_Tree, color = "Decision Tree"), 
             alpha = 0.5, size = 2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", 
              color = "black", size = 1) +
  scale_color_manual(values = c("Linear Regression" = "#3498DB", 
                                "Decision Tree" = "#E74C3C")) +
  labs(
    title = "Predicted vs Actual Prices",
    subtitle = "Perfect predictions would fall on the diagonal line",
    x = "Actual Price (USD)",
    y = "Predicted Price (USD)",
    color = "Model"
  ) +
  scale_x_continuous(labels = scales::dollar_format()) +
  scale_y_continuous(labels = scales::dollar_format()) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top")

ggsave("visualizations/14_predicted_vs_actual.png", p_pred_actual, 
       width = 10, height = 8, dpi = 300)
cat("✓ Predicted vs actual plot saved\n")

# Residual plots
p_residuals <- ggplot(predictions_df) +
  geom_histogram(aes(x = LR_Error, fill = "Linear Regression"), 
                alpha = 0.6, bins = 50) +
  geom_histogram(aes(x = DT_Error, fill = "Decision Tree"), 
                alpha = 0.6, bins = 50) +
  scale_fill_manual(values = c("Linear Regression" = "#3498DB", 
                               "Decision Tree" = "#E74C3C")) +
  labs(
    title = "Distribution of Prediction Errors (Residuals)",
    subtitle = "Residual = Actual - Predicted",
    x = "Prediction Error (USD)",
    y = "Frequency",
    fill = "Model"
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top")

ggsave("visualizations/15_residuals_distribution.png", p_residuals, 
       width = 10, height = 6, dpi = 300)
cat("✓ Residuals distribution plot saved\n")

# ===== 7. FEATURE IMPORTANCE =====
cat("\n=== 7. FEATURE IMPORTANCE ===\n")

# Plot feature importance from decision tree
top_features <- head(dt_importance, 15)

p_importance <- ggplot(top_features, aes(x = reorder(feature, importance), 
                                         y = importance)) +
  geom_col(fill = "#3498DB", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Top 15 Most Important Features (Decision Tree)",
    subtitle = "Feature importance based on reduction in variance",
    x = "Feature",
    y = "Importance"
  ) +
  theme_minimal(base_size = 14)

ggsave("visualizations/16_feature_importance.png", p_importance, 
       width = 10, height = 8, dpi = 300)
cat("✓ Feature importance plot saved\n")

# Save feature importance to CSV
write_csv(dt_importance, "outputs/feature_importance.csv")
cat("✓ Feature importance saved to CSV\n")

# ===== 8. SAVE MODELS AND RESULTS =====
cat("\n=== 8. SAVING MODELS AND RESULTS ===\n")

# Save models
saveRDS(lm_model, "outputs/linear_regression_model.rds")
saveRDS(dt_model_pruned, "outputs/decision_tree_model.rds")
cat("✓ Models saved as RDS files\n")

# Save predictions
write_csv(predictions_df, "outputs/predictions_sample.csv")
cat("✓ Predictions saved to CSV\n")

# Save comprehensive model performance report
performance_report <- paste(
  "AIRBNB PRICE PREDICTION - MODEL PERFORMANCE REPORT",
  "===================================================",
  "",
  paste("Date:", Sys.Date()),
  paste("Training set:", nrow(train_data), "listings"),
  paste("Test set:", nrow(test_data), "listings"),
  "",
  "MODELS EVALUATED:",
  "1. Linear Regression",
  "2. Decision Tree (Pruned)",
  "",
  "=== LINEAR REGRESSION ===",
  paste("RMSE: $", round(lm_rmse, 2)),
  paste("MAE: $", round(lm_mae, 2)),
  paste("R²:", round(lm_r2, 4)),
  paste("MAPE:", round(lm_mape, 2), "%"),
  "",
  "Interpretation:",
  paste("- On average, predictions are off by $", round(lm_mae, 2)),
  paste("- Model explains", round(lm_r2 * 100, 2), "% of price variance"),
  paste("- Percentage error:", round(lm_mape, 2), "%"),
  "",
  "=== DECISION TREE ===",
  paste("RMSE: $", round(dt_rmse, 2)),
  paste("MAE: $", round(dt_mae, 2)),
  paste("R²:", round(dt_r2, 4)),
  paste("MAPE:", round(dt_mape, 2), "%"),
  "",
  "Interpretation:",
  paste("- On average, predictions are off by $", round(dt_mae, 2)),
  paste("- Model explains", round(dt_r2 * 100, 2), "% of price variance"),
  paste("- Percentage error:", round(dt_mape, 2), "%"),
  "",
  "=== MODEL COMPARISON ===",
  ifelse(lm_rmse < dt_rmse,
         "Linear Regression has lower RMSE (better prediction accuracy)",
         "Decision Tree has lower RMSE (better prediction accuracy)"),
  ifelse(lm_r2 > dt_r2,
         "Linear Regression has higher R² (explains more variance)",
         "Decision Tree has higher R² (explains more variance)"),
  "",
  "=== TOP 5 MOST IMPORTANT FEATURES ===",
  paste("1.", dt_importance$feature[1], 
        "(importance:", round(dt_importance$importance[1], 2), ")"),
  paste("2.", dt_importance$feature[2],
        "(importance:", round(dt_importance$importance[2], 2), ")"),
  paste("3.", dt_importance$feature[3],
        "(importance:", round(dt_importance$importance[3], 2), ")"),
  paste("4.", dt_importance$feature[4],
        "(importance:", round(dt_importance$importance[4], 2), ")"),
  paste("5.", dt_importance$feature[5],
        "(importance:", round(dt_importance$importance[5], 2), ")"),
  "",
  "=== BUSINESS RECOMMENDATIONS ===",
  "",
  "1. PRICING STRATEGY:",
  "   - Use model predictions as baseline pricing",
  "   - Adjust based on local market conditions",
  paste("   - Expected accuracy: ±$", round(min(lm_mae, dt_mae), 2)),
  "",
  "2. FEATURE OPTIMIZATION:",
  "   - Focus on top 5 features identified",
  "   - Neighborhood selection is critical",
  "   - Property size directly impacts pricing power",
  "",
  "3. DATA-DRIVEN DECISIONS:",
  "   - Regular model retraining recommended",
  "   - Monitor prediction accuracy over time",
  "   - Collect feedback on pricing effectiveness",
  "",
  "4. COMPETITIVE POSITIONING:",
  "   - Benchmark against similar properties",
  "   - Consider seasonal adjustments",
  "   - Factor in unique amenities not in model",
  "",
  "MODEL FILES SAVED:",
  "  - outputs/linear_regression_model.rds",
  "  - outputs/decision_tree_model.rds",
  "  - outputs/predictions_sample.csv",
  "  - outputs/feature_importance.csv",
  "",
  "VISUALIZATIONS CREATED:",
  "  - visualizations/11_decision_tree.png",
  "  - visualizations/12_model_comparison_errors.png",
  "  - visualizations/13_model_comparison_performance.png",
  "  - visualizations/14_predicted_vs_actual.png",
  "  - visualizations/15_residuals_distribution.png",
  "  - visualizations/16_feature_importance.png",
  "",
  "NEXT STEPS:",
  "Run 05_predictions.R to generate predictions for new listings",
  sep = "\n"
)

write(performance_report, "outputs/model_performance_report.txt")
cat("✓ Performance report saved\n")

# ===== FINAL SUMMARY =====
cat("\n=== MODELING COMPLETE ===\n")
cat("\nBest Model Performance:\n")
best_model <- ifelse(lm_rmse < dt_rmse, "Linear Regression", "Decision Tree")
best_rmse <- min(lm_rmse, dt_rmse)
best_r2 <- max(lm_r2, dt_r2)

cat(paste("  Best Model:", best_model, "\n"))
cat(paste("  RMSE: $", round(best_rmse, 2), "\n"))
cat(paste("  R²:", round(best_r2, 4), "\n\n"))

cat("✓ All models trained and evaluated\n")
cat("✓ Visualizations created\n")
cat("✓ Performance metrics calculated\n")
cat("✓ Models saved for future use\n\n")

cat("Check outputs/ directory for detailed reports\n")
cat("Check visualizations/ directory for plots\n")
cat("Next: Run 05_predictions.R to make predictions on new data\n")
