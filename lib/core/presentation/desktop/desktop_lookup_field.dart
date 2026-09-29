import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../test_ids.dart';
import '../widgets/test_id.dart';
import 'desktop_tokens.dart';

/// Searchable single-pick field (POS Desktop mockup screen 13) — the shell
/// shared by the customer form's Flight code / Nationality / Customer type /
/// Agent code / Sub agent code.
///
/// The list opens from the magnifier or by typing (never a separate page),
/// re-queries [search] on every keystroke (debounced), and pre-selects the
/// first match. ↑↓ move, Enter picks and moves focus to the next field, Esc
/// closes and restores the committed [value]. Enter on a code typed in full
/// commits the exact match without opening the list.
class DesktopLookupField<T> extends StatefulWidget {
  final String id;
  final String label;
  final bool required;
  final T? value;
  final Future<List<T>> Function(String query) search;
  final String Function(T item) code;
  final String Function(T item) name;
  final String Function(T item)? trailing;
  final ValueChanged<T> onSelected;
  final bool enabled;

  /// Shown under the field while it is disabled, e.g. why it is.
  final String? disabledHint;
  final String hint;
  final Duration debounce;

  const DesktopLookupField({
    super.key,
    required this.id,
    required this.label,
    required this.search,
    required this.code,
    required this.name,
    required this.onSelected,
    this.value,
    this.trailing,
    this.required = false,
    this.enabled = true,
    this.disabledHint,
    this.hint = 'Type a code or name',
    this.debounce = const Duration(milliseconds: 300),
  });

  @override
  State<DesktopLookupField<T>> createState() => _DesktopLookupFieldState<T>();
}

class _DesktopLookupFieldState<T> extends State<DesktopLookupField<T>> {
  final _controller = TextEditingController();
  late final _focusNode = FocusNode(onKeyEvent: _onKey);
  final _magnifierFocus = FocusNode(skipTraversal: true);
  final _overlay = OverlayPortalController();
  final _link = LayerLink();
  Timer? _debounce;
  int _request = 0;
  bool _loading = false;
  List<T> _results = const [];
  int _highlight = -1;
  double _width = 0;

