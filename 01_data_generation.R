# 01_data_generation.R
# Generate synthetic Airbnb listing data for analysis

# Load required libraries
library(tidyverse)

# Set seed for reproducibility
set.seed(123)

# Number of listings to generate
n_listings <- 1000

# Generate synthetic Airbnb data
cat("Generating synthetic Airbnb dataset...\n")

# Define neighborhoods with different price ranges
neighborhoods <- c(
  "Downtown", "Beach Area", "Suburbs", "Historic District", 
  "Business District", "University Area", "Airport Area", "Waterfront"
)

# Property types
property_types <- c("Apartment", "House", "Condo", "Loft", "Townhouse")

# Room types
room_types <- c("Entire home/apt", "Private room", "Shared room")

# Generate data
airbnb_data <- tibble(
  listing_id = 1:n_listings,
  
  # Location features
  neighborhood = sample(neighborhoods, n_listings, replace = TRUE, 
                       prob = c(0.15, 0.12, 0.18, 0.10, 0.12, 0.15, 0.08, 0.10)),
  
  # Property characteristics
  property_type = sample(property_types, n_listings, replace = TRUE,
                        prob = c(0.35, 0.25, 0.20, 0.10, 0.10)),
  room_type = sample(room_types, n_listings, replace = TRUE,
                    prob = c(0.65, 0.30, 0.05)),
  
  bedrooms = sample(1:5, n_listings, replace = TRUE, 
                   prob = c(0.35, 0.30, 0.20, 0.10, 0.05)),
  bathrooms = sample(c(1, 1.5, 2, 2.5, 3), n_listings, replace = TRUE,
                    prob = c(0.30, 0.25, 0.25, 0.15, 0.05)),
  accommodates = pmax(2, rnorm(n_listings, mean = 4, sd = 2)),
  
  # Amenities (number of amenities)
  num_amenities = sample(5:30, n_listings, replace = TRUE),
  
  # Host features
  host_is_superhost = sample(c("Yes", "No"), n_listings, replace = TRUE, 
                            prob = c(0.25, 0.75)),
  host_listings_count = pmax(1, rpois(n_listings, lambda = 3)),
  host_years_active = sample(1:10, n_listings, replace = TRUE),
  
  # Reviews
  number_of_reviews = pmax(0, rpois(n_listings, lambda = 25)),
  review_scores_rating = pmin(5, pmax(3, rnorm(n_listings, mean = 4.5, sd = 0.5))),
  
  # Availability
  availability_365 = sample(0:365, n_listings, replace = TRUE),
  minimum_nights = sample(c(1, 2, 3, 7, 30), n_listings, replace = TRUE,
                         prob = c(0.40, 0.25, 0.15, 0.15, 0.05)),
  
  # Additional features
  instant_bookable = sample(c("Yes", "No"), n_listings, replace = TRUE,
                           prob = c(0.60, 0.40))
)

# Generate realistic prices based on features
# Base price
base_price <- 80

# Calculate price with realistic factors
airbnb_data <- airbnb_data %>%
  mutate(
    # Price factors
    neighborhood_factor = case_when(
      neighborhood == "Downtown" ~ 1.4,
      neighborhood == "Beach Area" ~ 1.5,
      neighborhood == "Waterfront" ~ 1.45,
      neighborhood == "Historic District" ~ 1.25,
      neighborhood == "Business District" ~ 1.30,
      neighborhood == "University Area" ~ 0.95,
      neighborhood == "Suburbs" ~ 0.90,
      neighborhood == "Airport Area" ~ 0.85,
      TRUE ~ 1.0
    ),
    
    property_factor = case_when(
      property_type == "House" ~ 1.3,
      property_type == "Loft" ~ 1.25,
      property_type == "Condo" ~ 1.1,
      property_type == "Townhouse" ~ 1.15,
      property_type == "Apartment" ~ 1.0,
      TRUE ~ 1.0
    ),
    
    room_factor = case_when(
      room_type == "Entire home/apt" ~ 1.5,
      room_type == "Private room" ~ 1.0,
      room_type == "Shared room" ~ 0.6,
      TRUE ~ 1.0
    ),
    
    # Calculate price
    price = base_price * 
      neighborhood_factor *
      property_factor *
      room_factor *
      (1 + 0.3 * bedrooms) *
      (1 + 0.15 * bathrooms) *
      (1 + 0.01 * num_amenities) *
      ifelse(host_is_superhost == "Yes", 1.15, 1.0) *
      (1 + 0.05 * pmin(review_scores_rating - 3, 2)) *
      (1 + rnorm(n_listings, 0, 0.15)) # Add random variation
  ) %>%
  # Remove intermediate calculation columns
  select(-neighborhood_factor, -property_factor, -room_factor) %>%
  # Round price
  mutate(
    price = round(pmax(30, price), 2),
    accommodates = round(accommodates),
    review_scores_rating = round(review_scores_rating, 2)
  ) %>%
  # Add some missing values to make it realistic
  mutate(
    review_scores_rating = ifelse(number_of_reviews == 0, NA, review_scores_rating),
    review_scores_rating = ifelse(runif(n_listings) < 0.05, NA, review_scores_rating),
    host_years_active = ifelse(runif(n_listings) < 0.03, NA, host_years_active)
  )

# Save the data
cat("Saving data to data/airbnb_data.csv...\n")
write_csv(airbnb_data, "data/airbnb_data.csv")

# Create data dictionary
data_dictionary <- "
AIRBNB DATA DICTIONARY
======================

listing_id: Unique identifier for each listing
neighborhood: Geographic area where the property is located
property_type: Type of property (Apartment, House, Condo, Loft, Townhouse)
room_type: Type of room available (Entire home/apt, Private room, Shared room)
bedrooms: Number of bedrooms
bathrooms: Number of bathrooms
accommodates: Maximum number of guests the property can accommodate
num_amenities: Total number of amenities offered
host_is_superhost: Whether the host has superhost status (Yes/No)
host_listings_count: Number of listings the host has
host_years_active: Number of years the host has been active on Airbnb
number_of_reviews: Total number of reviews received
review_scores_rating: Average review rating (1-5 scale)
availability_365: Number of days available for booking in the next 365 days
minimum_nights: Minimum number of nights required for booking
instant_bookable: Whether instant booking is available (Yes/No)
price: Nightly price in USD

Note: This is synthetic data generated for demonstration purposes.
"

write(data_dictionary, "data/data_dictionary.txt")

# Print summary
cat("\n=== Data Generation Complete ===\n")
cat(paste("Total listings generated:", nrow(airbnb_data), "\n"))
cat(paste("Total features:", ncol(airbnb_data), "\n"))
cat("\nData saved to: data/airbnb_data.csv\n")
cat("Data dictionary saved to: data/data_dictionary.txt\n")

# Display sample
cat("\n=== Sample Data (First 10 rows) ===\n")
print(head(airbnb_data, 10))

# Basic statistics
cat("\n=== Price Statistics ===\n")
cat(paste("Mean price: $", round(mean(airbnb_data$price), 2), "\n"))
cat(paste("Median price: $", round(median(airbnb_data$price), 2), "\n"))
cat(paste("Min price: $", round(min(airbnb_data$price), 2), "\n"))
cat(paste("Max price: $", round(max(airbnb_data$price), 2), "\n"))
cat(paste("Standard deviation: $", round(sd(airbnb_data$price), 2), "\n"))
