// lib/screens/filter_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

class FilterScreen extends StatefulWidget {
  final ApiService apiService;

  const FilterScreen({
    required this.apiService,
    Key? key,
  }) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late final ApiService _apiService;
  String _selectedType = 'All Types';
  String _selectedQuality = 'All Quality';
  final List<String> _selectedGenres = [];
  final List<String> _selectedCountries = [];
  String _selectedReleaseYear = 'All Time';

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _loadFilterOptions();
  }

  // Filter options with default values
  final List<String> _types = ['All Types', 'Movies', 'TV Series'];
  final List<String> _qualities = ['All Quality', 'HD', 'SD', 'CAM'];
  List<String> _genres = [];
  List<String> _countries = [];
  List<String> _releaseYears = [
    'All Time', '2025', '2024', '2023', '2022', '2021', '2020', '2019',
    '2018', '2017', '2016', '2015', 'Older'
  ];
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _loadFilterOptions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Connect to metadata WebSocket for filter options
      await for (final data in _apiService.connectToContentWebSocket(type: 'metadata')) {
        if (data is Map<String, dynamic>) {
          setState(() {
            if (data['genres'] is List) {
              _genres = List<String>.from(data['genres']);
            }
            if (data['countries'] is List) {
              _countries = List<String>.from(data['countries']);
            }
            _isLoading = false;
          });
          break; // Exit after receiving the first valid response
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load filter options: $e';
        _isLoading = false;
      });
      print('Error loading filter options: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Apply filters and return filtered content
              final filters = {
                'type': _selectedType != 'All Types' ? _selectedType.toLowerCase() : null,
                'quality': _selectedQuality != 'All Quality' ? _selectedQuality.toLowerCase() : null,
                'genres': _selectedGenres.isNotEmpty ? _selectedGenres : null,
                'countries': _selectedCountries.isNotEmpty ? _selectedCountries : null,
                'year': _selectedReleaseYear != 'All Time' ? _selectedReleaseYear : null,
              };
              
              // Remove null values
              filters.removeWhere((key, value) => value == null);
              
              Navigator.pop(context, filters);
            },
            child: Text(
              'Apply',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFilterOptions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
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
