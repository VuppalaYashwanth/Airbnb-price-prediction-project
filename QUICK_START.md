# Quick Start Guide

Get started with the Airbnb Price Prediction project in just a few steps!

## Prerequisites

- R (version 4.0 or higher)
- RStudio (recommended but optional)

## Installation & Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/airbnb-price-prediction.git
cd airbnb-price-prediction
```

### Step 2: Install Dependencies

Open R or RStudio and run:

```r
source("requirements.R")
```

This will automatically install all required packages:
- tidyverse
- ggplot2
- dplyr
- caret
- rpart & rpart.plot
- corrplot
- scales
- gridExtra
- Metrics

### Step 3: Run the Complete Analysis

```r
source("run_all.R")
```

This runs all 5 steps automatically:
1. Data generation (synthetic Airbnb data)
2. Data preprocessing and cleaning
3. Exploratory data analysis
4. Model training (Linear Regression & Decision Tree)
5. Predictions and recommendations

**Expected runtime:** 2-5 minutes

## Alternative: Run Steps Individually

If you prefer to run each step separately:

```r
# Step 1: Generate data
source("scripts/01_data_generation.R")

# Step 2: Preprocess data
source("scripts/02_data_preprocessing.R")

# Step 3: Exploratory analysis
source("scripts/03_exploratory_analysis.R")

# Step 4: Train models
source("scripts/04_modeling.R")

# Step 5: Generate predictions
source("scripts/05_predictions.R")
```

## Using Your Own Data

To use real Airbnb data instead of synthetic data:

1. **Skip Step 1** (data generation)

2. **Prepare your data** in CSV format with these columns:
   ```
   listing_id, neighborhood, property_type, room_type, bedrooms, 
   bathrooms, accommodates, num_amenities, host_is_superhost, 
   host_listings_count, host_years_active, number_of_reviews, 
   review_scores_rating, availability_365, minimum_nights, 
   instant_bookable, price
   ```

3. **Save as** `data/airbnb_data.csv`

4. **Run from Step 2:**
   ```r
   source("scripts/02_data_preprocessing.R")
   source("scripts/03_exploratory_analysis.R")
   source("scripts/04_modeling.R")
   source("scripts/05_predictions.R")
   ```

## What You'll Get

### Data Files
- `data/airbnb_data.csv` - Original dataset
- `data/airbnb_data_cleaned.csv` - Preprocessed dataset

### Models
- `outputs/linear_regression_model.rds` - Trained LR model
- `outputs/decision_tree_model.rds` - Trained DT model

### Reports
- `outputs/preprocessing_summary.txt`
- `outputs/eda_insights_report.txt`
- `outputs/model_performance_report.txt`
- `outputs/pricing_recommendations_report.txt`

### Visualizations (17 plots)
- Price distributions
- Location analysis
- Correlation matrices
- Model comparisons
- Feature importance
- And more!

## Troubleshooting

### Package Installation Issues

If packages fail to install:

```r
# Try installing individually
install.packages("tidyverse")
install.packages("caret")
# ... etc
```

### Memory Issues

For large datasets:

```r
# Increase memory limit (Windows)
memory.limit(size = 10000)

# Or sample your data
data_sample <- data %>% sample_n(10000)
```

### Path Issues

If scripts can't find files:

```r
# Set working directory
setwd("/path/to/airbnb-price-prediction")

# Then run scripts
source("run_all.R")
```

## Next Steps

1. **Explore the results:**
   - Check `visualizations/` for plots
   - Review reports in `outputs/`
   - Examine model performance

2. **Customize for your needs:**
   - Modify `05_predictions.R` to predict prices for your listings
   - Adjust model parameters in `04_modeling.R`
   - Add new features in `02_data_preprocessing.R`

3. **Contribute:**
   - See `CONTRIBUTING.md` for guidelines
   - Submit issues or pull requests
   - Share your improvements!

## Getting Help

- **Documentation:** Check `README.md` for detailed information
- **Issues:** Open a GitHub issue for bugs or questions
- **Examples:** See the generated reports for interpretation help

## RStudio Tips

If using RStudio:

1. **Open project:** File → Open Project → Select `.Rproj` file (create if needed)
2. **Run scripts:** Click "Source" button or Ctrl+Shift+S
3. **View plots:** Plots appear in the "Plots" pane
4. **Environment:** Check loaded data in "Environment" pane

## Project Structure

```
airbnb-price-prediction/
├── data/                    # Data files
├── scripts/                 # Analysis scripts (5 files)
├── outputs/                 # Results and models
├── visualizations/          # Generated plots
├── README.md               # Full documentation
├── requirements.R          # Package installer
├── run_all.R              # Master script
└── QUICK_START.md         # This file
```

## Resources

- [R Documentation](https://www.r-project.org/)
- [Tidyverse Guide](https://www.tidyverse.org/)
- [Caret Package](https://topepo.github.io/caret/)

Happy analyzing! 🎉
