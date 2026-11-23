import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/material_item.dart';
import 'material_providers.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  final _searchController = TextEditingController();
  bool _bookmarksOnly = false;
  bool _isUploading = false;
  String? _subjectFilter;
  String _sortOrder = 'newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).value?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (ref.watch(authStateProvider).value?.isGuest == true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning materials')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 52),
                SizedBox(height: 16),
                Text(
                  'Materials need Firebase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'You can create and study flashcards offline. Configure '
                  'Firebase to upload, bookmark, and browse shared files.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final materials = ref.watch(materialsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning materials'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort materials',
            initialValue: _sortOrder,
            onSelected: (value) => setState(() => _sortOrder = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest first')),
              PopupMenuItem(value: 'alphabetical', child: Text('A to Z')),
            ],
          ),
          IconButton(
            tooltip: _bookmarksOnly ? 'Show all materials' : 'Show bookmarks',
            onPressed: () => setState(() => _bookmarksOnly = !_bookmarksOnly),
            icon: Icon(
              _bookmarksOnly ? Icons.bookmark_rounded : Icons.bookmark_border,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : () => _upload(userId),
        icon: const Icon(Icons.upload_file_rounded),
        label: Text(_isUploading ? 'Uploading…' : 'Upload material'),
      ),
      body: materials.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorState(
          onRetry: () => ref.invalidate(materialsProvider(userId)),
        ),
        data: (items) {
          final subjects =
              items
                  .map((item) => item.subject)
                  .where((subject) => subject.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final search = _searchController.text.trim().toLowerCase();
          final visibleItems =
              items.where((item) {
                if (_bookmarksOnly && !item.isBookmarked) return false;
                if (_subjectFilter != null && item.subject != _subjectFilter) {
                  return false;
                }
                if (search.isEmpty) return true;
                return item.title.toLowerCase().contains(search) ||
                    item.subject.toLowerCase().contains(search) ||
                    item.description.toLowerCase().contains(search);
              }).toList()..sort(
                (a, b) => _sortOrder == 'alphabetical'
                    ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
                    : b.createdAt.compareTo(a.createdAt),
              );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search title, topic, or subject',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              if (subjects.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All subjects'),
                        selected: _subjectFilter == null,
                        onSelected: (selected) =>
                            setState(() => _subjectFilter = null),
                      ),
                      ...subjects.map(
                        (subject) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(subject),
                            selected: _subjectFilter == subject,
                            onSelected: (selected) => setState(
                              () => _subjectFilter = selected ? subject : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: visibleItems.isEmpty
                    ? (items.isEmpty
                          ? _EmptyMaterials(
                              bookmarkedOnly: _bookmarksOnly,
                              onUpload: () => _upload(userId),
                            )
                          : const Center(
                              child: Text('No materials match those filters.'),
                            ))
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(materialsProvider(userId)),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          itemCount: visibleItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = visibleItems[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  8,
                                  8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(
                                    item.fileType == 'pdf'
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.description_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.subject.isEmpty ? 'No subject' : item.subject}'
                                  ' · ${item.fileType.toUpperCase()}'
                                  ' · ${_formatSize(item.fileSize)}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'bookmark') {
                                      await _toggleBookmark(userId, item);
                                    } else if (action == 'open') {
                                      await _openMaterial(item);
                                    } else if (action == 'delete' &&
                                        item.uploadedBy == userId &&
                                        await _confirmDelete(item)) {
                                      await _deleteMaterial(userId, item);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'open',
                                      child: Text('Open / download'),
                                    ),
                                    PopupMenuItem(
                                      value: 'bookmark',
                                      child: Text(
                                        item.isBookmarked
                                            ? 'Remove bookmark'
                                            : 'Bookmark',
                                      ),
                                    ),
                                    if (item.uploadedBy == userId)
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete upload'),
                                      ),
                                  ],
                                ),
                                onTap: () => _openMaterial(item),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _upload(String userId) async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    PlatformFile? selectedFile;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Upload learning material'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const ['pdf', 'txt'],
                      );
                      if (result.isNotEmpty) {
                        setDialogState(() => selectedFile = result.first);
                      }
                    },
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(selectedFile?.name ?? 'Choose PDF or TXT'),
                  ),
                  if (selectedFile != null)
                    Text(
                      '${selectedFile!.lengthSync() == null ? 'Selected' : _formatSize(selectedFile!.lengthSync()!)}'
                      ' · max 20 MB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
    final title = titleController.text;
    final subject = subjectController.text;
    final description = descriptionController.text;
    titleController.dispose();
    subjectController.dispose();
    descriptionController.dispose();
    if (confirmed != true) return;
    final file = selectedFile;
    if (title.trim().isEmpty || subject.trim().isEmpty || file == null) {
      _showMessage('Add a title, subject, and a PDF or TXT file.');
      return;
    }
    setState(() => _isUploading = true);
    try {
      await ref
          .read(materialRepositoryProvider)
          .upload(
            userId: userId,
            title: title,
            subject: subject,
            description: description,
            file: file,
          );
      ref.invalidate(materialsProvider(userId));
      _showMessage('Material uploaded.');
    } catch (error) {
      _showMessage(
        error is MaterialFailure
            ? error.message
            : 'Could not upload the material. Check your Firebase setup.',
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _toggleBookmark(String userId, MaterialItem item) async {
    try {
      await ref
          .read(materialRepositoryProvider)
          .toggleBookmark(userId: userId, material: item);
      ref.invalidate(materialsProvider(userId));
    } catch (error) {
      _showMessage('Could not update this bookmark.');
    }
  }

  Future<void> _openMaterial(MaterialItem item) async {
    final uri = Uri.tryParse(item.fileUrl);
    if (uri == null || !uri.hasScheme) {
      _showMessage('This material has no valid download link.');
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) _showMessage('Could not open this material.');
    } catch (error) {
      _showMessage('Could not open this material.');
    }
  }

  Future<bool> _confirmDelete(MaterialItem item) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete this upload?'),
          content: Text('"${item.title}" will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _deleteMaterial(String userId, MaterialItem item) async {
    try {
      await ref
          .read(materialRepositoryProvider)
          .delete(userId: userId, material: item);
      ref.invalidate(materialsProvider(userId));
    } catch (error) {
      _showMessage(
        error is MaterialFailure ? error.message : 'Could not delete the file.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _EmptyMaterials extends StatelessWidget {
  const _EmptyMaterials({required this.bookmarkedOnly, required this.onUpload});

  final bool bookmarkedOnly;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            bookmarkedOnly
                ? Icons.bookmark_border_rounded
                : Icons.menu_book_rounded,
            size: 52,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            bookmarkedOnly ? 'No bookmarks yet' : 'Your library is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            bookmarkedOnly
                ? 'Bookmark materials to keep them close.'
                : 'Upload a PDF or text document to get started.',
            textAlign: TextAlign.center,
          ),
          if (!bookmarkedOnly) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload material'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Could not load materials. Connect Firebase or check access rules.',
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
