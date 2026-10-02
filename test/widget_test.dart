import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campuscareai_edition/main.dart';

void main() {
  testWidgets('CampusCare splash screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusCareApp());

    expect(find.text('CampusCare AI'), findsOneWidget);
    expect(find.text('Smart College Problem Reporting & Management'), findsOneWidget);
  });

  test('QR code resolves to its location ID', () {
    final locations = [
      {'id': 12, 'location_code': 'CSE_LAB_01', 'qr_code': 'CSE_LAB_01'},
    ];

    expect(findLocationIdForQrCode('cse_lab_01', locations), 12);
    expect(findLocationIdForQrCode('unknown-location', locations), isNull);
  });

  test('student dashboard counts complaints by status', () {
    final counts = summarizeStudentComplaints([
      {'status': 'Reported'},
      {'status': 'Assigned'},
      {'status': 'In Progress'},
      {'status': 'Resolved'},
      {'status': 'Closed'},
      {'status': 'Rejected'},
    ]);

    expect(counts['total'], 6);
    expect(counts['pending'], 2);
    expect(counts['inProgress'], 1);
    expect(counts['resolved'], 2);
  });

  testWidgets('Complaint list tile fits narrow screens without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ComplaintListTile(
            complaintId: 'CC1004',
            title: 'One of the classroom chairs is broken in Room 101.',
            status: 'Assigned',
            category: 'Classroom',
            location: 'Campus',
            priority: 'Low',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Priority: Low'), findsOneWidget);
  });

  testWidgets('Student complaint detail shows status and location', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentComplaintDetailSheet(
            token: 'demo-token',
            complaint: {
              'complaint_number': 'CC1004',
              'id': 1,
              'description': 'A chair is broken in classroom 101.',
              'category': 'Classroom',
              'status': 'Assigned',
              'priority': 'Low',
              'location_name': 'Classroom 101',
            },
            historyFuture: Future.value([
              {
                'new_status': 'Reported',
                'note': 'Complaint created',
                'created_at': '2026-10-02T10:00:00',
              },
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CC1004'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('Classroom 101'), findsOneWidget);
    expect(find.text('Status history'), findsOneWidget);
    expect(find.text('Reported'), findsOneWidget);
  });

  testWidgets('Student complaint card opens its detail sheet', (WidgetTester tester) async {
    const Map<String, dynamic> complaint = {
      'complaint_number': 'CC1005',
      'id': 2,
      'description': 'The classroom projector is not working.',
      'category': 'Classroom',
      'status': 'Reported',
      'priority': 'Medium',
      'location_name': 'Classroom 102',
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ComplaintListTile(
              complaintId: complaint['complaint_number']!,
              title: complaint['description']!,
              status: complaint['status']!,
              category: complaint['category']!,
              location: complaint['location_name']!,
              priority: complaint['priority']!,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => StudentComplaintDetailSheet(
                  token: 'demo-token',
                  complaint: complaint,
                  historyFuture: Future.value([]),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('CC1005 • Classroom'));
    await tester.pumpAndSettle();

    expect(find.text('CC1005'), findsOneWidget);
    expect(find.text('Classroom 102'), findsOneWidget);
  });

  testWidgets('Complaint detail sheet shows assignment and updates', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComplaintDetailSheet(
            token: 'demo-token',
            complaint: {
              'id': 1,
              'complaint_number': 'CC1001',
              'description': 'Main hallway light is out.',
              'category': 'Electrical',
              'priority': 'High',
              'status': 'Assigned',
              'location_name': 'Main Building',
              'assigned_staff_id': 2,
            },
            staffOptions: const [
              {'id': 1, 'name': 'Maintenance Staff'},
              {'id': 2, 'name': 'Facility Team'},
            ],
            onRefresh: () {},
          ),
        ),
      ),
    );

    expect(find.text('CC1001'), findsOneWidget);
    expect(find.text('Assignment flow'), findsOneWidget);
    expect(find.text('Facility Team'), findsOneWidget);
  });
}
