import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/services/search/bloc/search_bloc.dart';
import 'package:infinity_notes/services/search/bloc/search_event.dart';
import 'package:infinity_notes/utilities/generics/ui/ui_constants.dart';

class SearchBar extends StatefulWidget {
  final bool isExpanded;
  final Function(String)? onChanged;
  final VoidCallback? onToggleView;
  final bool isListView;
  final VoidCallback? onClose;

  const SearchBar({
    super.key,
    required this.isExpanded,
    this.onChanged,
    this.onToggleView,
    required this.isListView,
    this.onClose,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  Timer? _debounceTimer;

  final _focusNode = FocusNode();

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isSearching = _controller.text.isNotEmpty;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<SearchBloc>().add(SearchQueryChanged(_controller.text));
    });
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _cancelSearch() {
    _controller.clear();
    _focusNode.unfocus(); // Close keyboard
    context.read<SearchBloc>().add(const SearchCleared());
    setState(() {
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(102),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(153),
          width: 1.5,
        ),
        boxShadow: UIConstants.containerShadow,
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 22,
              shadows: UIConstants.iconShadow,
            ),
          ),

          // TextField
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: false,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
                shadows: UIConstants.textShadow,
              ),
              decoration: InputDecoration(
                hintText: "Search Notes",
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary.withAlpha(179),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  shadows: UIConstants.textShadow,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                alignLabelWithHint: true,
              ),
              onChanged: (text) => _onTextChanged(),
            ),
          ),
          _buildActionIcons(),
        ],
      ),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: _isSearching
          // Show CANCEL button when searching
              ? IconButton(
            key: const ValueKey('cancel_button'),
            icon: Icon(
              Icons.close,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimary,
              shadows: UIConstants.iconShadow,
            ),
            onPressed: _cancelSearch,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          )
          // Show TOGGLE VIEW button when not searching
              : (widget.onToggleView != null
              ? IconButton(
            key: const ValueKey('toggle_button'),
            icon: Icon(
              widget.isListView ? Icons.grid_view : Icons.view_agenda,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimary,
              shadows: UIConstants.iconShadow,
            ),
            onPressed: widget.onToggleView,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          )
              : const SizedBox.shrink(key: ValueKey('empty'))),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
