// lib/screens/filter_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String _selectedType = 'All Types';
  String _selectedQuality = 'All Quality';
  final List<String> _selectedGenres = [];
  final List<String> _selectedCountries = [];
  String _selectedReleaseYear = 'All Time';

  // Filter options
  final List<String> _types = ['All Types', 'Movies', 'TV Series'];
  final List<String> _qualities = ['All Quality', 'HD', 'SD', 'CAM'];
  final List<String> _genres = [
    'Mystery', 'Crime', 'Animation', 'Drama', 'Science Fiction',
    'Western', 'Comedy', 'TV Movie', 'Family', 'Action', 'Documentary',
    'Romance', 'Fantasy', 'Horror', 'Music', 'Thriller', 'War', 'Adventure',
    'History', 'Reality', 'Action & Adventure', 'Kids', 'War & Politics',
    'Talk', 'Sci-Fi & Fantasy', 'News', 'Soap', 'Biography'
  ];
  final List<String> _countries = [
    'Argentina', 'Australia', 'Austria', 'Belgium', 'Brazil', 'Canada',
    'China', 'Czech Republic', 'Denmark', 'Finland', 'France', 'Germany',
    'Hong Kong', 'Hungary', 'India', 'Ireland', 'Israel', 'Italy', 'Japan',
    'Luxembourg', 'Mexico', 'Netherlands', 'New Zealand', 'Norway', 'Poland',
    'Romania', 'Russia', 'South Africa', 'South Korea', 'Spain', 'Sweden',
    'Switzerland', 'Taiwan', 'Thailand', 'United Kingdom', 'United States of America'
  ];
  final List<String> _releaseYears = [
    'All Time', '2025', '2024', '2023', '2022', '2021', '2020', '2019',
    '2018', '2017', '2016', '2015', 'Older'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Types Section
              _buildSectionTitle('Types'),
              _buildTypeOptions(),
              
              const SizedBox(height: 24),
              
              // Quality Section
              _buildSectionTitle('Quality'),
              _buildQualityOptions(),
              
              const SizedBox(height: 24),
              
              // Genres Section
              _buildSectionTitle('Genres'),
              _buildGenreGrid(),
              
              const SizedBox(height: 24),
              
              // Countries Section
              _buildSectionTitle('Countries'),
              _buildCountryGrid(),
              
              const SizedBox(height: 24),
              
              // Releases Section
              _buildSectionTitle('Releases'),
              _buildReleaseYearOptions(),
              
              const SizedBox(height: 32),
              
              // Submit and Reset buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Return filter selections to the previous screen
                        Navigator.pop(context, {
                          'type': _selectedType,
                          'quality': _selectedQuality,
                          'genres': _selectedGenres,
                          'countries': _selectedCountries,
                          'releaseYear': _selectedReleaseYear
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.buttonTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = 'All Types';
                          _selectedQuality = 'All Quality';
                          _selectedGenres.clear();
                          _selectedCountries.clear();
                          _selectedReleaseYear = 'All Time';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textColorPrimary,
                        side: const BorderSide(color: AppTheme.textColorTertiary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textColorPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeOptions() {
    return Row(
      children: _types.map((type) {
        final isSelected = _selectedType == type;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilterChip(
            selected: isSelected,
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: AppTheme.buttonTextColor,
            backgroundColor: AppTheme.surfaceColor,
            label: Text(type),
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.buttonTextColor : AppTheme.textColorPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (selected) {
              setState(() {
                _selectedType = type;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQualityOptions() {
    return Row(
      children: _qualities.map((quality) {
        final isSelected = _selectedQuality == quality;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilterChip(
            selected: isSelected,
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: AppTheme.buttonTextColor,
            backgroundColor: AppTheme.surfaceColor,
            label: Text(quality),
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.buttonTextColor : AppTheme.textColorPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (selected) {
              setState(() {
                _selectedQuality = quality;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenreGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _genres.map((genre) {
        final isSelected = _selectedGenres.contains(genre);
        return FilterChip(
          selected: isSelected,
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: AppTheme.buttonTextColor,
          backgroundColor: AppTheme.surfaceColor,
          label: Text(genre),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.buttonTextColor : AppTheme.textColorPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedGenres.add(genre);
              } else {
                _selectedGenres.remove(genre);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCountryGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _countries.map((country) {
        final isSelected = _selectedCountries.contains(country);
        return FilterChip(
          selected: isSelected,
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: AppTheme.buttonTextColor,
          backgroundColor: AppTheme.surfaceColor,
          label: Text(country),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.buttonTextColor : AppTheme.textColorPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCountries.add(country);
              } else {
                _selectedCountries.remove(country);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildReleaseYearOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _releaseYears.map((year) {
        final isSelected = _selectedReleaseYear == year;
        return FilterChip(
          selected: isSelected,
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: AppTheme.buttonTextColor,
          backgroundColor: AppTheme.surfaceColor,
          label: Text(year),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.buttonTextColor : AppTheme.textColorPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (selected) {
            setState(() {
              _selectedReleaseYear = year;
            });
          },
        );
      }).toList(),
    );
  }
}
