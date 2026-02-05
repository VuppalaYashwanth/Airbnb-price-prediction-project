# Contributing to Airbnb Price Prediction

Thank you for your interest in contributing to this project! We welcome contributions from the community.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion for improvement:

1. Check if the issue already exists in the [Issues](https://github.com/yourusername/airbnb-price-prediction/issues) section
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Your R version and OS

### Proposing Changes

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/airbnb-price-prediction.git
   cd airbnb-price-prediction
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Update documentation if needed

4. **Test your changes**
   ```r
   source("run_all.R")
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add: brief description of changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Wait for review and feedback

## Development Guidelines

### Code Style

- Use meaningful variable names
- Follow tidyverse style guide
- Add comments for complex operations
- Keep functions focused and modular

### Project Structure

When adding new features:
- Scripts go in `scripts/`
- Data files in `data/`
- Outputs in `outputs/`
- Visualizations in `visualizations/`

### Adding New Models

If adding a new predictive model:

1. Create a new script or modify `04_modeling.R`
2. Follow the existing pattern:
   - Train the model
   - Generate predictions
   - Calculate metrics (RMSE, R², MAE, MAPE)
   - Create visualizations
   - Save model and results

3. Update documentation:
   - Add to README.md
   - Update model comparison section
   - Document hyperparameters

### Adding New Features

If adding new data features:

1. Modify `01_data_generation.R` to include new features
2. Update `02_data_preprocessing.R` for feature engineering
3. Update `data_dictionary.txt`
4. Ensure backward compatibility

### Testing

Before submitting a PR:

- Run the complete pipeline: `source("run_all.R")`
- Verify all outputs are generated correctly
- Check that visualizations render properly
- Test with different R versions if possible

## Areas for Contribution

We especially welcome contributions in these areas:

### High Priority
- Additional ML models (Random Forest, XGBoost, Neural Networks)
- Time series forecasting for seasonal pricing
- Hyperparameter tuning with cross-validation
- Interactive Shiny dashboard
- Real-world data integration guide

### Medium Priority
- Additional visualizations
- Performance optimizations
- Better error handling
- Unit tests
- Docker containerization

### Documentation
- Improve installation instructions
- Add video tutorials
- Create Jupyter notebook version
- Translate documentation

### Data Science
- Feature engineering ideas
- Advanced EDA techniques
- Model interpretability (SHAP, LIME)
- A/B testing framework

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Welcome newcomers

## Questions?

If you have questions about contributing:
- Open an issue with the "question" label
- Check existing issues and discussions
- Reach out to maintainers

## Recognition

Contributors will be acknowledged in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for helping improve this project! 🎉
