import 'package:flutter/material.dart';
import '../../services/user_service.dart';

/// ✅ Role-aware navigation widget
/// Automatically routes users to appropriate screen based on their role
class RoleAwareHomePlaceholder extends StatefulWidget {
  final String? phoneNumber;

  const RoleAwareHomePlaceholder({super.key, this.phoneNumber});

  @override
  State<RoleAwareHomePlaceholder> createState() =>
      _RoleAwareHomePlaceholderState();
}

class _RoleAwareHomePlaceholderState extends State<RoleAwareHomePlaceholder> {
  @override
  void initState() {
    super.initState();
    _checkRoleAndNavigate();
  }

  Future<void> _checkRoleAndNavigate() async {
    try {
      final phoneNumber = widget.phoneNumber;

      // Check if phoneNumber is null or empty
      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return;
      }

      final user = await UserService.get(phoneNumber);

      if (mounted) {
        if (user != null && user.isAdmin()) {
          Navigator.of(
            context,
          ).pushReplacementNamed('/admin', arguments: phoneNumber);
        } else {
          Navigator.of(
            context,
          ).pushReplacementNamed('/home', arguments: phoneNumber);
        }
      }
    } catch (e) {
      // Fallback to home if error
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/home', arguments: widget.phoneNumber);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
