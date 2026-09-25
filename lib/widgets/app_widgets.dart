import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label',
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Deduplicate items by item.value so DropdownButtonFormField never throws an assertion
    final seen = <T>{};
    final uniqueItems = <DropdownMenuItem<T>>[];
    for (final item in items) {
      if (item.value != null && seen.add(item.value as T)) {
        uniqueItems.add(item);
      }
    }

    final hasValue = value != null && seen.contains(value);
    final safeValue = hasValue ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            isExpanded: true,
            value: safeValue,
            items: uniqueItems.isEmpty ? null : uniqueItems,
            onChanged: uniqueItems.isEmpty ? null : onChanged,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
              hintText: uniqueItems.isEmpty ? 'No $label available' : 'Select $label',
            ),
            icon: const Icon(Icons.arrow_drop_down),
            dropdownColor: Theme.of(context).cardColor,
          ),
        ],
      ),
    );
  }
}

/// Google Chrome style typeahead search field:
/// User types and matching suggestions appear instantly underneath,
/// allowing easy selection while typing.
class GoogleSearchTypeAhead<T> extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final List<T> suggestions;
  final bool Function(T item, String query) filter;
  final String Function(T item) titleBuilder;
  final String? Function(T item)? subtitleBuilder;
  final ValueChanged<T> onSelected;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool isRequired;

  const GoogleSearchTypeAhead({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    required this.suggestions,
    required this.filter,
    required this.titleBuilder,
    this.subtitleBuilder,
    required this.onSelected,
    this.onChanged,
    this.prefixIcon,
    this.validator,
    this.isRequired = false,
    this.onAddNew,
    this.onAddNewText,
  });

  final VoidCallback? onAddNew;
  final String? onAddNewText;

  @override
  State<GoogleSearchTypeAhead<T>> createState() => _GoogleSearchTypeAheadState<T>();
}

class _GoogleSearchTypeAheadState<T> extends State<GoogleSearchTypeAhead<T>> {
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  List<T> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _filterList(widget.controller.text);
    } else {
      // Delay closing suggestions slightly so tap on item registers
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  void _onTextChanged() {
    if (_focusNode.hasFocus) {
      _filterList(widget.controller.text);
    }
  }

  void _filterList(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _filteredSuggestions = widget.suggestions.take(8).toList();
        _showSuggestions = _filteredSuggestions.isNotEmpty;
      });
    } else {
      final matches = widget.suggestions.where((item) => widget.filter(item, trimmed)).take(12).toList();
      setState(() {
        _filteredSuggestions = matches;
        _showSuggestions = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.isRequired)
                      const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (widget.onAddNew != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: widget.onAddNew,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 14, color: AppTheme.secondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            widget.onAddNewText ?? '+ Add',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            validator: widget.validator ??
                (widget.isRequired
                    ? (val) => (val == null || val.trim().isEmpty) ? 'Please enter or select ${widget.label}' : null
                    : null),
            onChanged: (val) {
              widget.onChanged?.call(val);
              _filterList(val);
            },
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Type to search ${widget.label}...',
              prefixIcon: Icon(widget.prefixIcon ?? Icons.search, size: 20, color: AppTheme.primaryColor),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged?.call('');
                        _filterList('');
                        setState(() {});
                      },
                    )
                  : const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
          ),
          if (_showSuggestions)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_filteredSuggestions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No matching results found',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _filteredSuggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final item = _filteredSuggestions[index];
                            final title = widget.titleBuilder(item);
                            final subtitle = widget.subtitleBuilder?.call(item);

                            return InkWell(
                              onTap: () {
                                widget.controller.text = title;
                                widget.onSelected(item);
                                setState(() => _showSuggestions = false);
                                _focusNode.unfocus();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search, size: 16, color: Colors.grey),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                          if (subtitle != null && subtitle.isNotEmpty)
                                            Text(
                                              subtitle,
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.north_west, size: 14, color: Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (widget.onAddNew != null) ...[
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      InkWell(
                        onTap: () {
                          setState(() => _showSuggestions = false);
                          _focusNode.unfocus();
                          widget.onAddNew!();
                        },
                        child: Container(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.08),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle, size: 16, color: AppTheme.secondaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.onAddNewText ?? '+ Add New',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isLoading;
  final Color? color;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(text),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: color != null ? ElevatedButton.styleFrom(backgroundColor: color) : null,
      icon: isLoading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : (icon != null ? Icon(icon) : const SizedBox.shrink()),
      label: Text(text),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;

  const SearchBarWidget({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.onClear,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: controller?.text.isNotEmpty == true
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: onClear,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (onFilterTap != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_list, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    this.title = 'No Records Found',
    this.message = 'There are no items to display at this moment.',
    this.icon = Icons.folder_open_outlined,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 54, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: AppButton(
                  text: buttonText!,
                  onPressed: onButtonPressed!,
                  icon: Icons.add,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (actionText != null && onActionTap != null)
            InkWell(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String content;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.content,
  });

  static Future<bool> show(BuildContext context, {required String title, required String content}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(title: title, content: content),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(100, 42),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('DELETE'),
        ),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final bool? isActive;

  const StatusBadge({
    super.key,
    required this.status,
    this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isAct = isActive ?? (status.toLowerCase() == 'active');
    final color = isAct ? const Color(0xFF2E7D32) : const Color(0xFF757575);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CompactActionTrailing extends StatelessWidget {
  final bool isActive;
  final String? statusText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompactActionTrailing({
    super.key,
    required this.isActive,
    this.statusText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final text = statusText ?? (isActive ? 'Active' : 'Inactive');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
            ),
          ),
        ),
        const SizedBox(width: 2),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32),
          tooltip: 'Actions',
          onSelected: (val) {
            if (val == 'edit') onEdit();
            if (val == 'delete') onDelete();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

