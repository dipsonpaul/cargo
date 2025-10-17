import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../models/request_model.dart';
import '../../../services/request_service.dart';

class CollectionStatusDialog extends StatefulWidget {
  final CargoRequest request;

  const CollectionStatusDialog({super.key, required this.request});

  @override
  State<CollectionStatusDialog> createState() => _CollectionStatusDialogState();
}

class _CollectionStatusDialogState extends State<CollectionStatusDialog> {
  final RequestService _requestService = RequestService();
  final ImagePicker _imagePicker = ImagePicker();
  
  RequestStatus? _selectedStatus;
  String _notes = '';
  int _packageCount = 1;
  File? _cargoImage;
  File? _doorImage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.update,
                    size: 24.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Update Collection Status',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              SizedBox(height: 20.h),
              
              // Status Selection
              Text(
                'Select Status',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              
              SizedBox(height: 12.h),
              
              ...RequestStatus.values.map((status) {
                if (status == RequestStatus.pending || status == RequestStatus.assigned) {
                  return const SizedBox.shrink();
                }
                
                return RadioListTile<RequestStatus>(
                  value: status,
                  groupValue: _selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                  title: Text(
                    _getStatusDisplayName(status),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
              
              SizedBox(height: 20.h),
              
              // Package Count (for collected status)
              if (_selectedStatus == RequestStatus.collected) ...[
                Text(
                  'Number of Packages',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_packageCount > 1) {
                          setState(() {
                            _packageCount--;
                          });
                        }
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _packageCount.toString(),
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _packageCount++;
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                
                SizedBox(height: 20.h),
              ],
              
              // Cargo Photo (for collected status)
              if (_selectedStatus == RequestStatus.collected) ...[
                Text(
                  'Cargo Photo',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                Container(
                  height: 120.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: _cargoImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(
                            _cargoImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 32.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Tap to take photo',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                ),
                
                SizedBox(height: 8.h),
                
                OutlinedButton.icon(
                  onPressed: _takeCargoPhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_cargoImage != null ? 'Retake Photo' : 'Take Photo'),
                ),
                
                SizedBox(height: 20.h),
              ],
              
              // Door Photo (for customer not available status)
              if (_selectedStatus == RequestStatus.customerNotAvailable) ...[
                Text(
                  'Door Photo',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                Container(
                  height: 120.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: _doorImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(
                            _doorImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 32.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Tap to take door photo',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                ),
                
                SizedBox(height: 8.h),
                
                OutlinedButton.icon(
                  onPressed: _takeDoorPhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_doorImage != null ? 'Retake Photo' : 'Take Photo'),
                ),
                
                SizedBox(height: 20.h),
              ],
              
              // Notes
              Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              
              SizedBox(height: 12.h),
              
              TextField(
                onChanged: (value) {
                  setState(() {
                    _notes = value;
                  });
                },
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any additional notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading || _selectedStatus == null ? null : _updateStatus,
                      child: _isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Update Status'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takeCargoPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _cargoImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takeDoorPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _doorImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload photos if needed
      String? cargoPhotoUrl;
      String? doorPhotoUrl;

      if (_selectedStatus == RequestStatus.collected && _cargoImage != null) {
        cargoPhotoUrl = await _requestService.uploadCargoPhoto(widget.request.id, _cargoImage!);
      }

      if (_selectedStatus == RequestStatus.customerNotAvailable && _doorImage != null) {
        doorPhotoUrl = await _requestService.uploadDoorPhoto(widget.request.id, _doorImage!);
      }

      // Update request status
      Map<String, dynamic> updates = {
        'status': _selectedStatus.toString().split('.').last,
        'collectionNotes': _notes.isNotEmpty ? _notes : null,
      };

      if (_selectedStatus == RequestStatus.collected) {
        updates['packageCount'] = _packageCount;
        if (cargoPhotoUrl != null) {
          updates['cargoPhotoUrl'] = cargoPhotoUrl;
        }
      }

      if (_selectedStatus == RequestStatus.customerNotAvailable && doorPhotoUrl != null) {
        updates['doorPhotoUrl'] = doorPhotoUrl;
      }

      await _requestService.updateRequest(widget.request.id, updates);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_getStatusDisplayName(_selectedStatus!)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusDisplayName(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.outForCollection:
        return 'Out for Collection';
      case RequestStatus.collected:
        return 'Collected';
      case RequestStatus.customerNotAvailable:
        return 'Customer Not Available';
      case RequestStatus.completed:
        return 'Completed';
      default:
        return status.toString().split('.').last;
    }
  }
}
