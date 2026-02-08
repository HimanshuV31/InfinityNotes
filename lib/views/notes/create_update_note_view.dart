import 'dart:async';
import 'package:flutter/material.dart';
import 'package:infinitynotes/services/auth/auth_service.dart';
import 'package:infinitynotes/services/cloud/cloud_note.dart';
import 'package:infinitynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:infinitynotes/services/notes_actions/share_note.dart';
import 'package:infinitynotes/utilities/ai/ai_helper.dart';
import 'package:infinitynotes/utilities/generics/ui/custom_app_bar.dart';
import 'package:infinitynotes/utilities/generics/ui/custom_toast.dart';
import 'package:infinitynotes/utilities/generics/ui/dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  late Color backgroundColor;
  late Color foregroundColor;

  CloudNote? _note;
  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  String _initialTitle = "";
  String _initialText = "";
  Timer? _debounce;
  List<DetectedLink> _detectedLinks = [];

  @override
  void initState() {
    super.initState();
    _notesService = FirebaseCloudStorage();
    _titleController = TextEditingController();
    _textController = TextEditingController();
    _setupListeners();
  }

  void _setupListeners() {
    _titleController.addListener(_onTitleChanged);
    _textController.addListener(_onTextChanged);
  }

  void _onTitleChanged() {
    setState(() {});
    _debouncedHandleChange();
  }

  void _onTextChanged() {
    setState(() {});
    _detectLinks();
    _debouncedHandleChange();
  }

  void _detectLinks() {
    final text = _textController.text;
    final linkRegex = RegExp(
      r'(https?://\S+|www\.\S+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\S*)',
      caseSensitive: false,
    );
    final foundLinks = <DetectedLink>[];
    for (final match in linkRegex.allMatches(text)) {
      final linkText = match.group(0)!;
      final processedUrl = linkText.startsWith('http')
          ? linkText
          : 'https://$linkText';
      foundLinks.add(
        DetectedLink(
          url: processedUrl,
          displayText: linkText,
          siteName: _extractSiteName(linkText),
        ),
      );
    }
    setState(() {
      _detectedLinks = foundLinks;
    });
    debugPrint("🔗 Detected ${_detectedLinks.length} links");
  }

  String _extractSiteName(String url) {
    try {
      String cleanUrl = url;
      if (cleanUrl.startsWith('www.')) {
        cleanUrl = cleanUrl.substring(4);
      }
      if (cleanUrl.startsWith('http://')) {
        cleanUrl = cleanUrl.substring(7);
      }
      if (cleanUrl.startsWith('https://')) {
        cleanUrl = cleanUrl.substring(8);
      }
      final firstSlash = cleanUrl.indexOf('/');
      if (firstSlash != -1) {
        cleanUrl = cleanUrl.substring(0, firstSlash);
      }
      final parts = cleanUrl.split('.');
      if (parts.length >= 2) {
        return parts[0].toUpperCase();
      }
      return cleanUrl.toUpperCase();
    } catch (e) {
      return 'WEBSITE';
    }
  }

  void _debouncedHandleChange() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _handleChange();
    });
  }

  List<String>? _getLinksFromDetectedLinks() {
    return _detectedLinks.isNotEmpty
        ? _detectedLinks.map((link) => link.url).toList()
        : null;
  }

  Future<void> _handleChange() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();
    if (_note != null && title == _initialTitle && text == _initialText) {
      return;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;
    if ((title.isNotEmpty || text.isNotEmpty) && _note == null) {
      await _createNote(userId, title, text);
      return;
    }
    if (_note != null && title.isEmpty && text.isEmpty) {
      final confirm = await showDeleteDialog(context: context);
      if (confirm) {
        await _notesService.deleteNote(documentId: _note!.documentId);
        if (!mounted) return;
        showCustomToast(context, "Note Deleted Successfully");
        if (!mounted) return;
        Navigator.of(context).pop();
      }
      return;
    }
    await _updateNote(title, text);
  }

  Future<void> _createNote(String userId, String title, String text) async {
    final links = _getLinksFromDetectedLinks();
    final newNote = await _notesService.createNewNote(
      ownerUserId: userId,
      title: title,
      text: text,
      links: links,
    );
    setState(() {
      _note = newNote;
      _initialTitle = title;
      _initialText = text;
    });
    debugPrint("📝 Created note with ${links?.length ?? 0} links");
  }

  Future<void> _updateNote(String title, String text) async {
    final links = _getLinksFromDetectedLinks();
    await _notesService.updateNote(
      documentId: _note!.documentId,
      title: title,
      text: text,
      links: links,
    );
    setState(() {
      _initialTitle = title;
      _initialText = text;
    });
    debugPrint("📝 Updated note with ${links?.length ?? 0} links");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is CloudNote) {
      _note = args;
      _titleController.text = _note!.title;
      _textController.text = _note!.text;
      _initialTitle = _note!.title;
      _initialText = _note!.text;
      if (_note!.hasLinks) {
        _detectedLinks = _note!.safeLinks
            .map(
              (url) => DetectedLink(
            url: url,
            displayText: url,
            siteName: _extractSiteName(url),
          ),
        )
            .toList();
      }
      _detectLinks();
    } else {
      _initialText = "";
      _initialTitle = "";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri);
      debugPrint("🔗 Launched: $uri");
    } catch (e) {
      debugPrint("🔗 Failed to launch: $e");
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'summarize':
        _handleSummarizeAction();
        break;
      case 'delete':
        await _handleDeleteAction();
        break;
      case 'export':
        _handleExportAction();
        break;
      case 'duplicate':
        await _handleDuplicateAction();
        break;
    }
  }

  void _handleSummarizeAction() {
    AIHelper.handleSummarizeAction(
      context: context,
      content: _textController.text,
      title: _titleController.text,
      onComplete: () =>
          showCustomToast(context, "Summary created successfully!"),
    );
  }

  Future<void> _handleDeleteAction() async {
    if (_note != null) {
      final confirm = await showDeleteDialog(context: context);
      if (confirm) {
        await _notesService.deleteNote(documentId: _note!.documentId);
        if (!mounted) return;
        showCustomToast(context, "Note Deleted Successfully");
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } else {
      // Note doesn't exist yet, just clear fields
      _titleController.clear();
      _textController.clear();
      showCustomToast(context, "Content cleared");
    }
  }


  void _handleExportAction() {
    if (_titleController.text.isEmpty && _textController.text.isEmpty) {
      showCustomToast(context, "Nothing to export");
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download, color: Colors.blue),
            SizedBox(width: 8),
            Text('Export Options'),
          ],
        ),
        content: const Text('Choose how you want to export this note:'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _saveAsNewNote();
            },
            icon: const Icon(Icons.note_add, color: Colors.green, size: 20),
            label: const Text(
              'Save as New Note',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showCustomToast(context, "Exported as plain text");
            },
            icon: const Icon(Icons.text_snippet, size: 20),
            label: const Text('Export as Text'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showCustomToast(context, "Exported as markdown");
            },
            icon: const Icon(Icons.code, size: 20),
            label: const Text('Export as Markdown'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAsNewNote() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();
    final links = _getLinksFromDetectedLinks();
    try {
      final currentUser = AuthService.firebase().currentUser!;
      final newTitle = title.isNotEmpty ? "$title (Copy)" : "Untitled (Copy)";

      await _notesService.createNewNote(
        ownerUserId: currentUser.id,
        title: newTitle,
        text: text,
        links: links,
      );
      if (!mounted) return;
      showCustomToast(context, "Note saved as: \"$newTitle\"");
    } catch (e) {
      showCustomToast(context, "Failed to save note copy");
    }
  }

  Future<void> _handleDuplicateAction() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();

    if (title.isEmpty && text.isEmpty) {
      showCustomToast(context, "Nothing to duplicate");
      return;
    }
    try {
      final currentUser = AuthService.firebase().currentUser!;
      final duplicatedTitle =
      title.isNotEmpty ? "$title (Copy)" : "Untitled (Copy)";
      final links = _getLinksFromDetectedLinks();
      await _notesService.createNewNote(
        ownerUserId: currentUser.id,
        title: duplicatedTitle,
        text: text,
        links: links,
      );
      if (!mounted) return;
      showCustomToast(context, "Note duplicated successfully!");
    } catch (e) {
      showCustomToast(context, "Failed to duplicate note");
    }
  }

  bool get _canSummarize => AIHelper.canSummarizeContent(_textController.text);

  @override
  Widget build(BuildContext context) {
    backgroundColor = Theme.of(context).colorScheme.primary;
    foregroundColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      appBar: CustomAppBar(
        title: _titleController.text.isEmpty
            ? "New Note"
            : _titleController.text,
        themeColor: backgroundColor,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor!,
        foregroundColor: foregroundColor,
        actions: [
          IconButton(
            onPressed: () async {
              if (_note == null ||
                  (_titleController.text.isEmpty &&
                      _textController.text.isEmpty)) {
                await showCannotShareEmptyNoteDialog(context);
              } else {
                shareNote(context: context, note: _note!);
              }
            },
            icon: Icon(Icons.share, color: foregroundColor),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: Icon(Icons.more_vert, color: foregroundColor),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "summarize",
                enabled: _canSummarize,
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: _canSummarize ? Colors.blue : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "AI Summary",
                      style: TextStyle(
                        color: _canSummarize ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: "export",
                enabled: _titleController.text.isNotEmpty ||
                    _textController.text.isNotEmpty,
                child: Row(
                  children: [
                    Icon(
                      Icons.file_download,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    const Text("Export"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "duplicate",
                enabled: _titleController.text.isNotEmpty ||
                    _textController.text.isNotEmpty,
                child: Row(
                  children: [
                    Icon(
                      Icons.copy,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    const Text("Duplicate"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: "delete",
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _note != null ? "Delete Note" : "Clear Content",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Title",
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 18.0),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  hintText: "Write your note here... Links will appear below when detected!",
                ),
              ),
            ),
            if (_detectedLinks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.link, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    "Detected Links (${_detectedLinks.length})",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.1,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _detectedLinks.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final link = _detectedLinks[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Icon(
                            Icons.language,
                            color: Colors.blue.shade700,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          link.siteName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          link.displayText,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.open_in_new,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          size: 16,
                        ),
                        onTap: () => _launchURL(link.url),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DetectedLink {
  final String url;
  final String displayText;
  final String siteName;

  DetectedLink({
    required this.url,
    required this.displayText,
    required this.siteName,
  });
}
