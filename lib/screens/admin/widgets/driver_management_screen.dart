import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';
import 'add_edit_driver_dialog.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  final AuthService _authService = AuthService();
  List<UserModel> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      List<UserModel> drivers = await _authService.getUsersByRole(
        UserRole.driver,
      );
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load drivers: ${e.toString()}');
    }
  }

  Future<void> _addDriver() async {
    final result = await showDialog<UserModel>(
      context: context,
      builder: (context) => const AddEditDriverDialog(),
    );

    if (result != null) {
      _loadDrivers();
      _showSuccessSnackBar('Driver added successfully');
    }
  }

  Future<void> _editDriver(UserModel driver) async {
    final result = await showDialog<UserModel>(
      context: context,
      builder: (context) => AddEditDriverDialog(driver: driver),
    );

    if (result != null) {
      _loadDrivers();
      _showSuccessSnackBar('Driver updated successfully');
    }
  }

  Future<void> _toggleDriverStatus(UserModel driver) async {
    try {
      await _authService.updateUser(driver.id, {'isActive': !driver.isActive});
      _loadDrivers();
      _showSuccessSnackBar(
        'Driver ${driver.isActive ? 'deactivated' : 'activated'} successfully',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update driver status: ${e.toString()}');
    }
  }

  Future<void> _deleteDriver(UserModel driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Driver'),
            content: Text('Are you sure you want to delete ${driver.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _authService.deleteUser(driver.id);
        _loadDrivers();
        _showSuccessSnackBar('Driver deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete driver: ${e.toString()}');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Driver Management',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addDriver,
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text(
                            'Add Driver',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    Expanded(
                      child:
                          _drivers.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.drive_eta,
                                      size: 64.sp,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No drivers found',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add your first driver to get started',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                itemCount: _drivers.length,
                                itemBuilder: (context, index) {
                                  UserModel driver = _drivers[index];
                                  return _DriverCard(
                                    driver: driver,
                                    onEdit: () => _editDriver(driver),
                                    onToggleStatus:
                                        () => _toggleDriverStatus(driver),
                                    onDelete: () => _deleteDriver(driver),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final UserModel driver;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _DriverCard({
    required this.driver,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      driver.isActive
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 24,
                    color:
                        driver.isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        driver.email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        driver.phone,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        driver.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color:
                          driver.isActive
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    driver.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: driver.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            if (driver.lastLogin != null) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Last login: ${_formatDate(driver.lastLogin!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    minimumSize: const Size(0, 36), // reduce height
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    driver.isActive ? Icons.pause : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(
                    driver.isActive ? 'Deactivate' : 'Activate',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        driver.isActive ? Colors.orange : Colors.green,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
