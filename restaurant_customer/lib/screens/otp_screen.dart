import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/debug_flags.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../config/socket_service.dart';
import 'menu_screen.dart';
import '../config/responsive.dart';

class OtpScreen extends StatefulWidget {
  final String tableNumber;
  final String restaurantId;

  const OtpScreen({
    super.key,
    required this.tableNumber,
    required this.restaurantId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _api = ApiService();

  bool otpSent = false;
  bool isSendingOtp = false;
  bool isProcessing = false;
  int? tableId;
  String localError = '';
  String? testOtp;
  String? _birthday;
  bool _acceptPrivacy = false;
  bool _receiveUpdates = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2EB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD4C2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.table_restaurant_rounded,
                size: 16,
                color: Color(0xFFF45B15),
              ),
              const SizedBox(width: 6),
              Text(
                'Table ${widget.tableNumber}',
                style: const TextStyle(
                  color: Color(0xFFF45B15),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0EBE7), height: 1),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCF9F6), Color(0xFFF5EFE9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 28,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 26,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Icon badge
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF7A3D), Color(0xFFF45B15)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40F45B15),
                                blurRadius: 18,
                                offset: Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Icon(
                            otpSent
                                ? Icons.mark_email_read_rounded
                                : Icons.phone_android_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title & Subtitle
                      Text(
                        otpSent ? 'Enter your OTP' : 'Confirm your details',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        otpSent
                            ? '${_phoneCtrl.text} par 6-digit OTP bheja gaya hai'
                            : 'Add your details to start ordering at the table.',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // ---- FORM SECTION ----
                      if (!otpSent) ...[
                        _buildFieldLabel('Your name', isRequired: true),
                        TextField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          decoration: _inputDecoration(
                            hintText: 'Enter your full name',
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFFF45B15),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Mobile Number', isRequired: true),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF1F2937),
                          ),
                          decoration: _inputDecoration(
                            hintText: '9876543210',
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.phone_iphone_rounded,
                                    color: Color(0xFFF45B15),
                                    size: 19,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '+91',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Email (optional)'),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                          decoration: _inputDecoration(
                            hintText: 'name@example.com',
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                              color: Color(0xFF9CA3AF),
                              size: 19,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Date of birth (optional)'),
                        InkWell(
                          onTap: _selectBirthday,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.cake_outlined,
                                  color: Color(0xFF9CA3AF),
                                  size: 19,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _birthday ?? 'YYYY-MM-DD',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: _birthday != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: _birthday != null
                                          ? const Color(0xFF1F2937)
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFFF45B15),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Checkboxes
                        _buildConsentTile(
                          value: _acceptPrivacy,
                          onChanged: (val) =>
                              setState(() => _acceptPrivacy = val ?? false),
                          title: const Text(
                            'I accept the privacy policy.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                        _buildConsentTile(
                          value: _receiveUpdates,
                          onChanged: (val) =>
                              setState(() => _receiveUpdates = val ?? false),
                          title: const Text(
                            'Send me important updates on WhatsApp, RCS or email.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Error Banner
                        if (localError.isNotEmpty) _buildErrorBanner(),

                        // Continue CTA
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: (isSendingOtp || !_acceptPrivacy)
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFFF7A3D),
                                      Color(0xFFF45B15),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: (isSendingOtp || !_acceptPrivacy)
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Color(0x38F45B15),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            onPressed: isSendingOtp || !_acceptPrivacy
                                ? null
                                : _handleSendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: const Color(0xFFE5E7EB),
                              disabledForegroundColor: const Color(0xFF9CA3AF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSendingOtp
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue with OTP',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],

                      // ---- OTP INPUT SECTION ----
                      if (otpSent) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.phone_iphone_rounded,
                                  size: 16,
                                  color: Color(0xFF4B5563),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+91 ${_phoneCtrl.text}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => setState(() {
                                    otpSent = false;
                                    localError = '';
                                  }),
                                  child: const Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFF45B15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildFieldLabel('Enter 6-Digit OTP', isRequired: true),
                        TextField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            letterSpacing: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '• • • • • •',
                            hintStyle: const TextStyle(
                              fontSize: 24,
                              letterSpacing: 8,
                              color: Color(0xFF9CA3AF),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFF45B15),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Error Message
                        if (localError.isNotEmpty) _buildErrorBanner(),

                        if (kShowTestOtp && testOtp != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: InkWell(
                              onTap: () {
                                _otpCtrl.text = testOtp!;
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.flash_on_rounded,
                                      color: Color(0xFFD97706),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Test OTP: $testOtp',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '(Tap to autofill)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFB45309),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: isProcessing
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFFF7A3D),
                                      Color(0xFFF45B15),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: isProcessing
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Color(0x38F45B15),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : _handleVerifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: const Color(0xFFE5E7EB),
                              disabledForegroundColor: const Color(0xFF9CA3AF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Verify & Lock Table',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Resend OTP
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              final resendResult = await _api.scanTable(
                                widget.tableNumber,
                                widget.restaurantId,
                                _phoneCtrl.text,
                              );
                              if (!context.mounted) return;
                              setState(
                                () => testOtp = resendResult['data']?['otp']
                                    ?.toString(),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP dobara bhej diya gaya!'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: Color(0xFFF45B15),
                            ),
                            label: const Text(
                              'OTP nahi aaya? Resend karo',
                              style: TextStyle(
                                color: Color(0xFFF45B15),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Info Security Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                color: Color(0xFF16A34A),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Table Protection',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'OTP verify hone par yeh table aapke liye lock ho jayegi. Koi aur is table se order nahi kar payega.',
                                    style: TextStyle(
                                      color: Color(0xFF166534),
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Color(0xFFF45B15),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      counterText: '',
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF45B15), width: 1.8),
      ),
    );
  }

  Widget _buildConsentTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget title,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFFF45B15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: title),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              localError,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _birthday =
          '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    });
  }

  // ---- SEND OTP HANDLER ----
  Future<void> _handleSendOtp() async {
    setState(() {
      localError = '';
      isSendingOtp = true;
    });

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() {
        localError = 'Enter your name';
        isSendingOtp = false;
      });
      return;
    }
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      setState(() {
        localError = 'Enter a valid email address';
        isSendingOtp = false;
      });
      return;
    }
    if (!_acceptPrivacy) {
      setState(() {
        localError = 'Accept the privacy policy to continue';
        isSendingOtp = false;
      });
      return;
    }
    if (_phoneCtrl.text.length != 10) {
      setState(() {
        localError = '10 digit phone number daalo';
        isSendingOtp = false;
      });
      return;
    }

    // Table scan karo — yahi table_lock OTP bhi bhej deta hai
    try {
      final scanResult = await _api.scanTable(
        widget.tableNumber,
        widget.restaurantId,
        _phoneCtrl.text,
      );

      if (scanResult['success'] != true) {
        setState(() => localError = scanResult['message'] ?? 'Table nahi mili');
        return;
      }

      final data = scanResult['data'];

      // Agar table already occupied hai
      if (data['requires_room_code'] == true) {
        _showRoomCodeDialog();
        return;
      }

      tableId = data['table_id'];
      setState(() {
        otpSent = true;
        testOtp = data['otp']?.toString();
      });
    } catch (e) {
      setState(
        () =>
            localError = 'Server se connect nahi ho raha. Backend check karo.',
      );
    } finally {
      setState(() => isSendingOtp = false);
    }
  }

  // ---- VERIFY OTP + LOCK TABLE HANDLER ----
  Future<void> _handleVerifyOtp() async {
    setState(() {
      localError = '';
      isProcessing = true;
    });

    if (_otpCtrl.text.length != 6) {
      setState(() {
        localError = '6 digit OTP daalo';
        isProcessing = false;
      });
      return;
    }

    // OTP verify + table lock ek hi call mein hota hai (backend table_lock purpose se OTP verify karta hai)
    try {
      final lockResult = await _api.lockTable(
        tableId!,
        _phoneCtrl.text,
        _otpCtrl.text,
      );

      if (lockResult['success'] == true) {
        final sessionId = lockResult['data']['session_id'].toString();
        final roomCode = lockResult['data']['room_code'];
        final token = lockResult['data']['token'] as String?;

        // Orders jaise authenticated API calls ke liye token save karo
        final prefs = await SharedPreferences.getInstance();
        if (token != null) await prefs.setString('token', token);
        await prefs.setString('phone', _phoneCtrl.text);
        await prefs.setString('customer_name', _nameCtrl.text.trim());
        await prefs.setString('customer_email', _emailCtrl.text.trim());
        await prefs.setString('customer_birthday', _birthday ?? '');
        await prefs.setBool('customer_updates_opt_in', _receiveUpdates);

        // Refresh ke baad bhi session yaad rahe, isliye save karo
        await SessionService.saveSession(
          tableId: tableId!,
          restaurantId: widget.restaurantId,
          tableNumber: widget.tableNumber,
          sessionId: sessionId,
          roomCode: roomCode,
        );

        // Step 3: Socket.io connect karo
        SocketService().connect(widget.restaurantId, tableId.toString());

        if (!mounted) return;

        // ✅ SUCCESS — Phase 2 mein yahan MenuScreen par jayenge
        // Abhi ke liye success dialog dikhao
        _showSuccessDialog(sessionId, roomCode);
      } else {
        setState(
          () => localError = lockResult['message'] ?? 'Table lock failed',
        );
      }
    } catch (e) {
      setState(() => localError = 'Table lock error. Try again.');
    }

    setState(() => isProcessing = false);
  }

  // ---- ROOM CODE DIALOG (Group Ordering) ----
  void _showRoomCodeDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.group, color: Colors.orange),
            SizedBox(width: 8),
            Text('Table Occupied'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Yeh table pehle se occupied hai. Host se Room Code lo aur yahan daalo.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Room Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Phase 2 mein room code verify implement hoga
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Room code verify — coming in Phase 2'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Join', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---- SUCCESS DIALOG ----
  void _showSuccessDialog(String sessionId, String roomCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Table Locked! 🔒',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ab koi aur is table se order nahi kar sakta',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Doston ke saath share karo:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Room Code: $roomCode',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuScreen(
                        restaurantId: widget.restaurantId,
                        tableNumber: widget.tableNumber,
                        tableId: tableId!,
                        sessionId: sessionId,
                        roomCode: roomCode,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF45B15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Menu →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
