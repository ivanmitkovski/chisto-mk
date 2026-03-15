import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

enum ReportStatus {
  underReview('Under review', AppColors.accentWarning, Color(0xFFFFF8EC)),
  approved('Approved', AppColors.primary, Color(0xFFEDFFF6)),
  declined('Declined', AppColors.accentDanger, Color(0xFFFFF0EE)),
  alreadyReported('Already reported', AppColors.accentInfo, Color(0xFFEDF3FF));

  const ReportStatus(this.label, this.color, this.background);
  final String label;
  final Color color;
  final Color background;
}

class MockReport {
  const MockReport({
    required this.title,
    required this.description,
    required this.status,
    required this.score,
    required this.category,
    this.address,
    this.declineReason,
    this.evidenceImagePaths,
    this.cleanupEffort,
    required this.createdAt,
  });

  final String title;
  final String description;
  final ReportStatus status;
  final int score;
  final ReportCategory category;
  final String? address;
  final String? declineReason;
  final List<String>? evidenceImagePaths;
  final CleanupEffort? cleanupEffort;
  final DateTime createdAt;
}

final List<MockReport> seedReportsCatalog = <MockReport>[
  MockReport(
    title: 'Illegal dump near river',
    description:
        'Large pile of mixed waste accumulating near the Vardar riverbank.',
    status: ReportStatus.underReview,
    score: 0,
    category: ReportCategory.illegalLandfill,
    address: 'Vardar riverbank, Skopje',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  MockReport(
    title: 'Construction debris on road',
    description:
        'Broken bricks and concrete blocking the sidewalk on main street.',
    status: ReportStatus.approved,
    score: 50,
    category: ReportCategory.industrialWaste,
    address: 'Main St. 15, Skopje',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  MockReport(
    title: 'Tire dump behind factory',
    description:
        'Dozens of old tires piled up behind the abandoned textile factory.',
    status: ReportStatus.declined,
    score: 0,
    category: ReportCategory.illegalLandfill,
    address: 'Industrial zone, Kumanovo',
    declineReason: 'Duplicate report — already tracked under site #42.',
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
  ),
  MockReport(
    title: 'Plastic waste in park',
    description:
        'Scattered plastic bags and bottles around the central park benches.',
    status: ReportStatus.alreadyReported,
    score: 0,
    category: ReportCategory.other,
    address: 'City Park, Bitola',
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
  ),
];

class ReportsListMockStore {
  const ReportsListMockStore._();

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static final List<MockReport> _submittedReports = <MockReport>[];

  static List<MockReport> get reports => <MockReport>[
    ..._submittedReports,
    ...seedReportsCatalog,
  ];

  static void addSubmittedDraft(ReportDraft draft) {
    final ReportCategory category = draft.category ?? ReportCategory.other;
    final String trimmedDescription = draft.description.trim();
    final String? trimmedAddress = draft.address?.trim();

    _submittedReports.insert(
      0,
      MockReport(
        title: '${category.label} report',
        description: trimmedDescription.isNotEmpty
            ? trimmedDescription
            : 'Citizen report awaiting moderation and site review.',
        status: ReportStatus.underReview,
        score: 0,
        category: category,
        address: trimmedAddress != null && trimmedAddress.isNotEmpty
            ? trimmedAddress
            : 'Pinned location in Macedonia',
        evidenceImagePaths:
            draft.photos.map((XFile file) => file.path).toList(),
        cleanupEffort: draft.cleanupEffort,
        createdAt: DateTime.now(),
      ),
    );
    changes.value++;
  }
}
