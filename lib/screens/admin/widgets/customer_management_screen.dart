import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';
import 'add_edit_customer_dialog.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final AuthService _authService = AuthService();
  List<UserModel> _customers = [];
  bool _isLoading = true;
  String? _expandedCustomerId;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<UserModel> customers = await _authService.getUsersByRole(
        UserRole.customer,
      );
      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      String errorMessage = 'Failed to load customers';

      if (e.toString().contains('is not a subtype of type \'bool\'')) {
        errorMessage =
            'Invalid data format in Firestore. Please check isActive and isFirstLogin fields.';
      } else if (e.toString().contains(
        'is not a subtype of type \'Timestamp\'',
      )) {
        errorMessage =
            'Date fields are in incorrect format. Please check createdAt and lastLogin fields.';
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  Future<void> _addCustomer() async {
    final result = await showDialog<UserModel>(
      context: context,
      builder: (context) => const AddEditCustomerDialog(),
    );

    if (result != null) {
      await _loadCustomers();
      if (mounted) {
        _showSuccessSnackBar('Customer added successfully');
      }
    }
  }

  Future<void> _editCustomer(UserModel customer) async {
    final result = await showDialog<UserModel>(
      context: context,
      builder: (context) => AddEditCustomerDialog(customer: customer),
    );

    if (result != null) {
      await _loadCustomers();
      if (mounted) {
        _showSuccessSnackBar('Customer updated successfully');
      }
    }
  }

  Future<void> _toggleCustomerStatus(UserModel customer) async {
    try {
      await _authService.updateUser(customer.id, {
        'isActive': !customer.isActive,
      });
      await _loadCustomers();
      if (mounted) {
        _showSuccessSnackBar(
          'Customer ${customer.isActive ? 'deactivated' : 'activated'} successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update customer status');
      }
    }
  }

  Future<void> _deleteCustomer(UserModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Customer'),
            content: Text('Are you sure you want to delete ${customer.name}?'),
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
        await _authService.deleteUser(customer.id);
        await _loadCustomers();
        if (mounted) {
          _showSuccessSnackBar('Customer deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to delete customer');
        }
      }
    }
  }

  void _toggleExpansion(String customerId) {
    setState(() {
      _expandedCustomerId =
          _expandedCustomerId == customerId ? null : customerId;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadCustomers,
                child:
                    _customers.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            UserModel customer = _customers[index];
                            bool isExpanded =
                                _expandedCustomerId == customer.id;
                            return _CustomerCard(
                              customer: customer,
                              isExpanded: isExpanded,
                              onTap: () => _toggleExpansion(customer.id),
                              onEdit: () => _editCustomer(customer),
                              onToggleStatus:
                                  () => _toggleCustomerStatus(customer),
                              onDelete: () => _deleteCustomer(customer),
                            );
                          },
                        ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80.sp, color: Colors.grey[300]),
            SizedBox(height: 24.h),
            Text(
              'No customers yet',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add your first customer to get started',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final UserModel customer;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.isExpanded,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isExpanded ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor:
                        customer.isActive
                            ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 28.sp,
                      color:
                          customer.isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14.sp,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                customer.email,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14.sp,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              customer.phone,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              customer.isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color:
                                customer.isActive
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          customer.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                customer.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
              if (customer.lastLogin != null && !isExpanded) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14.sp,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Last login: ${_formatDate(customer.lastLogin!)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
              if (isExpanded) ...[
                Divider(height: 24.h),
                if (customer.lastLogin != null) ...[
                  _buildInfoRow(
                    Icons.access_time,
                    'Last Login',
                    _formatDate(customer.lastLogin!),
                  ),
                  SizedBox(height: 8.h),
                ],
                _buildInfoRow(
                  Icons.calendar_today,
                  'Member Since',
                  _formatDate(customer.createdAt),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onToggleStatus,
                        icon: Icon(
                          customer.isActive ? Icons.block : Icons.check_circle,
                          size: 18,
                        ),
                        label: Text(
                          customer.isActive ? 'Deactivate' : 'Activate',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          backgroundColor:
                              customer.isActive
                                  ? Colors.orange[100]
                                  : Colors.green[100],
                          foregroundColor:
                              customer.isActive
                                  ? Colors.orange[900]
                                  : Colors.green[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          backgroundColor: Colors.red[100],
                          foregroundColor: Colors.red[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(value, style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
