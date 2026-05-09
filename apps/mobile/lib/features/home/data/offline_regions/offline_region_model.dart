class OfflineRegion {
  final String id;
  final String label;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final int tileCount;
  final int siteCount;
  final int sizeBytes;
  final DateTime? lastRefreshed;
  final double downloadProgress;

  const OfflineRegion({
    required this.id,
    required this.label,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    this.tileCount = 0,
    this.siteCount = 0,
    this.sizeBytes = 0,
    this.lastRefreshed,
    this.downloadProgress = 0.0,
  });

  OfflineRegion copyWith({
    String? label,
    int? tileCount,
    int? siteCount,
    int? sizeBytes,
    DateTime? lastRefreshed,
    double? downloadProgress,
  }) {
    return OfflineRegion(
      id: id,
      label: label ?? this.label,
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
      tileCount: tileCount ?? this.tileCount,
      siteCount: siteCount ?? this.siteCount,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
        'tileCount': tileCount,
        'siteCount': siteCount,
        'sizeBytes': sizeBytes,
        'lastRefreshed': lastRefreshed?.toIso8601String(),
        'downloadProgress': downloadProgress,
      };

  factory OfflineRegion.fromJson(Map<String, dynamic> json) {
    return OfflineRegion(
      id: json['id'] as String,
      label: json['label'] as String,
      minLat: (json['minLat'] as num).toDouble(),
      maxLat: (json['maxLat'] as num).toDouble(),
      minLng: (json['minLng'] as num).toDouble(),
      maxLng: (json['maxLng'] as num).toDouble(),
      tileCount: json['tileCount'] as int? ?? 0,
      siteCount: json['siteCount'] as int? ?? 0,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      lastRefreshed: json['lastRefreshed'] != null
          ? DateTime.tryParse(json['lastRefreshed'] as String)
          : null,
      downloadProgress: (json['downloadProgress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
