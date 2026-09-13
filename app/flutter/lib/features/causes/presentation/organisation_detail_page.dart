import 'package:flutter/material.dart';

import '../models/organisation.dart';

class OrganisationDetailPage extends StatelessWidget {
  const OrganisationDetailPage({super.key, required this.organisation});

  final Organisation organisation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = [
      if (organisation.city?.isNotEmpty == true) organisation.city!,
      if (organisation.state?.isNotEmpty == true) organisation.state!,
    ].join(', ');

    return Scaffold(
      appBar: AppBar(title: Text(organisation.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE8C9),
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: organisation.logoUrl?.trim().isNotEmpty == true
                  ? Image.network(
                      organisation.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.account_balance_rounded,
                        color: Color(0xFF6E1A14),
                        size: 42,
                      ),
                    )
                  : const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF6E1A14),
                      size: 42,
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            organisation.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (organisation.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              organisation.description!,
              style: theme.textTheme.bodyLarge,
            ),
          ],
          if (location.isNotEmpty || organisation.address?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (location.isNotEmpty)
                      _InfoRow(icon: Icons.location_on_outlined, text: location),
                    if (organisation.address?.trim().isNotEmpty == true) ...[
                      if (location.isNotEmpty) const SizedBox(height: 10),
                      _InfoRow(icon: Icons.place_outlined, text: organisation.address!),
                    ],
                    if (organisation.phone?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      _InfoRow(icon: Icons.phone_outlined, text: organisation.phone!),
                    ],
                    if (organisation.email?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      _InfoRow(icon: Icons.email_outlined, text: organisation.email!),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (organisation.gallery.isNotEmpty) ...[
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: organisation.gallery.length,
              itemBuilder: (context, index) {
                final url = organisation.gallery[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openGallery(context, index),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OrganisationGalleryViewer(
          images: organisation.gallery,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6E1A14)),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _OrganisationGalleryViewer extends StatefulWidget {
  const _OrganisationGalleryViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_OrganisationGalleryViewer> createState() => _OrganisationGalleryViewerState();
}

class _OrganisationGalleryViewerState extends State<_OrganisationGalleryViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.images[index],
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );
  }
}