  @override
  void initState() {
    super.initState();
    _controller.text = _committedText;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DesktopLookupField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compared by code: callers may rebuild an equal value on every build.
    final oldValue = oldWidget.value;
    final oldCode = oldValue == null ? '' : oldWidget.code(oldValue);
    if (oldCode != _committedText && !_overlay.isShowing) {
      _controller.text = _committedText;
    }
    if (!widget.enabled && _overlay.isShowing) _close();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _magnifierFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  String get _committedText {
    final value = widget.value;
    return value == null ? '' : widget.code(value);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _overlay.isShowing) _cancel();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _runSearch(text));
  }

  Future<void> _runSearch(String query) async {
    _debounce?.cancel();
    final request = ++_request;
    setState(() => _loading = true);
    _overlay.show();
    List<T> results;
    try {
      results = await widget.search(query.trim());
    } catch (_) {
      // A failed lookup reads as "no matches" rather than a stuck spinner.
      results = const [];
    }
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      _results = results;
      _highlight = results.isEmpty ? -1 : 0;
    });
  }

  Future<void> _commitExact() async {
    final typed = _controller.text.trim();
    if (typed.isEmpty) return;
    _debounce?.cancel();
    final request = ++_request;
    List<T> results;
    try {
      results = await widget.search(typed);
    } catch (_) {
      results = const [];
    }
    if (!mounted || request != _request) return;
    for (final item in results) {
      if (widget.code(item).toUpperCase() == typed.toUpperCase()) {
        _pick(item);
        return;
      }
    }
    setState(() {
      _results = results;
      _highlight = results.isEmpty ? -1 : 0;
    });
    _overlay.show();
  }

  void _pick(T item) {
    _debounce?.cancel();
    _request++;
    final code = widget.code(item);
    _controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    _close();
    widget.onSelected(item);
    _focusNode.nextFocus();
  }

  void _close() {
    if (_overlay.isShowing) _overlay.hide();
    if (mounted) {
      setState(() {
        _loading = false;
        _results = const [];
        _highlight = -1;
      });
    }
  }

  /// Esc / focus lost: close without changing the committed value.
  void _cancel() {
    _debounce?.cancel();
    _request++;
    _controller.text = _committedText;
    _close();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final open = _overlay.isShowing;
    if (key == LogicalKeyboardKey.arrowDown && open && _results.isNotEmpty) {
      setState(() => _highlight = (_highlight + 1) % _results.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp && open && _results.isNotEmpty) {
      setState(
        () => _highlight = (_highlight - 1 + _results.length) % _results.length,
      );
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final pending = _debounce?.isActive ?? false;
      if (open && !pending && !_loading && _highlight >= 0) {
        _pick(_results[_highlight]);
      } else {
        _commitExact();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && open) {
      _cancel();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final focused = _focusNode.hasFocus;
    return TestId(
      widget.id,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.label.toUpperCase()}${widget.required ? ' *' : ''}',
            style: DesktopText.fieldLabel,
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              _width = constraints.maxWidth;
              return CompositedTransformTarget(
                link: _link,
                child: OverlayPortal(
                  controller: _overlay,
                  overlayChildBuilder: _buildList,
                  child: SizedBox(
                    height: DesktopMetrics.fieldHeight,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: enabled,
                      onChanged: _onChanged,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: enabled ? widget.hint : null,
                        filled: true,
                        fillColor: enabled
                            ? AppColors.surface
                            : AppColors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        border: _border(AppColors.line, 1),
                        enabledBorder: _border(const Color(0xFFD8DDE5), 1),
                        disabledBorder: _border(AppColors.line, 1),
                        focusedBorder: _border(AppColors.goldMuted, 2),
                        // Out of the tab order, so Enter-to-pick moves on
                        // to the next field rather than to this button.
                        suffixIcon: TestId(
                          DesktopLookupIds.open(widget.id),
                          child: IconButton(
                            focusNode: _magnifierFocus,
                            tooltip: 'Search ${widget.label.toLowerCase()}',
                            icon: Icon(
                              Icons.search,
                              size: 18,
                              color: focused
                                  ? AppColors.goldDark
                                  : AppColors.hintText,
                            ),
                            onPressed: enabled
                                ? () {
                                    _focusNode.requestFocus();
                                    _runSearch(_controller.text);
                                  }
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (!enabled && widget.disabledHint != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.disabledHint!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A5A16)),
            ),
          ],
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _buildList(BuildContext context) {
    final footer = _loading
        ? 'Searching…'
        : _results.isEmpty
        ? 'No matches'
        : '${_results.length} match${_results.length == 1 ? '' : 'es'}'
              ' · Enter to pick';
    return Positioned(
      width: _width,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        offset: const Offset(0, 4),
        // Taps on the list count as inside the field, so picking an option
        // doesn't first blur (and close) it.
        child: TextFieldTapRegion(
          child: TestId(
            DesktopLookupIds.list(widget.id),
            child: Material(
              color: AppColors.surface,
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loading)
                    const LinearProgressIndicator(minHeight: 2)
                  else if (_results.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        itemBuilder: (context, i) => _option(i),
                      ),
                    ),
                  Container(
                    color: const Color(0xFFFAFBFC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      footer,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _option(int i) {
    final item = _results[i];
    final selected = i == _highlight;
    final trailing = widget.trailing?.call(item) ?? '';
    return TestId(
      DesktopLookupIds.option(widget.id, i),
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          canRequestFocus: false,
          onTap: () => _pick(item),
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFBF8F1) : null,
              border: Border(
                left: BorderSide(
                  color: selected ? AppColors.goldMuted : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    widget.code(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.name(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: selected
                          ? AppColors.textPrimary
                          : const Color(0xFF3A414C),
                    ),
                  ),
                ),
                if (trailing.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailing,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
