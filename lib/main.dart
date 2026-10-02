import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kApiBaseUrl = 'http://127.0.0.1:8001';

int? findLocationIdForQrCode(String scannedCode, List<Map<String, dynamic>> locations) {
  final normalizedCode = scannedCode.trim().toLowerCase();
  for (final location in locations) {
    if (location['qr_code']?.toString().toLowerCase() == normalizedCode ||
        location['location_code']?.toString().toLowerCase() == normalizedCode) {
      return location['id'] as int;
    }
  }
  return null;
}

void main() {
  runApp(const CampusCareApp());
}

class CampusCareApp extends StatelessWidget {
  const CampusCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusCare AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5EFF)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E5EFF)),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: Colors.black54),
          border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black54)),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black54)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(Color(0xFF1E5EFF)),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: const WidgetStatePropertyAll(Colors.black87),
            side: const WidgetStatePropertyAll(BorderSide(color: Colors.black54)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_rounded, size: 88, color: Color(0xFF1E5EFF)),
            const SizedBox(height: 20),
            const Text('CampusCare AI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Smart College Problem Reporting & Management', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController(text: 'admin@campuscare.com');
  final passwordController = TextEditingController(text: 'admin123');
  bool isLogin = true;
  bool isSubmitting = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    try {
      final token = await ApiService.login(emailController.text.trim(), passwordController.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      final user = await ApiService.getCurrentUser(token);
      if (!mounted) return;

      switch (user['role'] as String) {
        case 'admin':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AdminHomeScreen(token: token)),
          );
          break;
        case 'staff':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => StaffHomeScreen(token: token)),
          );
          break;
        default:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => StudentHomeScreen(token: token)),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    try {
      await ApiService.register(
        name: 'Demo User',
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful. Please log in.')),
      );
      setState(() => isLogin = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF2FF), Color(0xFFF8FAFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E5EFF).withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.school_rounded, size: 72, color: Color(0xFF1E5EFF)),
                          const SizedBox(height: 20),
                          const Text('CampusCare AI', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text('Smart College Problem Reporting & Management', style: TextStyle(color: Colors.grey.shade700)),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E5EFF).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isLogin ? 'Welcome back' : 'Create your account',
                              style: const TextStyle(
                                color: Color(0xFF1E5EFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(labelText: 'Email / Student ID'),
                                validator: (value) => (value == null || value.isEmpty) ? 'Email is required' : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Material(
                              color: Colors.transparent,
                              child: TextFormField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Password'),
                                validator: (value) => (value == null || value.length < 6) ? 'Password should be at least 6 characters' : null,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: isSubmitting ? null : (isLogin ? login : register),
                                icon: const Icon(Icons.login_rounded),
                                label: Text(isLogin ? 'Login' : 'Register'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E5EFF),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => setState(() => isLogin = !isLogin),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E5EFF)),
                                  child: Text(isLogin ? 'Register' : 'Login'),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E5EFF)),
                                  child: const Text('Forgot Password'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text('Demo accounts: student@campuscare.com / student123 • staff@campuscare.com / staff123 • admin@campuscare.com / admin123', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _openNotificationCenter(BuildContext context, String token) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => NotificationCenterScreen(token: token)),
  );
}

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({required this.token, super.key});

  final String token;

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getNotifications(widget.token);
  }

  void _refresh() {
    setState(() => _future = ApiService.getNotifications(widget.token));
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['is_read'] == true) return;
    try {
      await ApiService.markNotificationRead(widget.token, notification['id'] as int);
      if (!mounted) return;
      setState(() => notification['is_read'] = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh notifications',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final notifications = snapshot.data ?? <dynamic>[];
          if (notifications.isEmpty) {
            return const Center(child: Text('You are all caught up.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index] as Map<String, dynamic>;
              final isRead = notification['is_read'] == true;
              return ListTile(
                leading: Icon(
                  isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                  color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  notification['title']?.toString() ?? 'Notification',
                  style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600),
                ),
                subtitle: Text(notification['message']?.toString() ?? ''),
                trailing: isRead ? null : Icon(Icons.circle, size: 9, color: Theme.of(context).colorScheme.primary),
                onTap: () => _markAsRead(notification),
              );
            },
          );
        },
      ),
    );
  }
}

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({required this.token, super.key});
  final String token;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(token: widget.token),
      ReportProblemTab(token: widget.token),
      ComplaintsTab(token: widget.token),
      NotificationCenterScreen(token: widget.token),
      ProfileTab(token: widget.token),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.report_problem_rounded), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.list_alt_rounded), label: 'My Complaints'),
          NavigationDestination(icon: Icon(Icons.notifications_none_rounded), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

Map<String, int> summarizeStudentComplaints(List<dynamic> complaints) {
  final statuses = complaints
      .map((item) => (item as Map)['status']?.toString() ?? '')
      .toList();
  return {
    'total': complaints.length,
    'pending': statuses.where((status) => status == 'Reported' || status == 'Assigned').length,
    'inProgress': statuses.where((status) => status == 'In Progress').length,
    'resolved': statuses.where((status) => status == 'Resolved' || status == 'Closed').length,
  };
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({required this.token, super.key});
  final String token;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late Future<Map<String, dynamic>> _userFuture;
  late Future<List<dynamic>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = ApiService.getCurrentUser(widget.token);
    _complaintsFuture = ApiService.getStudentComplaints(widget.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _userFuture = ApiService.getCurrentUser(widget.token);
      _complaintsFuture = ApiService.getStudentComplaints(widget.token);
    });
    await _userFuture;
    await _complaintsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _userFuture,
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()));
              }
              if (userSnapshot.hasError) {
                return SizedBox(height: 320, child: Center(child: Text(userSnapshot.error.toString())));
              }

              return FutureBuilder<List<dynamic>>(
                future: _complaintsFuture,
                builder: (context, complaintsSnapshot) {
                  if (complaintsSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()));
                  }
                  if (complaintsSnapshot.hasError) {
                    return SizedBox(height: 320, child: Center(child: Text(complaintsSnapshot.error.toString())));
                  }

                  final complaints = complaintsSnapshot.data ?? <dynamic>[];
                  final counts = summarizeStudentComplaints(complaints);
                  final stats = [
                    _StatCard(title: 'Total Complaints', value: '${counts['total']}', color: Colors.blue),
                    _StatCard(title: 'Pending', value: '${counts['pending']}', color: Colors.orange),
                    _StatCard(title: 'In Progress', value: '${counts['inProgress']}', color: Colors.purple),
                    _StatCard(title: 'Resolved', value: '${counts['resolved']}', color: Colors.green),
                  ];
                  final recentComplaints = complaints.take(2).toList();
                  final name = userSnapshot.data?['name']?.toString() ?? 'Student';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E5EFF), Color(0xFF4F7CFF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CampusCare Overview',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text('Hello, $name', style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: stats,
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ReportProblemTab(token: widget.token)),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('+ Report a Problem'),
                      ),
                      const SizedBox(height: 24),
                      const Text('Recent Complaints', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (recentComplaints.isEmpty)
                        const Text('No complaints yet.')
                      else
                        ...recentComplaints.map((entry) {
                          final complaint = entry as Map<String, dynamic>;
                          return ComplaintListTile(
                            complaintId: complaint['complaint_number']?.toString() ?? 'N/A',
                            title: complaint['description']?.toString() ?? 'Complaint',
                            status: complaint['status']?.toString() ?? 'Unknown',
                            category: complaint['category']?.toString() ?? 'General',
                            location: complaint['location_name']?.toString() ?? 'Campus',
                            priority: complaint['priority']?.toString() ?? 'Medium',
                            imagePath: complaint['image_path']?.toString(),
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => StudentComplaintDetailSheet(
                                token: widget.token,
                                complaint: complaint,
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class ReportProblemTab extends StatefulWidget {
  const ReportProblemTab({required this.token, super.key});
  final String token;

  @override
  State<ReportProblemTab> createState() => _ReportProblemTabState();
}

class _ReportProblemTabState extends State<ReportProblemTab> {
  final _formKey = GlobalKey<FormState>();
  String selectedCategory = 'Electrical';
  String selectedPriority = 'Medium';
  final descriptionController = TextEditingController();
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  List<Map<String, dynamic>> locations = [];
  int? selectedLocationId;
  bool isLoadingLocations = true;
  String? locationLoadError;
  Map<String, dynamic>? aiSuggestion;
  String? aiAnalysisError;
  bool isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final result = await ApiService.getLocations(widget.token);
      if (!mounted) return;
      setState(() {
        locations = result;
        for (final location in locations) {
          if (location['location_name'] == 'CSE Lab 1') {
            selectedLocationId = location['id'] as int;
            break;
          }
        }
        selectedLocationId ??= locations.isNotEmpty ? locations.first['id'] as int : null;
        isLoadingLocations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingLocations = false;
        locationLoadError = 'Unable to load campus locations.';
      });
    }
  }

  Future<void> scanLocationQr() async {
    var invalidCodeShown = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.7,
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                String? scannedCode;
                for (final barcode in capture.barcodes) {
                  if (barcode.rawValue != null) {
                    scannedCode = barcode.rawValue;
                    break;
                  }
                }
                if (scannedCode == null) return;

                final locationId = findLocationIdForQrCode(scannedCode, locations);
                if (locationId == null) {
                  if (!invalidCodeShown) {
                    invalidCodeShown = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('This QR code is not linked to a campus location.')),
                    );
                  }
                  return;
                }

                setState(() => selectedLocationId = locationId);
                Navigator.of(sheetContext).pop();
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: 'Close scanner',
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    await _setSelectedImage(file);
  }

  Future<void> takePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    await _setSelectedImage(file);
  }

  Future<void> _setSelectedImage(XFile? file) async {
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      selectedImageBytes = bytes;
      selectedImageName = file.name;
    });
  }

  Future<void> analyzeDescription() async {
    final description = descriptionController.text.trim();
    if (description.length < 10) {
      setState(() => aiAnalysisError = 'Enter at least 10 characters to analyze.');
      return;
    }

    setState(() {
      isAnalyzing = true;
      aiAnalysisError = null;
    });
    try {
      final result = await ApiService.analyzeComplaint(widget.token, description);
      if (!mounted) return;
      setState(() => aiSuggestion = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => aiAnalysisError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isAnalyzing = false);
    }
  }

  Future<void> submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ApiService.submitComplaint(
        category: selectedCategory,
        description: descriptionController.text,
        locationId: selectedLocationId,
        priority: selectedPriority,
        imageBytes: selectedImageBytes,
        imageName: selectedImageName,
        token: widget.token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StudentHomeScreen(token: widget.token)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report a Problem',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  items: const [
                    'Electrical', 'Classroom', 'Laboratory', 'Computer', 'Water', 'Plumbing', 'Sanitation', 'Wi-Fi', 'Infrastructure', 'Other'
                  ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value ?? selectedCategory),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isLoadingLocations)
                const LinearProgressIndicator()
              else if (locations.isEmpty)
                Text(locationLoadError ?? 'No campus locations available.')
              else
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedLocationId,
                          items: locations
                              .map((location) => DropdownMenuItem<int>(
                                    value: location['id'] as int,
                                    child: Text(location['location_name']?.toString() ?? 'Campus'),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => selectedLocationId = value),
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            labelStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Scan location QR',
                      onPressed: scanLocationQr,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: TextFormField(
                  controller: descriptionController,
                  minLines: 4,
                  maxLines: 8,
                  onChanged: (_) {
                    if (aiSuggestion != null || aiAnalysisError != null) {
                      setState(() {
                        aiSuggestion = null;
                        aiAnalysisError = null;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Problem Description',
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  validator: (value) => (value == null || value.trim().length < 10) ? 'Enter a valid description' : null,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isAnalyzing ? null : analyzeDescription,
                icon: isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(isAnalyzing ? 'Analyzing...' : 'Analyze with AI'),
              ),
              if (aiAnalysisError != null) ...[
                const SizedBox(height: 8),
                Text(aiAnalysisError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (aiSuggestion != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI suggestion', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Category: ${aiSuggestion!['category']}'),
                      Text('Priority: ${aiSuggestion!['priority']}'),
                      Text('Confidence: ${((aiSuggestion!['confidence'] as num) * 100).round()}%'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Select from Gallery'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: takePhoto,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Take Photo'),
                    ),
                  ),
                ],
              ),
              if (selectedImageBytes != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(selectedImageBytes!, height: 180, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  items: const ['Low', 'Medium', 'High', 'Emergency']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedPriority = value ?? selectedPriority),
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: submitComplaint,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit Complaint'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComplaintsTab extends StatefulWidget {
  const ComplaintsTab({required this.token, super.key});
  final String token;

  @override
  State<ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<ComplaintsTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getStudentComplaints(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final complaints = snapshot.data ?? <dynamic>[];
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Complaints', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (complaints.isEmpty)
                  const Expanded(child: Center(child: Text('No complaints yet.')))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        final item = complaints[index] as Map<String, dynamic>;
                        return ComplaintListTile(
                          complaintId: item['complaint_number']?.toString() ?? 'N/A',
                          title: item['description']?.toString() ?? 'Complaint',
                          status: item['status']?.toString() ?? 'Unknown',
                          category: item['category']?.toString() ?? 'General',
                          location: item['location_name']?.toString() ?? 'Campus',
                          priority: item['priority']?.toString() ?? 'Medium',
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => StudentComplaintDetailSheet(token: widget.token, complaint: item),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({required this.token, super.key});
  final String token;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getCurrentUser(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final user = snapshot.data ?? {};
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const CircleAvatar(radius: 40, child: Icon(Icons.person_rounded, size: 45)),
                const SizedBox(height: 14),
                Text(user['name']?.toString() ?? 'Student', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(user['email']?.toString() ?? 'student@campuscare.com'),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.badge_rounded),
                  title: const Text('Student ID'),
                  trailing: Text(user['student_id']?.toString() ?? 'N/A'),
                ),
                ListTile(
                  leading: const Icon(Icons.school_rounded),
                  title: const Text('Department'),
                  trailing: Text(user['department']?.toString() ?? 'N/A'),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('token');
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({required this.token, super.key});
  final String token;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;
  late Future<List<dynamic>> _complaintsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _dashboardFuture = ApiService.getAdminDashboard(widget.token);
    _complaintsFuture = ApiService.getAdminComplaints(widget.token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = ApiService.getAdminDashboard(widget.token);
      _complaintsFuture = ApiService.getAdminComplaints(widget.token);
    });
  }

  List<ChartBarData> _buildChartData(Map<String, dynamic> source) {
    final entries = source.entries.toList();
    final maxValue = entries.isEmpty
        ? 1.0
        : entries
            .map((entry) => (entry.value as num).toDouble())
            .reduce((a, b) => a > b ? a : b);
    final safeMaxValue = maxValue <= 0 ? 1.0 : maxValue.toDouble();

    return entries
        .map((entry) => ChartBarData(
              label: entry.key,
              value: (entry.value as num).toDouble(),
              maxValue: safeMaxValue,
            ))
        .toList();
  }

  List<dynamic> _filteredComplaints(List<dynamic> complaints) {
    final query = _searchController.text.trim().toLowerCase();
    return complaints.where((item) {
      final complaint = item as Map<String, dynamic>;
      final status = (complaint['status'] ?? 'Unknown').toString();
      final matchesFilter = _statusFilter == 'All' || status == _statusFilter;
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final haystack = [
        complaint['complaint_number'],
        complaint['description'],
        complaint['category'],
        complaint['priority'],
        complaint['location_name'],
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => _openNotificationCenter(context, widget.token),
          ),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            }
          }),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, dashboardSnapshot) {
          if (dashboardSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (dashboardSnapshot.hasError) {
            return Center(child: Text(dashboardSnapshot.error.toString()));
          }

          final summary = dashboardSnapshot.data?['summary'] as Map<String, dynamic>? ?? {};
          final categoryData = dashboardSnapshot.data?['complaints_by_category'] as Map<String, dynamic>? ?? {};
          final statusData = dashboardSnapshot.data?['complaints_by_status'] as Map<String, dynamic>? ?? {};

          final cards = [
            _StatCard(title: 'Total', value: '${summary['total_complaints'] ?? 0}', color: Colors.blue),
            _StatCard(title: 'New', value: '${summary['new_complaints'] ?? 0}', color: Colors.orange),
            _StatCard(title: 'Assigned', value: '${summary['assigned'] ?? 0}', color: Colors.purple),
            _StatCard(title: 'Resolved', value: '${summary['resolved'] ?? 0}', color: Colors.green),
          ];

          return FutureBuilder<List<dynamic>>(
            future: _complaintsFuture,
            builder: (context, listSnapshot) {
              final complaints = listSnapshot.data ?? <dynamic>[];
              final filteredComplaints = _filteredComplaints(complaints);

              return SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const Text('Campus overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 18),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: cards,
                    ),
                    const SizedBox(height: 20),
                    if (categoryData.isNotEmpty) ...[
                      const Text('Category mix', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SimpleBarChart(data: _buildChartData(categoryData)),
                      const SizedBox(height: 18),
                    ],
                    if (statusData.isNotEmpty) ...[
                      const Text('Status pipeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SimpleBarChart(data: _buildChartData(statusData)),
                      const SizedBox(height: 18),
                    ],
                    const Text('Complaints queue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search complaints',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', 'Reported', 'Assigned', 'In Progress', 'Resolved', 'Closed']
                          .map(
                            (value) => ChoiceChip(
                              label: Text(value),
                              selected: _statusFilter == value,
                              onSelected: (_) => setState(() => _statusFilter = value),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    if (filteredComplaints.isEmpty)
                      const Center(child: Text('No complaints found'))
                    else
                      ...filteredComplaints.map((item) {
                        final complaint = item as Map<String, dynamic>;
                        return InkWell(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => ComplaintDetailSheet(
                              token: widget.token,
                              complaint: complaint,
                              staffOptions: const [
                                {'id': 1, 'name': 'Maintenance Staff'},
                                {'id': 2, 'name': 'Facility Team'},
                                {'id': 3, 'name': 'Security Operations'},
                              ],
                              onRefresh: _refresh,
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (complaint['image_path'] != null && complaint['image_path'].toString().isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        buildComplaintImageUrl(complaint['image_path']) ?? '',
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const SizedBox(
                                          height: 150,
                                          child: Center(child: Icon(Icons.image_not_supported_rounded)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          complaint['complaint_number']?.toString() ?? 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Chip(label: Text(complaint['status']?.toString() ?? 'Unknown')),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(complaint['description']?.toString() ?? 'Complaint'),
                                  const SizedBox(height: 8),
                                  Text('Category: ${complaint['category'] ?? 'General'} • Priority: ${complaint['priority'] ?? 'Medium'}'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.assignment_rounded, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        complaint['assigned_staff_id'] != null
                                            ? 'Assigned to staff #${complaint['assigned_staff_id']}'
                                            : 'Unassigned',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ComplaintDetailSheet extends StatefulWidget {
  const ComplaintDetailSheet({
    super.key,
    required this.token,
    required this.complaint,
    required this.staffOptions,
    required this.onRefresh,
  });

  final String token;
  final Map<String, dynamic> complaint;
  final List<Map<String, dynamic>> staffOptions;
  final VoidCallback onRefresh;

  @override
  State<ComplaintDetailSheet> createState() => _ComplaintDetailSheetState();
}

class _ComplaintDetailSheetState extends State<ComplaintDetailSheet> {
  late int _selectedStaffId;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    final complaint = widget.complaint;
    final assigned = complaint['assigned_staff_id'];
    _selectedStaffId = assigned is int ? assigned : (int.tryParse(assigned?.toString() ?? '') ?? 1);
    _selectedStatus = complaint['status']?.toString() ?? 'Reported';
  }

  Future<void> _saveChanges() async {
    final complaintId = widget.complaint['id'];
    final intId = complaintId is int ? complaintId : int.tryParse(complaintId.toString()) ?? -1;
    if (intId < 0) return;

    try {
      await ApiService.assignComplaintToStaff(widget.token, intId, _selectedStaffId);
      await ApiService.updateAdminStatus(widget.token, intId, _selectedStatus);
      if (!mounted) return;
      widget.onRefresh();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final imageUrl = buildComplaintImageUrl(complaint['image_path']?.toString());

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Text(
                complaint['complaint_number']?.toString() ?? 'N/A',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                complaint['description']?.toString() ?? 'Complaint description',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 18),
              if (imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 180,
                      child: Center(child: Icon(Icons.image_not_supported_rounded)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TagChip(label: complaint['category']?.toString() ?? 'General', color: Colors.blue),
                  _TagChip(label: complaint['priority']?.toString() ?? 'Medium', color: Colors.orange),
                  _TagChip(label: complaint['status']?.toString() ?? 'Reported', color: Colors.green),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Assignment flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedStaffId,
                  items: widget.staffOptions
                      .map((staff) => DropdownMenuItem<int>(
                            value: staff['id'] as int,
                            child: Text(staff['name']?.toString() ?? 'Staff member'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedStaffId = value ?? _selectedStaffId),
                  decoration: const InputDecoration(labelText: 'Assign to staff'),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  items: const ['Reported', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Closed']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedStatus = value ?? _selectedStatus),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class ChartBarData {
  const ChartBarData({required this.label, required this.value, required this.maxValue});

  final String label;
  final double value;
  final double maxValue;
}

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.data});

  final List<ChartBarData> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty ? 1.0 : data.map((e) => e.maxValue).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: data.map((item) {
          final barWidth = maxValue <= 0 ? 0.0 : (item.value / maxValue) * 100;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(item.label, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: barWidth / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 24,
                  child: Text(item.value.toStringAsFixed(0)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({required this.token, super.key});
  final String token;

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  late Future<List<dynamic>> _future;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _future = ApiService.getStaffComplaints(widget.token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ApiService.getStaffComplaints(widget.token);
    });
  }

  List<dynamic> _filteredComplaints(List<dynamic> complaints) {
    final query = _searchController.text.trim().toLowerCase();
    return complaints.where((item) {
      final complaint = item as Map<String, dynamic>;
      final status = (complaint['status'] ?? 'Assigned').toString();
      final matchesFilter = _statusFilter == 'All' || status == _statusFilter;
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final haystack = [
        complaint['complaint_number'],
        complaint['description'],
        complaint['category'],
        complaint['priority'],
        complaint['location_name'],
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => _openNotificationCenter(context, widget.token),
          ),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            }
          }),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final complaints = snapshot.data ?? <dynamic>[];
          final filteredComplaints = _filteredComplaints(complaints);

          if (filteredComplaints.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search your queue',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Assigned', 'In Progress', 'Resolved', 'Closed']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value),
                            selected: _statusFilter == value,
                            onSelected: (_) => setState(() => _statusFilter = value),
                          ),
                        )
                        .toList(),
                  ),
                  const Expanded(child: Center(child: Text('No complaints assigned to you.'))),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search your queue',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Assigned', 'In Progress', 'Resolved', 'Closed']
                    .map(
                      (value) => ChoiceChip(
                        label: Text(value),
                        selected: _statusFilter == value,
                        onSelected: (_) => setState(() => _statusFilter = value),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              ...filteredComplaints.map((item) {
                final complaint = item as Map<String, dynamic>;
                final status = complaint['status']?.toString() ?? 'Assigned';
                const statusOptions = ['Reported', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Closed'];
                final selectedStatus = statusOptions.contains(status) ? status : 'Assigned';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (complaint['image_path'] != null && complaint['image_path'].toString().isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              buildComplaintImageUrl(complaint['image_path']) ?? '',
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox(
                                height: 150,
                                child: Center(child: Icon(Icons.image_not_supported_rounded)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(complaint['complaint_number']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
                            Chip(label: Text(status)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(complaint['description']?.toString() ?? 'Complaint'),
                        const SizedBox(height: 8),
                        Text('Category: ${complaint['category'] ?? 'General'} • Priority: ${complaint['priority'] ?? 'Medium'}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(complaint['location_name']?.toString() ?? 'Campus')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedStatus,
                                  items: statusOptions
                                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (value) async {
                                    if (value == null) return;
                                    await ApiService.updateStaffStatus(widget.token, complaint['id'] as int, value);
                                    _refresh();
                                  },
                                  decoration: const InputDecoration(labelText: 'Update status'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => StaffTimelineSheet(complaint: complaint),
                              ),
                              icon: const Icon(Icons.timeline_rounded),
                              label: const Text('Timeline'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class ComplaintListTile extends StatelessWidget {
  const ComplaintListTile({
    super.key,
    required this.complaintId,
    required this.title,
    required this.status,
    required this.category,
    required this.location,
    required this.priority,
    this.imagePath,
    this.onTap,
  });

  final String complaintId;
  final String title;
  final String status;
  final String category;
  final String location;
  final String priority;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = buildComplaintImageUrl(imagePath);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            if (imageUrl != null) ...[
              Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 120,
                  child: Center(child: Icon(Icons.image_not_supported_rounded)),
                ),
              ),
            ],
            ListTile(
              onTap: onTap,
              title: Text('$complaintId • $category'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(title),
                  const SizedBox(height: 6),
                  Text('Location: $location'),
                  const SizedBox(height: 6),
                  Text('Priority: $priority'),
                ],
              ),
              trailing: Chip(label: Text(status), backgroundColor: Colors.blue.shade100),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentComplaintDetailSheet extends StatefulWidget {
  const StudentComplaintDetailSheet({
    super.key,
    required this.token,
    required this.complaint,
    this.historyFuture,
  });

  final String token;
  final Map<String, dynamic> complaint;
  final Future<List<dynamic>>? historyFuture;

  @override
  State<StudentComplaintDetailSheet> createState() => _StudentComplaintDetailSheetState();
}

class _StudentComplaintDetailSheetState extends State<StudentComplaintDetailSheet> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.historyFuture ??
        ApiService.getComplaintHistory(widget.token, widget.complaint['id'] as int);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = buildComplaintImageUrl(widget.complaint['image_path']?.toString());
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Text(
                widget.complaint['complaint_number']?.toString() ?? 'Complaint',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(widget.complaint['description']?.toString() ?? 'No description provided.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(label: Text(widget.complaint['status']?.toString() ?? 'Unknown')),
                  Chip(label: Text(widget.complaint['category']?.toString() ?? 'General')),
                  Chip(label: Text('Priority: ${widget.complaint['priority'] ?? 'Medium'}')),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_rounded),
                title: Text(widget.complaint['location_name']?.toString() ?? 'Campus'),
                subtitle: const Text('Reported location'),
              ),
              const SizedBox(height: 12),
              const Text('Status history', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FutureBuilder<List<dynamic>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text('Unable to load status history.');
                  }
                  final entries = snapshot.data ?? <dynamic>[];
                  if (entries.isEmpty) return const Text('No status updates yet.');
                  return Column(
                    children: entries.map((entry) {
                      final event = entry as Map<String, dynamic>;
                      final date = event['created_at']?.toString().split('T').first ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary),
                        title: Text(event['new_status']?.toString() ?? 'Status updated'),
                        subtitle: event['note'] == null ? null : Text(event['note'].toString()),
                        trailing: Text(date),
                      );
                    }).toList(),
                  );
                },
              ),
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 180,
                      child: Center(child: Icon(Icons.image_not_supported_rounded)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StaffTimelineSheet extends StatelessWidget {
  const StaffTimelineSheet({super.key, required this.complaint});

  final Map<String, dynamic> complaint;

  List<_TimelineEntry> _entries() {
    final status = complaint['status']?.toString() ?? 'Assigned';
    final details = [
      _TimelineEntry('Submitted', complaint['created_at']?.toString() ?? 'Today'),
      _TimelineEntry('Assigned', status == 'Reported' ? 'Pending' : 'Queued'),
      _TimelineEntry('In Progress', status == 'In Progress' || status == 'Resolved' || status == 'Closed' ? 'Active' : 'Waiting'),
      _TimelineEntry('Resolved', status == 'Resolved' || status == 'Closed' ? 'Complete' : 'Pending'),
    ];
    return details;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff timeline', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          ...entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: entry.title == 'Resolved' && entry.note == 'Complete'
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (entry != entries.last)
                          Container(
                            width: 2,
                            height: 28,
                            color: Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(entry.note, style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TimelineEntry {
  const _TimelineEntry(this.title, this.note);

  final String title;
  final String note;
}

String? buildComplaintImageUrl(String? path) {
  if (path == null || path.toString().isEmpty) return null;
  final value = path.toString();
  if (value.startsWith('http')) return value;
  return '$kApiBaseUrl$value';
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class ApiService {
  static Map<String, String> authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  static Future<String> login(String email, String password) async {
    final uri = Uri.parse('$kApiBaseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to log in. Check credentials and backend URL.');
    }
    final data = jsonDecode(response.body);
    return data['access_token'] as String;
  }

  static Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/auth/me'), headers: authHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch current user.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getNotifications(String token) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/notifications'), headers: authHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch notifications.');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<void> markNotificationRead(String token, int notificationId) async {
    final response = await http.put(
      Uri.parse('$kApiBaseUrl/notifications/$notificationId/read'),
      headers: authHeaders(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to mark notification as read.');
    }
  }

  static Future<List<Map<String, dynamic>>> getLocations(String token) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/locations'), headers: authHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch campus locations.');
    }
    final locations = jsonDecode(response.body) as List<dynamic>;
    return locations.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': 'student',
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Registration failed.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<List<dynamic>> getStudentComplaints(String token) async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/complaints'),
      headers: authHeaders(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch complaints.');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getComplaintHistory(String token, int complaintId) async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/complaints/$complaintId/history'),
      headers: authHeaders(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch complaint history.');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getAdminComplaints(String token) async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/admin/complaints'),
      headers: authHeaders(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch admin complaints.');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getAdminDashboard(String token) async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/admin/dashboard'),
      headers: authHeaders(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch dashboard data.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getStaffComplaints(String token) async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/staff/complaints'),
      headers: authHeaders(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch staff complaints.');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<void> assignComplaintToStaff(String token, int complaintId, int staffId) async {
    final response = await http.put(
      Uri.parse('$kApiBaseUrl/admin/complaints/$complaintId/assign'),
      headers: authHeaders(token),
      body: jsonEncode({'staff_id': staffId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to assign complaint to staff.');
    }
  }

  static Future<void> updateAdminStatus(String token, int complaintId, String status) async {
    final response = await http.put(
      Uri.parse('$kApiBaseUrl/admin/complaints/$complaintId/status'),
      headers: authHeaders(token),
      body: jsonEncode({'status': status, 'note': 'Updated via mobile app'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to update complaint status.');
    }
  }

  static Future<void> updateStaffStatus(String token, int complaintId, String status) async {
    final response = await http.put(
      Uri.parse('$kApiBaseUrl/staff/complaints/$complaintId/status'),
      headers: authHeaders(token),
      body: jsonEncode({'status': status, 'note': 'Updated via staff app'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to update staff status.');
    }
  }

  static Future<Map<String, dynamic>> analyzeComplaint(String token, String description) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/ai/analyze-complaint'),
      headers: authHeaders(token),
      body: jsonEncode({'description': description}),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to analyze complaint.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<dynamic> submitComplaint({
    required String category,
    required String description,
    required int? locationId,
    required String priority,
    required Uint8List? imageBytes,
    required String? imageName,
    required String token,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/complaints');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['category'] = category;
    request.fields['description'] = description;
    request.fields['priority'] = priority;
    request.fields['location_id'] = locationId?.toString() ?? '';
    if (imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageName ?? 'complaint-image.jpg',
      ));
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 201) {
      throw Exception(body);
    }
    return jsonDecode(body);
  }
}
