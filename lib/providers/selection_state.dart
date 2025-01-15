import 'package:flutter/foundation.dart';

class SelectionState extends ChangeNotifier {
  final Set<String> _selectedCards = {};
  bool _isMultiSelectMode = false;

  bool get isMultiSelectMode => _isMultiSelectMode;
  Set<String> get selectedCards => Set.unmodifiable(_selectedCards);
  int get selectedCount => _selectedCards.length;

  void toggleSelection(String cardId) {
    if (_selectedCards.contains(cardId)) {
      _selectedCards.remove(cardId);
      if (_selectedCards.isEmpty) {
        _isMultiSelectMode = false;
      }
    } else {
      _selectedCards.add(cardId);
      _isMultiSelectMode = true;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedCards.clear();
    _isMultiSelectMode = false;
    notifyListeners();
  }

  bool isSelected(String cardId) => _selectedCards.contains(cardId);
}
