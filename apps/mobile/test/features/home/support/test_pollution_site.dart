import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';

PollutionSite buildTestPollutionSite({
  required String id,
  String statusLabel = 'Reported',
  String? statusCode = 'REPORTED',
  String? pollutionType = 'Illegal landfill',
  double latitude = 41.61,
  double longitude = 21.75,
}) {
  return PollutionSite(
    id: id,
    title: 'Site $id',
    description: 'Description for $id',
    statusLabel: statusLabel,
    statusCode: statusCode,
    statusColor: Colors.red,
    distanceKm: 1.2,
    score: 10,
    participantCount: 0,
    pollutionType: pollutionType,
    latitude: latitude,
    longitude: longitude,
  );
}
