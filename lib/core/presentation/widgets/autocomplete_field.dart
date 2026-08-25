import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_sizing.dart';

/// Inline autocomplete — a labelled text field that, after a short pause in
/// typing, shows [search]'s matches directly below it (no modal/sheet).
/// Shared by every workflow that picks one item from a searchable remote
/// list (nationality, agent, guide, ...) by typing rather than browsing.
class AutocompleteField<T> extends StatefulWidget {
  final String label;
  final String hintText;
  final String? initialText;
  final Future<List<T>> Function(String query) search;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onSelected;
  final Duration debounce;

  const AutocompleteField({
    super.key,
    required this.label,
    required this.search,
    required this.itemLabel,
    required this.onSelected,
    this.hintText = 'Search…',
    this.initialText,
    this.debounce = const Duration(milliseconds: 300),
  });

  @override
  State<AutocompleteField<T>> createState() => _AutocompleteFieldState<T>();
}

class _AutocompleteFieldState<T> extends State<AutocompleteField<T>> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;
  List<T> _suggestions = const [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _isLoading = true);
    List<T> results;
    try {
      results = await widget.search(query);
    } catch (_) {
      // A failed lookup (network error, timeout, ...) must not leave the
      // spinner stuck forever — fall back to "no matches" like an empty
      // result, same as any other unsuccessful search.
      results = const [];
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _suggestions = results;
    });
  }

  void _select(T item) {
    _debounceTimer?.cancel();
    final label = widget.itemLabel(item);
    _controller.value = TextEditingValue(
      text: label,
      selection: TextSelection.collapsed(offset: label.length),
    );
    setState(() => _suggestions = const []);
    widget.onSelected(item);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_isLoading || _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xxs),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(widget.itemLabel(item)),
                        onTap: () => _select(item),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
