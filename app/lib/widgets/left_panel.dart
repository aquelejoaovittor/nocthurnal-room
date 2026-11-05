import 'package:flutter/material.dart';
import '../models/photo.dart';

class LeftPanel extends StatelessWidget {
  final Photo? selectedPhoto;
  final VoidCallback onUpdate;

  const LeftPanel({super.key, this.selectedPhoto, required this.onUpdate});

  void _applyPreset(String presetName) {
    if (selectedPhoto == null) return;
    
    // Define valores de preset
    if (presetName == 'Warm Portrait') {
      selectedPhoto!.temperature = 25.0;
      selectedPhoto!.contrast = 10.0;
      selectedPhoto!.highlights = -15.0;
      selectedPhoto!.shadows = 20.0;
    } else if (presetName == 'Cinematic') {
      selectedPhoto!.temperature = -10.0;
      selectedPhoto!.contrast = 25.0;
      selectedPhoto!.highlights = -30.0;
      selectedPhoto!.shadows = -10.0;
      selectedPhoto!.blacks = -15.0;
    } else if (presetName == 'Neutral') {
      selectedPhoto!.temperature = 0.0;
      selectedPhoto!.contrast = 0.0;
      selectedPhoto!.highlights = 0.0;
      selectedPhoto!.shadows = 0.0;
      selectedPhoto!.whites = 0.0;
      selectedPhoto!.blacks = 0.0;
      selectedPhoto!.exposure = 0.0;
    }
    onUpdate();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
    );
  }

  Widget _buildListItem(String title, IconData icon, {bool selected = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        color: selected ? const Color(0xFF1E2633) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? const Color(0xFF9D4EDD) : Colors.grey),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 13, color: selected ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF121620),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildSectionTitle('CATÁLOGO'),
          _buildListItem('Todas as Fotos', Icons.photo_library, selected: true),
          
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E2633), height: 1),
          
          _buildSectionTitle('PRESETS SALVOS'),
          _buildListItem('Warm Portrait', Icons.wb_sunny_outlined, onTap: () => _applyPreset('Warm Portrait')),
          _buildListItem('Cinematic', Icons.movie_filter_outlined, onTap: () => _applyPreset('Cinematic')),
          _buildListItem('Neutral', Icons.tune, onTap: () => _applyPreset('Neutral')),
        ],
      ),
    );
  }
}
