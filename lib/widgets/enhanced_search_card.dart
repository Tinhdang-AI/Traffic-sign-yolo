import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/autocomplete_service.dart';
import '../services/location_storage_service.dart';
import '../theme/app_colors.dart';

class EnhancedSearchCard extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;
  final Function(String)? onSuggestionSelected;

  const EnhancedSearchCard({
    Key? key,
    required this.controller,
    required this.isLoading,
    required this.onSearch,
    this.onSuggestionSelected,
  }) : super(key: key);

  @override
  State<EnhancedSearchCard> createState() => _EnhancedSearchCardState();
}

class _EnhancedSearchCardState extends State<EnhancedSearchCard> {
  late AutocompleteService _autocompleteService;
  late LocationStorageService _storageService;
  List<AutocompleteResult> _suggestions = [];
  List<SavedLocation> _recentLocations = [];
  bool _showSuggestions = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _autocompleteService = AutocompleteService();
    _storageService = LocationStorageService();
    _loadRecentLocations();
    widget.controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _autocompleteService.dispose();
    widget.controller.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _loadRecentLocations() async {
    try {
      final recent = await _storageService.getRecent(limit: 5);
      setState(() {
        _recentLocations = recent;
      });
    } catch (e) {
      print('Error loading recent locations: $e');
    }
  }

  void _onSearchChanged() {
    final query = widget.controller.text.trim();

    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
      return;
    }

    _fetchSuggestions(query);
  }

  void _fetchSuggestions(String query) async {
    setState(() => _isSearching = true);

    try {
      final results = await _autocompleteService.getSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectSuggestion(String text) {
    widget.controller.text = text;
    setState(() => _showSuggestions = false);
    widget.onSuggestionSelected?.call(text);
    widget.onSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập điểm đến...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => widget.onSearch(),
                ),
              ),
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {
                  if (!widget.isLoading) {
                    widget.onSearch();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.isLoading ? Icons.hourglass_bottom : Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Suggestions / Recent locations
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  title: Text(
                    suggestion.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                  onTap: () => _selectSuggestion(suggestion.displayName),
                );
              },
            ),
          )
        else if (!_showSuggestions && _recentLocations.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Gần đây',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _recentLocations.length,
                    itemBuilder: (context, index) {
                      final location = _recentLocations[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          location.isFavorite ? Icons.favorite : Icons.history,
                          color: location.isFavorite ? Colors.red : Colors.grey,
                          size: 18,
                        ),
                        title: Text(
                          location.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () => _selectSuggestion(location.name),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
